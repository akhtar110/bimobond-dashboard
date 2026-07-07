import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../reports_center_tab.dart';
import '../utils/reports_center_theme.dart';

class ReportsNavEntry {
  const ReportsNavEntry({
    required this.tab,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  final ReportsCenterTab tab;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
}

const reportsNavEntries = <ReportsNavEntry>[
  ReportsNavEntry(
    tab: ReportsCenterTab.moderation,
    labelKey: 'moderation',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
  ),
  ReportsNavEntry(
    tab: ReportsCenterTab.users,
    labelKey: 'users',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
  ),
  ReportsNavEntry(
    tab: ReportsCenterTab.posts,
    labelKey: 'posts',
    icon: Icons.play_circle_outline_rounded,
    selectedIcon: Icons.play_circle_rounded,
  ),
  ReportsNavEntry(
    tab: ReportsCenterTab.auctions,
    labelKey: 'auctions',
    icon: Icons.gavel_outlined,
    selectedIcon: Icons.gavel_rounded,
  ),
  ReportsNavEntry(
    tab: ReportsCenterTab.gifts,
    labelKey: 'gifts',
    icon: Icons.redeem_outlined,
    selectedIcon: Icons.redeem_rounded,
  ),
  ReportsNavEntry(
    tab: ReportsCenterTab.categories,
    labelKey: 'categories',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers_rounded,
  ),
];

class ReportsCenterNavRail extends StatelessWidget {
  const ReportsCenterNavRail({
    super.key,
    required this.width,
    required this.selected,
    required this.onSelected,
  });

  final double width;
  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 16),
          child: DecoratedBox(
            decoration: ReportsCenterTheme.navRailPanel(scheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: ReportsCenterTheme.accentWash(
                                scheme,
                                scheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.analytics_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.t('reportSections'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Moderation & analytics',
                        style: ReportsCenterTheme.muted(theme, scheme),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 12),
                    itemCount: reportsNavEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final entry = reportsNavEntries[index];
                      return _ReportsNavTile(
                        entry: entry,
                        selected: entry.tab == selected,
                        onTap: () => onSelected(entry.tab),
                      );
                    },
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

class ReportsCenterNavDrawer extends StatelessWidget {
  const ReportsCenterNavDrawer({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Drawer(
      width: 300,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
              child: Text(
                l10n.t('reportSections'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
              child: Text(
                'Moderation & analytics',
                style: ReportsCenterTheme.muted(Theme.of(context), scheme),
              ),
            ),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                itemCount: reportsNavEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final entry = reportsNavEntries[index];
                  return _ReportsNavTile(
                    entry: entry,
                    selected: entry.tab == selected,
                    onTap: () => onSelected(entry.tab),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsNavTile extends StatefulWidget {
  const _ReportsNavTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ReportsNavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ReportsNavTile> createState() => _ReportsNavTileState();
}

class _ReportsNavTileState extends State<_ReportsNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final selected = widget.selected;

    final bg = selected
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.12),
            scheme.primaryContainer.withValues(alpha: 0.45),
          )
        : _hovered
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.85)
            : Colors.transparent;

    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    final labelColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: ReportsCenterTheme.fast,
        curve: ReportsCenterTheme.ease,
        height: ReportsCenterTheme.navItemHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusMd),
          border: selected
              ? Border.all(color: scheme.primary.withValues(alpha: 0.22))
              : null,
          boxShadow: selected ? ReportsCenterTheme.shadowSm(scheme) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusMd),
            onTap: widget.onTap,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: ReportsCenterTheme.fast,
                  curve: ReportsCenterTheme.ease,
                  width: selected ? 4 : 0,
                  height: 28,
                  margin: EdgeInsetsDirectional.only(start: selected ? 6 : 10),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(width: selected ? 10 : 4),
                Icon(
                  selected ? widget.entry.selectedIcon : widget.entry.icon,
                  size: 20,
                  color: fg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t(widget.entry.labelKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                      letterSpacing: selected ? -0.1 : 0,
                    ),
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.7),
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
