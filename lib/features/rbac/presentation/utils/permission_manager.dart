import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../bloc/rbac_bloc.dart';

/// Documented backend permission keys the RBAC screens gate on.
abstract final class RbacPermissionKeys {
  /// Required for role create/edit/delete.
  static const manageRoles = 'users.admin.roles.manage';

  /// Required alongside [manageRoles] for user role assignment: the PUT
  /// service checks both keys.
  static const assignRoles = 'users.admin.roles.assign';

  /// Required for admin password reset (`PATCH /users/admin/:id/password`).
  static const resetUserPassword = 'users.admin.password.reset';

  /// Users admin list / investigation read (`GET /users`, detail tabs).
  static const readUsers = 'users.admin.read';

  /// Users admin update / delete (`PATCH /users/admin/:id`, `DELETE /users/:id`, bulk).
  static const updateUsers = 'users.admin.update';

  /// Ban / unban (`PATCH /users/:id/ban|unban`).
  static const banUsers = 'users.admin.ban';

  /// Search-history admin ops.
  static const searchHistory = 'users.admin.search_history';

  /// User location history / movements.
  static const userLocations = 'users.admin.locations';

  /// Activity admin read (`GET /activity/admin/*`).
  static const activityAdminRead = 'activity.admin.read';

  /// Required for Camera Studio / Filters & Effects admin management.
  static const manageCameraStudio = 'camera_studio.admin.manage';

  /// Stories admin catalog (`GET /stories/admin/all`).
  static const readStories = 'stories.admin.read';

  /// Story metadata updates (`PATCH /stories/admin/:id`).
  static const updateStories = 'stories.admin.update';

  /// Story hard-delete (`DELETE /stories/admin/:id`).
  static const deleteStories = 'stories.admin.delete';

  /// Sounds admin library (`/sounds/admin/*`).
  static const manageSounds = 'sounds.admin.manage';

  /// Auctions admin catalog (`GET /auctions/admin/all`).
  static const readAuctions = 'auctions.admin.read';

  /// Auction cancel, ban, and metadata updates.
  static const moderateAuctions = 'auctions.admin.moderate';

  /// Force resolve winner (`PATCH /auctions/admin/:id/resolve`).
  static const resolveAuctions = 'auctions.admin.resolve';

  /// Escrow refund / release (`PATCH .../fulfillment/*`).
  static const fulfillAuctions = 'auctions.admin.fulfillment';

  /// Seller verification queue (`GET /seller-verification/admin/all`).
  static const readSellerVerification = 'seller_verification.admin.read';

  /// Approve / reject seller applications.
  static const reviewSellerVerification = 'seller_verification.admin.review';

  /// Settings admin read (`GET /settings/admin/*`).
  static const readSettings = 'settings.admin.read';

  /// Settings admin write (create / patch / delete / seed / branding).
  static const writeSettings = 'settings.admin.write';

  /// Currencies CRUD (`/settings/admin/currencies`).
  static const manageCurrencies = 'settings.admin.currencies';

  /// Chat admin list / search / messages (`GET /chats/admin/*`).
  static const readChat = 'chat.admin.read';

  /// Chat moderation (soft-delete messages, update groups, delete chats, bulk).
  static const moderateChat = 'chat.admin.moderate';

  static const assignmentKeys = [assignRoles, manageRoles];
}

/// Static helpers reading the current auth context from the nearest
/// [RbacBloc]. Returns false while the context has not loaded yet.
abstract final class PermissionManager {
  static bool hasPermission(BuildContext context, String permission) =>
      _keys(context)?.contains(permission) ?? false;

  static bool hasAny(BuildContext context, Iterable<String> permissions) {
    final keys = _keys(context);
    if (keys == null) return false;
    return permissions.any(keys.contains);
  }

  static bool hasAll(BuildContext context, Iterable<String> permissions) {
    final keys = _keys(context);
    if (keys == null) return false;
    return permissions.every(keys.contains);
  }

  /// Coarse legacy `ADMIN` role — used only as a fallback while RBAC
  /// permissions catch up (same rule as the RBAC access boundary).
  static bool isLegacyAdmin(BuildContext context) {
    try {
      final auth = context.read<AuthBloc>().state;
      return auth is Authenticated && auth.user.roles.contains(UserRole.admin);
    } on ProviderNotFoundException {
      return false;
    }
  }

  /// Role CRUD (`users.admin.roles.manage`) or legacy admin.
  static bool canManageRoles(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.manageRoles) ||
      isLegacyAdmin(context);

  /// User role assignment needs both assign + manage on the backend; legacy
  /// admins are allowed through the same fallback as the RBAC section.
  static bool canAssignRoles(BuildContext context) =>
      hasAll(context, RbacPermissionKeys.assignmentKeys) ||
      isLegacyAdmin(context);

  /// Legacy role promote/demote / `PATCH /users/:id/role` — needs assign only.
  static bool canAssignUserLegacyRoles(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.assignRoles) ||
      isLegacyAdmin(context);

  static bool canReadUsers(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readUsers) ||
      isLegacyAdmin(context);

  static bool canUpdateUsers(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.updateUsers) ||
      isLegacyAdmin(context);

  static bool canBanUsers(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.banUsers) ||
      isLegacyAdmin(context);

  static bool canResetUserPassword(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.resetUserPassword) ||
      isLegacyAdmin(context);

  static bool canAccessSearchHistory(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.searchHistory) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  static bool canAccessUserLocations(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.userLocations) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  /// Camera Studio catalog management (`camera_studio.admin.manage`) or
  /// legacy admin while RBAC catches up.
  static bool canManageCameraStudio(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.manageCameraStudio) ||
      isLegacyAdmin(context);

