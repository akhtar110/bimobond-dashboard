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
  'security',
};

/// Current tab indices (21 tabs):
/// 0 Analytics, 1 Search Mgmt, 2 Users, 3 Locations, 4 Search History,
/// 5 Posts, 6 Stories, 7 Categories, 8 Chat, 9 Auctions, 10 Gifts,
/// 11 Wallets, 12 Promotions, 13 Sounds, 14 Reports, 15 Notifications,
/// 16 Filters & Effects, 17 Settings, 18 Roles, 19 Logs, 20 Profile
const kSidebarMenuGroups = <SidebarMenuGroupConfig>[
  SidebarMenuGroupConfig(
    id: 'overview',
    titleL10nKey: 'sidebarGroupOverview',
    fallbackTitle: 'Overview',
    itemIndices: [0, 1],
  ),
  SidebarMenuGroupConfig(
    id: 'users',
    titleL10nKey: 'sidebarGroupUsers',
    fallbackTitle: 'User Management',
    itemIndices: [2, 3, 4],
  ),
  SidebarMenuGroupConfig(
    id: 'content',
    titleL10nKey: 'sidebarGroupContent',
    fallbackTitle: 'Content Management',
    // Posts → Stories → Filters & Effects → Categories → Chat → Auctions →
    // Gifts → Wallets → Promotions
    itemIndices: [5, 6, 16, 7, 8, 9, 10, 11, 12],
  ),
  SidebarMenuGroupConfig(
    id: 'platform',
    titleL10nKey: 'sidebarGroupPlatform',
    fallbackTitle: 'Platform',
    // Sounds → Reports → Notifications → Settings
    itemIndices: [13, 14, 15, 17],
  ),
  SidebarMenuGroupConfig(
    id: 'security',
    titleL10nKey: 'sidebarGroupSecurity',
    fallbackTitle: 'Security',
    // Roles → Logs
    itemIndices: [18, 19],
  ),
];
