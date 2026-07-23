import 'package:equatable/equatable.dart';

import 'app_setting_entity.dart';

class AppBrandingEntity extends Equatable {
  const AppBrandingEntity({
    required this.id,
    required this.appName,
    this.tagline,
    this.supportEmail,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String appName;
  final String? tagline;
  final String? supportEmail;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppBrandingEntity copyWith({
    String? id,
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppBrandingEntity(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      tagline: tagline ?? this.tagline,
      supportEmail: supportEmail ?? this.supportEmail,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, appName, tagline, supportEmail, logoUrl, createdAt, updatedAt];
}

class AppCurrencyEntity extends Equatable {
  const AppCurrencyEntity({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.isDefault = false,
    this.isActive = true,
    this.coinsPerUnit,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? symbol;
  final bool isDefault;
  final bool isActive;
  final double? coinsPerUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppCurrencyEntity copyWith({
    String? id,
    String? code,
    String? name,
    String? symbol,
    bool? isDefault,
    bool? isActive,
    double? coinsPerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppCurrencyEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      coinsPerUnit: coinsPerUnit ?? this.coinsPerUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        symbol,
        isDefault,
        isActive,
        coinsPerUnit,
        createdAt,
        updatedAt,
      ];
}

class SettingsDefaultsEntity extends Equatable {
  const SettingsDefaultsEntity({
    this.keys = const {},
    this.commissionPercent = 25,
    this.coinsPerPriceUnit = 100,
    this.defaultCurrencyCode = 'USD',
    this.commissionKey = 'AUCTION_COMMISSION_PERCENT',
    this.coinsPerPriceUnitKey = 'COINS_PER_PRICE_UNIT',
  });

  final Map<String, String> keys;
  final double commissionPercent;
  final double coinsPerPriceUnit;
  final String defaultCurrencyCode;
  final String commissionKey;
  final String coinsPerPriceUnitKey;

  @override
  List<Object?> get props => [
        keys,
        commissionPercent,
        coinsPerPriceUnit,
        defaultCurrencyCode,
        commissionKey,
        coinsPerPriceUnitKey,
      ];
}

class SettingsSeedResultEntity extends Equatable {
  const SettingsSeedResultEntity({
    required this.seeded,
    this.branding,
    this.settings = const [],
  });

  final int seeded;
  final AppBrandingEntity? branding;
  final List<AppSettingEntity> settings;

  @override
  List<Object?> get props => [seeded, branding, settings];
}

class SettingsGroupedResultEntity extends Equatable {
  const SettingsGroupedResultEntity({
    this.grouped = const {},
    this.categories = const [],
  });

  final Map<String, List<AppSettingEntity>> grouped;
  final List<String> categories;

  List<AppSettingEntity> get flat {
    final out = <AppSettingEntity>[];
    for (final category in categories.isNotEmpty
        ? categories
        : grouped.keys.toList()) {
      out.addAll(grouped[category] ?? const []);
    }
    // Include any groups not listed in categories.
    for (final entry in grouped.entries) {
      if (categories.contains(entry.key)) continue;
      out.addAll(entry.value);
    }
    return out;
  }

  @override
  List<Object?> get props => [grouped, categories];
}
