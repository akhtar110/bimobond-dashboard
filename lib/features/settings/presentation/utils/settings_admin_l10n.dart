import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';

/// Localized labels for admin settings tabs and category chips.
abstract final class SettingsAdminL10n {
  static String tabLabel(BuildContext context, String tabKey) {
    final l10n = context.l10n;
    return switch (tabKey) {
      'economy' => l10n.tOr('economyTab', 'Economy'),
      'branding' => l10n.tOr('tabBranding', 'Branding'),
      'commission' => l10n.tOr('tabCommission', 'Commission'),
      'currencies' => l10n.tOr('tabCurrencies', 'Currencies'),
      'auction' => l10n.tOr('tabAuction', 'Auction'),
      'promotion' => l10n.tOr('tabPromotion', 'Promotion'),
      'features' => l10n.tOr('tabFeatures', 'Features'),
      'notifications' => l10n.tOr('tabNotifications', 'Notifications'),
      'uploads' => l10n.tOr('tabUploads', 'Uploads'),
      'defaults' => l10n.tOr('tabDefaults', 'Defaults'),
      _ => tabKey,
    };
  }

  static String categoryLabel(BuildContext context, String? category) {
    final l10n = context.l10n;
    final key = (category ?? '').trim().toUpperCase();
    if (key.isEmpty) {
      return l10n.tOr('tabGeneral', 'General');
    }
    return switch (key) {
      'GENERAL' => l10n.tOr('tabGeneral', 'General'),
      'BRANDING' => l10n.tOr('tabBranding', 'Branding'),
      'ECONOMY' => l10n.tOr('economyTab', 'Economy'),
      'COMMISSION' => l10n.tOr('tabCommission', 'Commission'),
      'CURRENCY' => l10n.tOr('tabCurrencies', 'Currencies'),
      'AUCTION' => l10n.tOr('tabAuction', 'Auction'),
      'PROMOTION' => l10n.tOr('tabPromotion', 'Promotion'),
      'FEATURES' => l10n.tOr('tabFeatures', 'Features'),
      _ => category!,
    };
  }

  static List<String> resolveCategories(List<String> fromApi) {
    if (fromApi.isEmpty) return AppSettingCategories.all;
    final merged = <String>[...AppSettingCategories.all];
    for (final cat in fromApi) {
      final normalized = cat.trim().toUpperCase();
      if (normalized.isNotEmpty && !merged.contains(normalized)) {
        merged.add(normalized);
      }
    }
    return merged;
  }
}
