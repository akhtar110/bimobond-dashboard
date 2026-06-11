import 'package:flutter/material.dart';

import '../localization/localization.dart';

class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class WebDashboardLayout extends StatefulWidget {
  const WebDashboardLayout({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.currentPage,
    required this.onDestinationSelected,
  });

  final List<DashboardNavItem> items;
  final int currentIndex;
  final Widget currentPage;
  final ValueChanged<int> onDestinationSelected;

  static const desktopBreakpoint = 1000.0;
  static const sidebarExpandedWidth = 260.0;
  static const sidebarCollapsedWidth = 84.0;
  static const mobileDrawerBarHeight = 44.0;

  @override
  State<WebDashboardLayout> createState() => _WebDashboardLayoutState();
}

class _WebDashboardLayoutState extends State<WebDashboardLayout> {
  /// `false` = full menu (icons + labels); `true` = compact rail (icons only).
  bool _sidebarCollapsed = false;

  void _onDesktopDestinationSelected(int index) {
    widget.onDestinationSelected(index);
  }

  void _onMobileDestinationSelected(int index) {
    Navigator.of(context).maybePop();
    widget.onDestinationSelected(index);
  }

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width > WebDashboardLayout.desktopBreakpoint;
    final railWidth = _sidebarCollapsed
        ? WebDashboardLayout.sidebarCollapsedWidth
        : WebDashboardLayout.sidebarExpandedWidth;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              child: _Sidebar(
                compact: false,
                items: widget.items,
                currentIndex: widget.currentIndex,
                onDestinationSelected: _onMobileDestinationSelected,
              ),
            ),
      appBar: isDesktop
          ? null
          : AppBar(
              toolbarHeight: WebDashboardLayout.mobileDrawerBarHeight,
              title: const SizedBox.shrink(),
              scrolledUnderElevation: 0,
            ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: railWidth,
              child: ClipRect(
                child: OverflowBox(
                  alignment: AlignmentDirectional.topStart,
                  minWidth: WebDashboardLayout.sidebarExpandedWidth,
                  maxWidth: WebDashboardLayout.sidebarExpandedWidth,
                  child: _Sidebar(
                    compact: _sidebarCollapsed,
                    items: widget.items,
                    currentIndex: widget.currentIndex,
                    onDestinationSelected: _onDesktopDestinationSelected,
                    onToggleCollapse: _toggleSidebar,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _DashboardContent(child: widget.currentPage),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 12.0 : width < 1000 ? 16.0 : 20.0;
    final vertical = width < 600 ? 10.0 : 14.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1680),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            horizontal,
            vertical,
            horizontal,
            vertical,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.onToggleCollapse,
  });

  final bool compact;
  final List<DashboardNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: WebDashboardLayout.sidebarExpandedWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
          border: BorderDirectional(
            end: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.22),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 10 : 14,
              16,
              compact ? 10 : 14,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SidebarHeader(
                  compact: compact,
                  onToggleCollapse: onToggleCollapse,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _SidebarNavItem(
                        key: ValueKey(item.label),
                        item: item,
                        selected: index == currentIndex,
                        compact: compact,
                        onTap: () => onDestinationSelected(index),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemCount: items.length,
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

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.compact,
    this.onToggleCollapse,
  });

  final bool compact;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final logo = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.admin_panel_settings_rounded,
        color: scheme.onPrimaryContainer,
        size: 22,
      ),
    );

    final title = Text(
      l10n.t('bimoBondAdmin'),
      textAlign: TextAlign.start,
      maxLines: compact ? 3 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: compact ? 11 : 18,
        height: compact ? 1.25 : 1.2,
      ),
    );

    final toggle = onToggleCollapse == null
        ? null
        : _CollapseToggle(
            compact: compact,
            onPressed: onToggleCollapse!,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        logo,
        const SizedBox(height: 8),
        title,
        if (toggle != null) ...[
          const SizedBox(height: 10),
          toggle,
        ],
      ],
    );
  }
}

class _CollapseToggle extends StatelessWidget {
  const _CollapseToggle({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: compact ? 'Expand menu' : 'Collapse menu',
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              compact ? Icons.last_page_rounded : Icons.first_page_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    super.key,
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final DashboardNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = selected ? item.selectedIcon : item.icon;
    final bg = selected ? scheme.primaryContainer : Colors.transparent;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: Icon(icon, color: fg, size: 22),
                ),
              ),
              Expanded(
                child: compact
                    ? const SizedBox.shrink()
                    : Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
