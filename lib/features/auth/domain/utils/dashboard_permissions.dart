import '../../../users/domain/entities/user_entity.dart';
import '../entities/user_entity.dart';

bool isDashboardAdmin(DashboardUserEntity user) => user.roles.includesAdmin;

bool isDashboardModerator(DashboardUserEntity user) =>
    user.roles.includesModerator && !isDashboardAdmin(user);

bool isDashboardStaff(DashboardUserEntity user) => user.roles.includesStaff;

bool canAccessDashboardTab(int tabIndex, List<UserRole> roles) {
  if (roles.includesAdmin) return true;
  if (!roles.includesModerator) return false;
  return switch (tabIndex) {
    0 => true, // analytics (monetization section hidden in UI)
    1 => true, // search management
    9 => true, // auctions
    12 => true, // promotions (read-only actions)
    14 => true, // reports / money reports
    15 => true, // notifications
    20 => true, // own admin profile
    // Camera Studio (16) is gated by camera_studio.admin.manage in the router.
    // Stories (6) is gated by stories.admin.read in the router.
    _ => false,
  };
}

bool canManageWallets(List<UserRole> roles) => roles.includesAdmin;

bool canAdjustWallets(List<UserRole> roles) => roles.includesAdmin;

bool canManageCoinPackages(List<UserRole> roles) => roles.includesAdmin;

bool canManageSettings(List<UserRole> roles) => roles.includesAdmin;

bool canViewMonetizationAnalytics(List<UserRole> roles) => roles.includesAdmin;

bool canManageGiftsCatalog(List<UserRole> roles) => roles.includesAdmin;

bool canWritePromotions(List<UserRole> roles) => roles.includesAdmin;

bool canModerateAuctions(List<UserRole> roles) => roles.includesStaff;

bool canManageFiltersEffects(List<UserRole> roles) => roles.includesAdmin;
