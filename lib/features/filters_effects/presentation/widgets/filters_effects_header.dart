import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../dialogs/publish_catalog_dialog.dart';
import '../utils/filters_effects_responsive.dart';
import 'filters_effects_tab_bar.dart';

/// Compact title + refresh / publish actions (no subtitle).
class FiltersEffectsHeader extends StatelessWidget {
  const FiltersEffectsHeader({
    super.key,
    required this.metrics,
    this.isLoading = false,
    this.activeTab,
    this.showCreateAction = false,
  });

  final FiltersEffectsLayoutMetrics metrics;
  final bool isLoading;
  final FiltersEffectsTab? activeTab;

  /// When true (small screens), create filter/effect lives here instead of the tab bar.
  final bool showCreateAction;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isCompact;

    context.select<RbacBloc, Set<String>?>(
      (b) => b.state.authContext?.permissionKeys,
    );
    final canManage = PermissionManager.canManageCameraStudio(context);
    final resolvedTab = activeTab == null
        ? null
        : FiltersEffectsTabBar.normalizeTab(activeTab!);
    final showCreate =
        showCreateAction &&
        canManage &&
        (resolvedTab == FiltersEffectsTab.filters ||
            resolvedTab == FiltersEffectsTab.effects);

    final titleStyle =
        (compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge)
            ?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
              color: scheme.onSurface,
              height: 1.05,
            );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              l10n.tOr('feModuleTitle', 'Filters & Effects'),
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          SizedBox(width: metrics.filterGap),
          if (showCreate) ...[
            _HeaderCreateButton(activeTab: resolvedTab!),
            SizedBox(width: metrics.filterGap),
          ],
          _RefreshButton(isLoading: isLoading),
          if (canManage) ...[
            SizedBox(width: metrics.filterGap),
            _PublishButton(compact: compact),
          ],
        ],
      ),
    );
  }
}

class _HeaderCreateButton extends StatelessWidget {
  const _HeaderCreateButton({required this.activeTab});

  final FiltersEffectsTab activeTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEffects = activeTab == FiltersEffectsTab.effects;
    final label = isEffects
        ? l10n.tOr('feCreateEffect', 'Create effect')
        : l10n.tOr('feCreateFilter', 'Create filter');

    return Tooltip(
      message: label,
      child: FilledButton(
        onPressed: () {
          if (isEffects) {
            createCameraEffectFromManagement(context);
          } else {
            createCameraFilterFromManagement(context);
          }
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 40),
          maximumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.tOr('feRefresh', 'Refresh'),
      visualDensity: VisualDensity.compact,
      onPressed: isLoading
          ? null
          : () => context.read<FiltersEffectsBloc>().add(
              const LoadFiltersEffects(),
            ),
      icon: const Icon(Icons.refresh_rounded),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return compact
        ? IconButton(
            tooltip: l10n.tOr('fePublishCatalog', 'Publish catalog'),
            visualDensity: VisualDensity.compact,
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded),
          )
        : OutlinedButton.icon(
            onPressed: () => showPublishCatalogDialog(context),
            icon: const Icon(Icons.publish_rounded, size: 18),
            label: Text(l10n.tOr('fePublishCatalog', 'Publish catalog')),
          );
  }
}
