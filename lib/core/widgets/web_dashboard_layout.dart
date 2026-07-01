import 'package:flutter/material.dart';

import '../sidebar/presentation/widgets/sidebar_container.dart';

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

class WebDashboardLayout extends StatelessWidget {
  const WebDashboardLayout({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.currentPage,
    required this.onDestinationSelected,
    this.tabVisible,
  });

  final List<DashboardNavItem> items;
  final int currentIndex;
  final Widget currentPage;
  final ValueChanged<int> onDestinationSelected;
  final bool Function(int tabIndex)? tabVisible;

  static const desktopBreakpoint = 1000.0;
  static const tabletBreakpoint = 768.0;
  static const mobileDrawerBarHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > desktopBreakpoint;
    final isTablet =
        width > tabletBreakpoint && width <= desktopBreakpoint;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      drawer: isDesktop
          ? null
          : Drawer(
              width: SidebarContainer.expandedWidth + 8,
              child: SidebarContainer(
                embedded: true,
                items: items,
                currentIndex: currentIndex,
                tabVisible: tabVisible,
                onDestinationSelected: (index) {
                  Navigator.of(context).maybePop();
                  onDestinationSelected(index);
                },
                showCollapseToggle: false,
              ),
            ),
      appBar: isDesktop
          ? null
          : AppBar(
              toolbarHeight: mobileDrawerBarHeight,
              title: const SizedBox.shrink(),
              scrolledUnderElevation: 0,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            SidebarContainer(
              items: items,
              currentIndex: currentIndex,
              tabVisible: tabVisible,
              onDestinationSelected: onDestinationSelected,
              forceCollapsed: isTablet ? true : null,
            ),
          Expanded(
            child: _DashboardContent(
              child: SizedBox.expand(child: currentPage),
            ),
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