  static bool canReadStories(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readStories) ||
      isLegacyAdmin(context);

  static bool canUpdateStories(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.updateStories) ||
      isLegacyAdmin(context);

  static bool canDeleteStories(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.deleteStories) ||
      isLegacyAdmin(context);

  static bool canManageSounds(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.manageSounds) ||
      isLegacyAdmin(context);

  static bool isLegacyModerator(BuildContext context) {
    try {
      final auth = context.read<AuthBloc>().state;
      return auth is Authenticated &&
          auth.user.roles.contains(UserRole.moderator);
    } on ProviderNotFoundException {
      return false;
    }
  }

  static bool canReadAuctions(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readAuctions) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  static bool canModerateAuctions(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.moderateAuctions) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  static bool canResolveAuctions(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.resolveAuctions) ||
      isLegacyAdmin(context);

  static bool canFulfillAuctions(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.fulfillAuctions) ||
      hasPermission(context, RbacPermissionKeys.resolveAuctions) ||
      isLegacyAdmin(context);

  static bool canReadSellerVerification(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readSellerVerification) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  static bool canReviewSellerVerification(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.reviewSellerVerification) ||
      isLegacyAdmin(context);

  static bool canReadSettings(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readSettings) ||
      hasPermission(context, RbacPermissionKeys.writeSettings) ||
      isLegacyAdmin(context);

  static bool canWriteSettings(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.writeSettings) ||
      isLegacyAdmin(context);

  static bool canManageCurrencies(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.manageCurrencies) ||
      isLegacyAdmin(context);

  /// Chat admin read (`GET /chats/admin/all`, detail, messages).
  static bool canReadChatAdmin(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.readChat) ||
      hasPermission(context, RbacPermissionKeys.moderateChat) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  /// Chat moderation (delete messages/chats, bulk, PATCH group metadata).
  static bool canModerateChatAdmin(BuildContext context) =>
      hasPermission(context, RbacPermissionKeys.moderateChat) ||
      isLegacyAdmin(context) ||
      isLegacyModerator(context);

  /// Mirrors HomeShell tab visibility: fine-grained RBAC keys where defined,
  /// otherwise legacy admin / moderator dashboard tab rules.
  static bool canAccessDashboardTab(BuildContext context, int tabIndex) {
    final permissions = _keys(context) ?? const <String>{};
    final roles = _roles(context);

    if (tabIndex == 16) {
      return permissions.contains(RbacPermissionKeys.manageCameraStudio) ||
          roles.contains(UserRole.admin);
    }
    if (tabIndex == 6) {
      return permissions.contains(RbacPermissionKeys.readStories) ||
          roles.contains(UserRole.admin);
    }
    if (tabIndex == 13) {
      return permissions.contains(RbacPermissionKeys.manageSounds) ||
          roles.contains(UserRole.admin);
    }
    if (tabIndex == 18) {
      return permissions.contains(RbacPermissionKeys.manageRoles) ||
          roles.contains(UserRole.admin);
    }
    if (tabIndex == 2) {
      return permissions.contains(RbacPermissionKeys.readUsers) ||
          roles.contains(UserRole.admin);
    }
    if (tabIndex == 8) {
      return permissions.contains(RbacPermissionKeys.readChat) ||
          permissions.contains(RbacPermissionKeys.moderateChat) ||
          roles.contains(UserRole.admin) ||
          roles.contains(UserRole.moderator);
    }

    if (roles.contains(UserRole.admin)) return true;
    if (!roles.contains(UserRole.moderator)) return false;
    return switch (tabIndex) {
      0 => true, // analytics
      1 => true, // search management
      9 => true, // auctions
      12 => true, // promotions
      14 => true, // reports
      15 => true, // notifications
      _ => false,
    };
  }

  /// Admin-only surfaces (users, posts, wallets, settings, …).
  static bool canAccessAdminDashboard(BuildContext context) =>
      isLegacyAdmin(context);

  /// Staff surfaces allowed for admin or moderator.
  static bool canAccessStaffDashboard(BuildContext context) =>
      isLegacyAdmin(context) || isLegacyModerator(context);

  static List<UserRole> _roles(BuildContext context) {
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is Authenticated) return auth.user.roles;
    } on ProviderNotFoundException {
      // Fall through.
    }
    return const [];
  }

  static Set<String>? _keys(BuildContext context) {
    final rbacBloc = _tryReadRbacBloc(context);
    return rbacBloc?.state.authContext?.permissionKeys;
  }

  static RbacBloc? _tryReadRbacBloc(BuildContext context) {
    try {
      return context.read<RbacBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// Shows [child] only when the current auth context grants the requested
/// permissions. While the context has not loaded yet (null), [fallback] is
/// shown so protected UI never appears without a verified grant.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.child,
    this.permission,
    this.anyOf = const [],
    this.allOf = const [],
    this.allowLegacyAdmin = false,
    this.fallback = const SizedBox.shrink(),
  }) : assert(
         permission != null || anyOf.length > 0 || allOf.length > 0,
         'Specify a permission, anyOf, or allOf.',
       );

  final String? permission;
  final List<String> anyOf;
  final List<String> allOf;
  final bool allowLegacyAdmin;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext,
      builder: (context, state) {
        if (allowLegacyAdmin && PermissionManager.isLegacyAdmin(context)) {
          return child;
        }
        final auth = state.authContext;
        if (auth == null) return fallback;
        final keys = auth.permissionKeys;
        final allowed =
            (permission == null || keys.contains(permission)) &&
            (anyOf.isEmpty || anyOf.any(keys.contains)) &&
            (allOf.isEmpty || allOf.every(keys.contains));
        return allowed ? child : fallback;
      },
    );
  }
}
