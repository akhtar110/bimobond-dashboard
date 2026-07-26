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

/// Top navigation: Filters · Effects · Catalog.
class FiltersEffectsTabBar extends StatelessWidget {
  const FiltersEffectsTabBar({
    super.key,
    required this.activeTab,
    required this.metrics,
    this.onTabChanged,
  });

  final FiltersEffectsTab activeTab;
  final FiltersEffectsLayoutMetrics metrics;
  final ValueChanged<FiltersEffectsTab>? onTabChanged;

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

    final actions = _TabActions(activeTab: resolvedTab, metrics: metrics);

    return Material(
      color: scheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.all(metrics.isCompact ? 8 : 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackActions =
                  metrics.isCompact || constraints.maxWidth < 680;

              final nav = DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : _hovered
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
  const _TabActions({required this.activeTab, required this.metrics});

  final FiltersEffectsTab activeTab;
  final FiltersEffectsLayoutMetrics metrics;

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
    final compact = metrics.isCompact;

    return switch (activeTab) {
      FiltersEffectsTab.filters => _CreateButton(
        compact: compact,
        label: l10n.tOr('feCreateFilter', 'Create filter'),
        onPressed: () => _createFilter(context),
      ),
      FiltersEffectsTab.effects => _CreateButton(
        compact: compact,
        label: l10n.tOr('feCreateEffect', 'Create effect'),
        onPressed: () => _createEffect(context),
      ),
      FiltersEffectsTab.catalog ||
      FiltersEffectsTab.filterCategories ||
      FiltersEffectsTab.effectCategories ||
      FiltersEffectsTab.arOverlays => const SizedBox.shrink(),
    };
  }

  Future<void> _createFilter(BuildContext context) async {
    final saved = await openFilterEditor(context);
    if (!context.mounted || saved != true) return;
    context.read<FiltersEffectsBloc>().add(const LoadCameraFilters());
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('feFilterCreatedSuccess'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _createEffect(BuildContext context) async {
    final saved = await openEffectEditor(context);
    if (!context.mounted || saved != true) return;
    context.read<FiltersEffectsBloc>().add(const LoadCameraEffects());
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('feEffectCreatedSuccess'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.compact,
    required this.label,
    required this.onPressed,
  });

  final bool compact;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
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
