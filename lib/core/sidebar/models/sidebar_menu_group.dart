/// Presentation-only grouping for sidebar navigation.
/// Item indices match [HomeShell] / [WebDashboardLayout] destination order.
class SidebarMenuGroupConfig {
  const SidebarMenuGroupConfig({
    required this.id,
    required this.titleL10nKey,
    required this.fallbackTitle,
    required this.itemIndices,
  });

  final String id;
  final String titleL10nKey;
  final String fallbackTitle;
  final List<int> itemIndices;
}

const kDefaultExpandedSidebarGroups = {
  'overview',
  'users',
  'content',
  'platform',
};

const kSidebarMenuGroups = <SidebarMenuGroupConfig>[
  SidebarMenuGroupConfig(
    id: 'overview',
    titleL10nKey: 'sidebarGroupOverview',
    fallbackTitle: 'Overview',
    itemIndices: [0],
  ),
  SidebarMenuGroupConfig(
    id: 'users',
    titleL10nKey: 'sidebarGroupUsers',
    fallbackTitle: 'User Management',
    itemIndices: [1, 2, 3],
  ),
  SidebarMenuGroupConfig(
    id: 'content',
    titleL10nKey: 'sidebarGroupContent',
    fallbackTitle: 'Content Management',
    itemIndices: [4, 14, 5, 6, 7, 8, 9, 10],
  ),
  SidebarMenuGroupConfig(
    id: 'platform',
    titleL10nKey: 'sidebarGroupPlatform',
    fallbackTitle: 'Platform',
    itemIndices: [11, 12, 13, 15],
  ),
];
