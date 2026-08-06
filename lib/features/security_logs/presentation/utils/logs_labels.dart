import '../../../../core/localization/localization.dart';
import '../../domain/entities/log_entity.dart';

String logsDash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '—' : text;
}

String logsActorRoleLabel(AppLocalizations l10n, String? role) {
  if (role == null || role.trim().isEmpty) {
    return l10n.tOr('logsCategoryAll', 'All');
  }
  return switch (role.trim().toUpperCase()) {
    'USER' => l10n.tOr('logsActorRoleUser', 'USER'),
    'ADMIN' => l10n.tOr('logsActorRoleAdmin', 'ADMIN'),
    'SYSTEM' => l10n.tOr('logsActorRoleSystem', 'SYSTEM'),
    _ => role.trim().toUpperCase(),
  };
}

String logsCategoryLabel(AppLocalizations l10n, String? category) {
  if (category == null || category.trim().isEmpty) {
    return l10n.tOr('logsCategoryAll', 'All');
  }
  return switch (category.trim().toUpperCase()) {
    'AUTH' => l10n.tOr('logsCategoryAuth', 'AUTH'),
    'SOCIAL' => l10n.tOr('logsCategorySocial', 'SOCIAL'),
    'CONTENT' => l10n.tOr('logsCategoryContent', 'CONTENT'),
    'COMMERCE' => l10n.tOr('logsCategoryCommerce', 'COMMERCE'),
    'MESSAGING' => l10n.tOr('logsCategoryMessaging', 'MESSAGING'),
    'MODERATION' => l10n.tOr('logsCategoryModeration', 'MODERATION'),
    'ADMIN' => l10n.tOr('logsCategoryAdmin', 'ADMIN'),
    'NAVIGATION' => l10n.tOr('logsCategoryNavigation', 'NAVIGATION'),
    'SETTINGS' => l10n.tOr('logsCategorySettings', 'SETTINGS'),
    _ => category.trim().toUpperCase(),
  };
}

String logsDisplayTitle(
  AppLocalizations l10n,
  LogEntity log, {
  required bool isArabic,
}) {
  if (isArabic) {
    final desc = log.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
  } else {
    final descEn = log.descriptionEn?.trim();
    if (descEn != null && descEn.isNotEmpty) return descEn;
    final desc = log.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
  }
  return logsActionLabel(l10n, log);
}

String logsActionLabel(AppLocalizations l10n, LogEntity log) {
  final rawAction = log.action.trim();
  if (rawAction.isEmpty) {
    final description = log.description?.trim() ?? '';
    return description.isEmpty ? '—' : description;
  }
  return _knownActionLabel(l10n, rawAction) ?? _humanizeActionCode(rawAction);
}

String logsActionCodeLabel(AppLocalizations l10n, String? action) {
  if (action == null || action.trim().isEmpty) {
    return l10n.tOr('logsCategoryAll', 'All');
  }
  return _knownActionLabel(l10n, action) ?? _humanizeActionCode(action);
}

String? _knownActionLabel(AppLocalizations l10n, String action) {
  return switch (action.trim().toUpperCase().replaceAll('-', '_')) {
    'AUTH_LOGIN' => l10n.tOr('logsActionLogin', 'Login'),
    'AUTH_LOGOUT' => l10n.tOr('logsActionLogout', 'Logout'),
    'AUTH_REGISTER' => l10n.tOr('logsActionRegister', 'Register'),
    'AUTH_PASSWORD_RESET' =>
      l10n.tOr('logsActionResetPassword', 'Reset password'),
    'AUTH_OTP_VERIFY' => l10n.tOr('logsActionOtpVerify', 'OTP verify'),
    'FOLLOW' => l10n.tOr('logsActionFollow', 'Follow'),
    'UNFOLLOW' => l10n.tOr('logsActionUnfollow', 'Unfollow'),
    'BLOCK_USER' => l10n.tOr('logsActionBlockUser', 'Block user'),
    'UNBLOCK_USER' => l10n.tOr('logsActionUnblockUser', 'Unblock user'),
    'POST_CREATE' => l10n.tOr('logsActionPostCreate', 'Create post'),
    'POST_DELETE' => l10n.tOr('logsActionPostDelete', 'Delete post'),
    'POST_LIKE' => l10n.tOr('logsActionPostLike', 'Like post'),
    'POST_UNLIKE' => l10n.tOr('logsActionPostUnlike', 'Unlike post'),
    'GIFT_SEND' => l10n.tOr('logsActionGiftSend', 'Send gift'),
    'MESSAGE_SEND' => l10n.tOr('logsActionMessageSend', 'Send message'),
    'REPORT_CREATE' => l10n.tOr('logsActionReportCreate', 'Create report'),
    'PROFILE_VIEW' => l10n.tOr('logsActionProfileView', 'Profile view'),
    'SCREEN_VIEW' => l10n.tOr('logsActionScreenView', 'Screen view'),
    'SEARCH' => l10n.tOr('logsActionSearch', 'Search'),
    'ADMIN_ACTION' => l10n.tOr('logsActionAdminAction', 'Admin action'),
    'USER_BAN' ||
    'BAN_USER' ||
    'BAN' ||
    'USER_UNBAN' ||
    'UNBAN_USER' ||
    'UNBAN' =>
      l10n.tOr('logsActionBanUnban', 'Ban / Unban'),
    _ => null,
  };
}

String _humanizeActionCode(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[.\-/]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  final words = normalized
      .split('_')
      .where((w) => w.trim().isNotEmpty)
      .map((w) => w.toLowerCase())
      .toList(growable: false);
  if (words.isEmpty) return value;
  final first = words.first;
  final rest = words.skip(1).join(' ');
  return '${first[0].toUpperCase()}${first.substring(1)}'
      '${rest.isEmpty ? '' : ' $rest'}';
}

List<String?> logsActorRoleDropdownItems() => [
      null,
      ...LogsQuery.actorRoleOptions,
    ];

List<String?> logsCategoryDropdownItems() => [
      null,
      ...LogsQuery.categoryOptions,
    ];

List<String?> logsActionDropdownItems(String? category) => [
      null,
      ...LogsQuery.actionsForCategory(category),
    ];
