import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_page_tab.dart';
import 'gifts_view_toggle.dart';

class GiftsSliverHeader extends StatelessWidget {
  const GiftsSliverHeader({
    super.key,
    required this.theme,
    required this.isLoading,
    required this.showViewToggle,
    required this.canAdd,
    required this.activeTab,
    required this.onTabChanged,
    required this.onAdd,
    required this.onRefresh,
  });

  final ThemeData theme;
  final bool isLoading;
  final bool showViewToggle;
  final bool canAdd;
  final GiftsPageTab activeTab;
  final ValueChanged<GiftsPageTab> onTabChanged;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (_, box) {
          final width = box.maxWidth;
          final pad = giftsPageHorizontalPadding(width);
          final compact = width < 480;
          final toolbarNarrow = width < 720;
          final inlineTabs = width >= 900;

          final refreshBtn = Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isLoading ? null : onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
          );

          final addBtn = compact
              ? FilledButton(
                  onPressed: canAdd ? onAdd : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 40),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                )
              : FilledButton.icon(
                  onPressed: canAdd ? onAdd : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.t('addGift')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

          final viewToggle = showViewToggle ? const GiftsViewToggle() : null;

          final tabs = _GiftsHeaderTabBar(
            activeTab: activeTab,
            onTabChanged: onTabChanged,
            compact: compact,
            maxWidth: inlineTabs ? 320 : width - pad * 2 - 24,
          );

          final actionRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (viewToggle != null && !toolbarNarrow) ...[
                viewToggle,
                const SizedBox(width: 8),
              ],
              addBtn,
              const SizedBox(width: 8),
              refreshBtn,
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1680),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (inlineTabs)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('gifts'),
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                      color: scheme.onSurface,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.t('giftsSubtitle'),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            tabs,
                            const SizedBox(width: 16),
                            actionRow,
                          ],
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('gifts'),
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                      color: scheme.onSurface,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.t('giftsSubtitle'),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!toolbarNarrow) actionRow,
                          ],
                        ),
                        const SizedBox(height: 12),
                        tabs,
                        if (toolbarNarrow) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ?viewToggle,
                              const Spacer(),
                              addBtn,
                              const SizedBox(width: 8),
                              refreshBtn,
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GiftsHeaderTabBar extends StatelessWidget {
  const _GiftsHeaderTabBar({
    required this.activeTab,
    required this.onTabChanged,
    required this.compact,
    required this.maxWidth,
  });

  final GiftsPageTab activeTab;
  final ValueChanged<GiftsPageTab> onTabChanged;
  final bool compact;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(220, 520)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconOnly = constraints.maxWidth < 280;

                return Row(
                  children: [
                    Expanded(
                      child: _GiftsHeaderTabSegment(
                        selected: activeTab == GiftsPageTab.catalog,
                        icon: Icons.card_giftcard_outlined,
                        selectedIcon: Icons.card_giftcard_rounded,
                        label: l10n.tOr('giftCatalogTab', 'Catalog'),
                        iconOnly: iconOnly,
                        compact: compact,
                        onTap: () => onTabChanged(GiftsPageTab.catalog),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _GiftsHeaderTabSegment(
                        selected: activeTab == GiftsPageTab.groups,
                        icon: Icons.tab_outlined,
                        selectedIcon: Icons.tab_rounded,
                        label: l10n.tOr('giftGroupsTab', 'Panel tabs'),
                        iconOnly: iconOnly,
                        compact: compact,
                        onTap: () => onTabChanged(GiftsPageTab.groups),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftsHeaderTabSegment extends StatelessWidget {
  const _GiftsHeaderTabSegment({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.iconOnly,
    required this.compact,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool iconOnly;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 8 : (compact ? 10 : 14),
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: compact ? 16 : 18,
                  color: fg,
                ),
                if (!iconOnly) ...[
                  SizedBox(width: compact ? 6 : 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: compact ? 12 : 13,
                            color: fg,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
