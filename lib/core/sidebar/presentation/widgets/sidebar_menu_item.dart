import 'package:flutter/material.dart';

import '../../../widgets/web_dashboard_layout.dart';
import 'sidebar_tooltip.dart';

class SidebarMenuItem extends StatefulWidget {
  const SidebarMenuItem({
    super.key,
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.searchQuery,
    required this.onTap,
  });

  final DashboardNavItem item;
  final bool selected;
  final bool collapsed;
  final String searchQuery;
  final VoidCallback onTap;

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = widget.selected ? widget.item.selectedIcon : widget.item.icon;
    final label = _highlightedLabel(context, widget.item.label);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: 44,
      margin: EdgeInsetsDirectional.only(
        start: widget.collapsed ? 6 : 10,
        end: widget.collapsed ? 6 : 10,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: widget.selected
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : _hovered
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.85)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: widget.selected
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (widget.selected)
            PositionedDirectional(
              start: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Builder(
            builder: (context) {
              final iconWidget = AnimatedScale(
                scale: _hovered ? 1.06 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  icon,
                  size: 22,
                  color: widget.selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              );

              if (widget.collapsed) {
                return Center(child: iconWidget);
              }

              return Row(
                children: [
                  SizedBox(width: 48, child: Center(child: iconWidget)),
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                      child: label,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    final interactive = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: content,
        ),
      ),
    );

    if (widget.collapsed) {
      return SidebarTooltip(
        message: widget.item.label,
        child: interactive,
      );
    }

    return interactive;
  }

  Widget _highlightedLabel(BuildContext context, String label) {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty || !label.toLowerCase().contains(query)) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final scheme = Theme.of(context).colorScheme;
    final index = label.toLowerCase().indexOf(query);
    final before = label.substring(0, index);
    final match = label.substring(index, index + query.length);
    final after = label.substring(index + query.length);

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
