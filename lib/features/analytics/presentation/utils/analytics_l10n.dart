import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Localized labels for the analytics dashboard.
abstract final class AnalyticsL10n {
  static String postType(BuildContext context, String type) => switch (type) {
        'VIDEO' => context.l10n.t('analyticsPostTypeVideo'),
        'IMAGE' => context.l10n.t('analyticsPostTypeImage'),
        'CAROUSEL' => context.l10n.t('analyticsPostTypeCarousel'),
        _ => type,
      };

  static String postStatus(BuildContext context, String status) => switch (status) {
        'PUBLISHED' => context.l10n.t('analyticsStatusPublished'),
        'HIDDEN' => context.l10n.t('analyticsStatusHidden'),
        'BANNED' => context.l10n.t('analyticsStatusBanned'),
        'EXPIRED' => context.l10n.t('analyticsStatusExpired'),
        _ => status,
      };

  static String roleLabel(BuildContext context, String role) => switch (role) {
        'ADMIN' => context.l10n.t('analyticsRoleAdmin'),
        'MODERATOR' => context.l10n.t('analyticsRoleModerator'),
        'USER' => context.l10n.t('analyticsRoleUser'),
        _ => role,
      };
}
