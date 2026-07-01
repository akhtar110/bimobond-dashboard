import '../../../users/domain/entities/user_entity.dart';
import '../entities/user_entity.dart';

bool isDashboardAdmin(DashboardUserEntity user) =>
    user.roles.contains(UserRole.admin);

bool isDashboardModerator(DashboardUserEntity user) =>
    user.roles.contains(UserRole.moderator) && !isDashboardAdmin(user);

bool isDashboardStaff(DashboardUserEntity user) =>
    user.roles.contains(UserRole.admin) ||
    user.roles.contains(UserRole.moderator);

bool canAccessDashboardTab(int tabIndex, List<UserRole> roles) {
  if (roles.contains(UserRole.admin)) return true;
  if (!roles.contains(UserRole.moderator)) return false;
  return switch (tabIndex) {
    0 => true, // analytics (monetization section hidden in UI)
    7 => true, // auctions
    10 => true, // promotions (read-only actions)
    12 => true, // reports / money reports
    13 => true, // notifications
    _ => false,
  };
}

bool canManageWallets(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canAdjustWallets(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canManageCoinPackages(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canManageSettings(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canViewMonetizationAnalytics(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canManageGiftsCatalog(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canWritePromotions(List<UserRole> roles) =>
    roles.contains(UserRole.admin);

bool canModerateAuctions(List<UserRole> roles) =>
    roles.contains(UserRole.admin) || roles.contains(UserRole.moderator);
