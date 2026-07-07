import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_dropdown.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../data/datasources/filters_effects_remote_datasource.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/publish_catalog_dialog.dart';
import '../dialogs/seed_catalog_dialog.dart';
import '../utils/filters_effects_responsive.dart';

class FiltersEffectsHeader extends StatefulWidget {
  const FiltersEffectsHeader({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  final FiltersEffectsLayoutMetrics metrics;
  final bool isLoading;

  @override
  State<FiltersEffectsHeader> createState() => _FiltersEffectsHeaderState();
}

class _FiltersEffectsHeaderState extends State<FiltersEffectsHeader> {
  Timer? _debounce;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.unfocus();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<FiltersEffectsBloc>().add(
            FiltersEffectsSearchChanged(value.trim()),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final metrics = widget.metrics;
    final compact = metrics.isCompact;

    final roles = context.select<AuthBloc, List<UserRole>>((b) {
      final state = b.state;
      if (state is Authenticated) return state.user.roles;
      return const <UserRole>[];
    });
    final canManage = canManageFiltersEffects(roles);

    final titleStyle = (compact
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(fontWeight: FontWeight.w800);

    final statusFilter = context.select<FiltersEffectsBloc, FiltersEffectsStatusFilter>(
      (b) {
        final state = b.state;
        if (state is FiltersEffectsLoaded) return state.query.status;
        return FiltersEffectsStatusFilter.all;
      },
    );

    final engineKey = context.select<FiltersEffectsBloc, String?>(
      (b) {
        final state = b.state;
        if (state is FiltersEffectsLoaded) return state.query.engineKey;
        return null;
      },
    );

    final activeTab = context.select<FiltersEffectsBloc, FiltersEffectsTab>(
      (b) {
        final state = b.state;
        if (state is FiltersEffectsLoaded) return state.activeTab;
        return FiltersEffectsTab.overview;
      },
    );

    final showStatusFilter = activeTab == FiltersEffectsTab.filters ||
        activeTab == FiltersEffectsTab.effects;
    final showEngineFilter = activeTab == FiltersEffectsTab.filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feModuleTitle', 'Filters & Effects'),
          textAlign: TextAlign.start,
          style: titleStyle,
        ),
        SizedBox(height: metrics.toolbarFilterGap),
        Text(
          l10n.tOr(
            'feModuleSubtitle',
            'Manage camera studio filters, effects, categories, and catalog publishing.',
          ),
          textAlign: TextAlign.start,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compact ? 12 : null,
                color: scheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: metrics.toolbarSectionGap),
        if (compact)
          _buildCompactToolbar(
            context,
            canManage: canManage,
            showStatusFilter: showStatusFilter,
            showEngineFilter: showEngineFilter,
            statusFilter: statusFilter,
            engineKey: engineKey,
          )
        else
          _buildWideToolbar(
            context,
            canManage: canManage,
            showStatusFilter: showStatusFilter,
            showEngineFilter: showEngineFilter,
            statusFilter: statusFilter,
            engineKey: engineKey,
          ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final height = widget.metrics.toolbarControlHeight;

    return SizedBox(
      height: height,
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        textAlign: TextAlign.start,
        decoration: ToolbarFilterStyle.inputDecoration(
          scheme,
          hintText: l10n.tOr('feSearchHint', 'Search filters or effects…'),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(FiltersEffectsStatusFilter statusFilter) {
    final l10n = context.l10n;
    final selected = statusFilter == FiltersEffectsStatusFilter.all
        ? null
        : statusFilter;

    return ToolbarFilterDropdown<FiltersEffectsStatusFilter?>(
      hint: l10n.tOr('feStatusFilter', 'Status'),
      value: selected,
      items: const [
        null,
        FiltersEffectsStatusFilter.active,
        FiltersEffectsStatusFilter.inactive,
      ],
      itemLabel: (value) {
        return switch (value) {
          null => l10n.tOr('feStatusAll', 'All statuses'),
          FiltersEffectsStatusFilter.active =>
            l10n.tOr('feActive', 'Active'),
          FiltersEffectsStatusFilter.inactive =>
            l10n.tOr('feInactive', 'Inactive'),
          FiltersEffectsStatusFilter.all => l10n.tOr('feStatusAll', 'All statuses'),
        };
      },
      onChanged: (value) {
        context.read<FiltersEffectsBloc>().add(
              FiltersEffectsFilterChanged(
                status: value ?? FiltersEffectsStatusFilter.all,
              ),
            );
      },
    );
  }

  Widget _buildEngineDropdown(String? engineKey) {
    final l10n = context.l10n;

    return ToolbarFilterDropdown<String?>(
      hint: l10n.tOr('feEngineKeyFilter', 'Engine key'),
      value: engineKey,
      items: [
        null,
        ...kCameraAwesomeEngineKeys,
      ],
      itemLabel: (value) =>
          value ?? l10n.tOr('feAllEngineKeys', 'All engine keys'),
      onChanged: (value) {
        context.read<FiltersEffectsBloc>().add(
              FiltersEffectsFilterChanged(
                engineKey: value,
                clearEngineKey: value == null,
              ),
            );
      },
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.tOr('feRefresh', 'Refresh'),
      onPressed: widget.isLoading
          ? null
          : () => context.read<FiltersEffectsBloc>().add(
                const LoadFiltersEffects(),
              ),
      icon: const Icon(Icons.refresh_rounded),
    );
  }

  Widget _buildPublishButton(BuildContext context, {bool compact = false}) {
    final l10n = context.l10n;
    return compact
        ? IconButton(
            tooltip: l10n.tOr('fePublishCatalog', 'Publish catalog'),
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded),
          )
        : OutlinedButton.icon(
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded, size: 18),
            label: Text(l10n.tOr('fePublishCatalog', 'Publish catalog')),
          );
  }

  Widget _buildSeedButton(BuildContext context, {bool compact = false}) {
    final l10n = context.l10n;
    return compact
        ? IconButton(
            tooltip: l10n.tOr('feSeedDefaults', 'Seed defaults'),
            onPressed: () => showSeedCatalogDialog(context),
            icon: const Icon(Icons.grass_rounded),
          )
        : FilledButton.tonalIcon(
            onPressed: () => showSeedCatalogDialog(context),
            icon: const Icon(Icons.grass_rounded, size: 18),
            label: Text(l10n.tOr('feSeedDefaults', 'Seed defaults')),
          );
  }

  Widget _buildWideToolbar(
    BuildContext context, {
    required bool canManage,
    required bool showStatusFilter,
    required bool showEngineFilter,
    required FiltersEffectsStatusFilter statusFilter,
    required String? engineKey,
  }) {
    final gap = widget.metrics.filterGap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildSearchField(context)),
        SizedBox(width: gap),
        if (showStatusFilter) ...[
          SizedBox(width: 132, child: _buildStatusDropdown(statusFilter)),
          SizedBox(width: gap),
        ],
        if (showEngineFilter) ...[
          SizedBox(width: 168, child: _buildEngineDropdown(engineKey)),
          SizedBox(width: gap),
        ],
        _buildRefreshButton(context),
        if (canManage) ...[
          SizedBox(width: gap),
          _buildPublishButton(context),
          SizedBox(width: gap),
          _buildSeedButton(context),
        ],
      ],
    );
  }

  Widget _buildCompactToolbar(
    BuildContext context, {
    required bool canManage,
    required bool showStatusFilter,
    required bool showEngineFilter,
    required FiltersEffectsStatusFilter statusFilter,
    required String? engineKey,
  }) {
    final gap = widget.metrics.filterGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(context),
        SizedBox(height: gap),
        if (showStatusFilter || showEngineFilter)
          Row(
            children: [
              if (showStatusFilter)
                Expanded(child: _buildStatusDropdown(statusFilter)),
              if (showStatusFilter && showEngineFilter) SizedBox(width: gap),
              if (showEngineFilter)
                Expanded(child: _buildEngineDropdown(engineKey)),
            ],
          ),
        if (showStatusFilter || showEngineFilter) SizedBox(height: gap),
        Row(
          children: [
            _buildRefreshButton(context),
            if (canManage) ...[
              _buildPublishButton(context, compact: true),
              _buildSeedButton(context, compact: true),
            ],
          ],
        ),
      ],
    );
  }
}
