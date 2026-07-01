import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/web_dashboard_layout.dart';
import '../../bloc/sidebar_bloc.dart';
import '../../models/sidebar_menu_group.dart';
import 'sidebar_footer.dart';
import 'sidebar_header.dart';
import 'sidebar_menu_group.dart';
import 'sidebar_search.dart';

class SidebarContainer extends StatelessWidget {
  const SidebarContainer({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.tabVisible,
    this.showCollapseToggle = true,
    this.forceCollapsed,
    this.embedded = false,
  });

  final List<DashboardNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool Function(int tabIndex)? tabVisible;
  final bool showCollapseToggle;
  final bool? forceCollapsed;
  final bool embedded;

  static const expandedWidth = 300.0;
  static const collapsedWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SidebarBloc, SidebarState, _SidebarViewData>(
      selector: (state) => _SidebarViewData(
        collapsed: state.isCollapsed,
        searchQuery: state.searchQuery,
      ),
      builder: (context, data) {
        final scheme = Theme.of(context).colorScheme;
        final collapsed = forceCollapsed ?? data.collapsed;
        final width = collapsed ? collapsedWidth : expandedWidth;

        final radius = embedded ? 0.0 : 20.0;

        return AnimatedContainer(
          duration: SidebarState.animationDuration,
          curve: Curves.easeOutCubic,
          width: width,
          margin: embedded
              ? EdgeInsets.zero
              : const EdgeInsetsDirectional.fromSTEB(12, 12, 0, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: embedded
                  ? null
                  : Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
              boxShadow: embedded
                  ? null
                  : [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showCollapseToggle)
                      SidebarHeader(
                        collapsed: collapsed,
                        showToggle: showCollapseToggle,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: SidebarHeader(
                          collapsed: false,
                          showToggle: false,
                        ),
                      ),
                    SidebarSearch(collapsed: collapsed),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          for (final group in kSidebarMenuGroups)
                            SidebarMenuGroup(
                              group: group,
                              items: items,
                              currentIndex: currentIndex,
                              collapsed: collapsed,
                              searchQuery: data.searchQuery,
                              tabVisible: tabVisible,
                              onDestinationSelected: onDestinationSelected,
                            ),
                        ],
                      ),
                    ),
                    SidebarFooter(collapsed: collapsed),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarViewData {
  const _SidebarViewData({
    required this.collapsed,
    required this.searchQuery,
  });

  final bool collapsed;
  final String searchQuery;

  @override
  bool operator ==(Object other) =>
      other is _SidebarViewData &&
      collapsed == other.collapsed &&
      searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(collapsed, searchQuery);
}
