import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/presentation/bloc/settings_cubit.dart';
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
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    // Width / chrome only — search query rebuilds the menu list below.
    return BlocSelector<SidebarBloc, SidebarState, bool>(
      selector: (state) => forceCollapsed ?? state.isCollapsed,
      builder: (context, collapsed) {
        final scheme = Theme.of(context).colorScheme;
        final width = collapsed ? collapsedWidth : expandedWidth;
        final contentWidth = width;
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
              // Lay out at the target width and clip while the shell animates,
              // so expanded rows never overflow mid-tween (no per-frame rebuilds).
              child: SizedBox.expand(
                child: OverflowBox(
                  alignment: AlignmentDirectional.topStart,
                  minWidth: contentWidth,
                  maxWidth: contentWidth,
                  child: SizedBox(
                    width: contentWidth,
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
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: SidebarHeader(
                                collapsed: false,
                                showToggle: false,
                              ),
                            ),
                          SidebarSearch(collapsed: collapsed),
                          const SizedBox(height: 4),
                          Expanded(
                            child: BlocSelector<SidebarBloc, SidebarState,
                                String>(
                              selector: (state) => state.searchQuery,
                              builder: (context, searchQuery) {
                                return ListView(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  children: [
                                    for (final group in kSidebarMenuGroups)
                                      SidebarMenuGroup(
                                        group: group,
                                        items: items,
                                        currentIndex: currentIndex,
                                        collapsed: collapsed,
                                        searchQuery: searchQuery,
                                        tabVisible: tabVisible,
                                        onDestinationSelected:
                                            onDestinationSelected,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          SidebarFooter(collapsed: collapsed),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
