import 'package:equatable/equatable.dart';

import '../models/sidebar_menu_group.dart';

class SidebarState extends Equatable {
  const SidebarState({
    this.isCollapsed = false,
    this.searchQuery = '',
    Set<String>? expandedGroups,
  }) : expandedGroups = expandedGroups ?? kDefaultExpandedSidebarGroups;

  final bool isCollapsed;
  final String searchQuery;
  final Set<String> expandedGroups;

  static const animationDuration = Duration(milliseconds: 300);

  SidebarState copyWith({
    bool? isCollapsed,
    String? searchQuery,
    Set<String>? expandedGroups,
  }) =>
      SidebarState(
        isCollapsed: isCollapsed ?? this.isCollapsed,
        searchQuery: searchQuery ?? this.searchQuery,
        expandedGroups: expandedGroups ?? this.expandedGroups,
      );

  bool isGroupExpanded(String groupId) => expandedGroups.contains(groupId);

  @override
  List<Object?> get props => [isCollapsed, searchQuery, expandedGroups];
}
