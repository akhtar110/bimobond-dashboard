import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/effect_form_dialog.dart';
import '../dialogs/filter_form_dialog.dart';
import '../utils/filters_effects_responsive.dart';

/// Opens create-filter flow (same behavior as the tab create action).
Future<void> createCameraFilterFromManagement(BuildContext context) async {
  final saved = await openFilterEditor(context);
  if (!context.mounted || saved != true) return;
  context.read<FiltersEffectsBloc>().add(const LoadCameraFilters());
  context.read<FiltersEffectsBloc>().add(
    const ShowFiltersEffectsMessage(
      'feFilterCreatedSuccess',
      isError: false,
    ),
  );
}

/// Opens create-effect flow (same behavior as the tab create action).
Future<void> createCameraEffectFromManagement(BuildContext context) async {
  final saved = await openEffectEditor(context);
  if (!context.mounted || saved != true) return;
  context.read<FiltersEffectsBloc>().add(const LoadCameraEffects());
  context.read<FiltersEffectsBloc>().add(
    const ShowFiltersEffectsMessage(
      'feEffectCreatedSuccess',
      isError: false,
    ),
  );
}

/// Top navigation: Filters · Effects · Catalog.
class FiltersEffectsTabBar extends StatelessWidget {
  const FiltersEffectsTabBar({
    super.key,
    required this.activeTab,
    required this.metrics,
    this.onTabChanged,
    this.showCreateAction = true,
  });

  final FiltersEffectsTab activeTab;
  final FiltersEffectsLayoutMetrics metrics;
  final ValueChanged<FiltersEffectsTab>? onTabChanged;

  /// When false (small screens), create lives in the header instead.
  final bool showCreateAction;

  static FiltersEffectsTab normalizeTab(FiltersEffectsTab tab) {
    return switch (tab) {
      FiltersEffectsTab.filterCategories => FiltersEffectsTab.filters,
      FiltersEffectsTab.effectCategories => FiltersEffectsTab.effects,
      _ => tab,
    };
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final resolvedTab = normalizeTab(activeTab);

    final tabs = <(FiltersEffectsTab, String, IconData)>[
      (
        FiltersEffectsTab.filters,
        l10n.tOr('feFilters', 'Filters'),
        Icons.filter_vintage_rounded,
      ),
      (
        FiltersEffectsTab.effects,
        l10n.tOr('feEffects', 'Effects'),
        Icons.auto_awesome_rounded,
      ),
      (
        FiltersEffectsTab.arOverlays,
        l10n.tOr('arOverlays', 'AR Overlays'),
        Icons.layers_outlined,
      ),
      (
        FiltersEffectsTab.catalog,
        l10n.tOr('feCatalog', 'Catalog'),
        Icons.inventory_2_outlined,
      ),
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.isCompact ? 2 : 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackActions = showCreateAction &&
                (metrics.isCompact || constraints.maxWidth < 680);

            final actions = showCreateAction
                ? _TabActions(
                    activeTab: resolvedTab,
                    iconOnly: stackActions,
                  )
                : const SizedBox.shrink();

            final nav = DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++) ...[
                        if (i > 0) SizedBox(width: metrics.filterGap),
                        _NavChip(
                          label: tabs[i].$2,
                          icon: tabs[i].$3,
                          selected: resolvedTab == tabs[i].$1,
                          onTap: () {
                            final next = tabs[i].$1;
                            onTabChanged?.call(next);
                            context.read<FiltersEffectsBloc>().add(
                              FiltersEffectsTabChanged(next),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            if (!showCreateAction) {
              return nav;
            }

            if (stackActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nav,
                  SizedBox(height: metrics.filterGap),
                  actions,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: nav),
                SizedBox(width: metrics.filterGap + 4),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavChip extends StatefulWidget {
  const _NavChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavChip> createState() => _NavChipState();
}

class _NavChipState extends State<_NavChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : _hovered
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabActions extends StatelessWidget {
  const _TabActions({
    required this.activeTab,
    this.iconOnly = false,
  });

  final FiltersEffectsTab activeTab;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    context.select<RbacBloc, Set<String>?>(
      (b) => b.state.authContext?.permissionKeys,
    );
    final canManage = PermissionManager.canManageCameraStudio(context);
    if (!canManage) return const SizedBox.shrink();

    final loaded = context.select<FiltersEffectsBloc, FiltersEffectsLoaded?>((
      b,
    ) {
      final state = b.state;
      return state is FiltersEffectsLoaded ? state : null;
    });
    if (loaded == null) return const SizedBox.shrink();

    final l10n = context.l10n;

    return switch (activeTab) {
      FiltersEffectsTab.filters => _CreateButton(
        iconOnly: iconOnly,
        label: l10n.tOr('feCreateFilter', 'Create filter'),
        onPressed: () => createCameraFilterFromManagement(context),
      ),
      FiltersEffectsTab.effects => _CreateButton(
        iconOnly: iconOnly,
        label: l10n.tOr('feCreateEffect', 'Create effect'),
        onPressed: () => createCameraEffectFromManagement(context),
      ),
      FiltersEffectsTab.catalog ||
      FiltersEffectsTab.filterCategories ||
      FiltersEffectsTab.effectCategories ||
      FiltersEffectsTab.arOverlays => const SizedBox.shrink(),
    };
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.iconOnly,
    required this.label,
    required this.onPressed,
  });

  final bool iconOnly;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Tooltip(
          message: label,
          child: FilledButton(
            onPressed: onPressed,
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
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );
  }
}
