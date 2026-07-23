import '../../domain/entities/app_setting_entity.dart';
import '../../domain/entities/settings_admin_entities.dart';
import 'app_setting_model.dart';

class AppBrandingModel extends AppBrandingEntity {
  const AppBrandingModel({
    required super.id,
    required super.appName,
    super.tagline,
    super.supportEmail,
    super.logoUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory AppBrandingModel.fromJson(Map<String, dynamic> json) {
    return AppBrandingModel(
      id: json['id']?.toString() ?? '',
      appName: json['appName']?.toString() ?? 'DCC',
      tagline: json['tagline']?.toString(),
      supportEmail: json['supportEmail']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toPatchJson({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  }) {
    return {
      if (appName != null) 'appName': appName,
      if (tagline != null) 'tagline': tagline,
      if (supportEmail != null) 'supportEmail': supportEmail,
      if (logoUrl != null) 'logoUrl': logoUrl,
    };
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class AppCurrencyModel extends AppCurrencyEntity {
  const AppCurrencyModel({
    required super.id,
    required super.code,
    required super.name,
    super.symbol,
    super.isDefault,
    super.isActive,
    super.coinsPerUnit,
    super.createdAt,
    super.updatedAt,
  });

  factory AppCurrencyModel.fromJson(Map<String, dynamic> json) {
    return AppCurrencyModel(
      id: json['id']?.toString() ?? '',
      code: (json['code']?.toString() ?? '').toUpperCase(),
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString(),
      isDefault: json['isDefault'] == true,
      isActive: json['isActive'] != false,
      coinsPerUnit: _asDouble(json['coinsPerUnit']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'code': code,
        'name': name,
        if (symbol != null) 'symbol': symbol,
        'isDefault': isDefault,
        'isActive': isActive,
        if (coinsPerUnit != null) 'coinsPerUnit': coinsPerUnit,
      };

  Map<String, dynamic> toPatchJson() => {
        if (name.isNotEmpty) 'name': name,
        if (symbol != null) 'symbol': symbol,
        'isDefault': isDefault,
        'isActive': isActive,
        if (coinsPerUnit != null) 'coinsPerUnit': coinsPerUnit,
      };

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class SettingsDefaultsModel extends SettingsDefaultsEntity {
  const SettingsDefaultsModel({
    super.keys,
    super.commissionPercent,
    super.coinsPerPriceUnit,
    super.defaultCurrencyCode,
    super.commissionKey,
    super.coinsPerPriceUnitKey,
  });

  factory SettingsDefaultsModel.fromJson(Map<String, dynamic> json) {
    final keysRaw = json['keys'];
    final keys = <String, String>{};
    if (keysRaw is Map) {
      for (final entry in keysRaw.entries) {
        keys[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    final defaults = json['defaults'];
    final defaultsMap =
        defaults is Map ? Map<String, dynamic>.from(defaults) : const {};

    return SettingsDefaultsModel(
      keys: keys,
      commissionPercent:
          _asDouble(defaultsMap['commissionPercent']) ?? 25,
      coinsPerPriceUnit:
          _asDouble(defaultsMap['coinsPerPriceUnit']) ?? 100,
      defaultCurrencyCode:
          defaultsMap['defaultCurrencyCode']?.toString() ?? 'USD',
      commissionKey:
          json['commissionKey']?.toString() ?? 'AUCTION_COMMISSION_PERCENT',
      coinsPerPriceUnitKey:
          json['coinsPerPriceUnitKey']?.toString() ?? 'COINS_PER_PRICE_UNIT',
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class SettingsSeedResultModel extends SettingsSeedResultEntity {
  const SettingsSeedResultModel({
    required super.seeded,
    super.branding,
    super.settings,
  });

  factory SettingsSeedResultModel.fromJson(Map<String, dynamic> json) {
    final brandingRaw = json['branding'];
    final settingsRaw = json['settings'];
    return SettingsSeedResultModel(
      seeded: _asInt(json['seeded']) ?? 0,
      branding: brandingRaw is Map
          ? AppBrandingModel.fromJson(Map<String, dynamic>.from(brandingRaw))
          : null,
      settings: settingsRaw is List
          ? settingsRaw
              .whereType<Map>()
              .map(
                (e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class SettingsGroupedResultModel extends SettingsGroupedResultEntity {
  const SettingsGroupedResultModel({
    super.grouped,
    super.categories,
  });

  factory SettingsGroupedResultModel.fromJson(Map<String, dynamic> json) {
    final groupedRaw = json['grouped'];
    final grouped = <String, List<AppSettingEntity>>{};
    if (groupedRaw is Map) {
      for (final entry in groupedRaw.entries) {
        final list = entry.value;
        if (list is! List) {
          grouped[entry.key.toString()] = const [];
          continue;
        }
        grouped[entry.key.toString()] = list
            .whereType<Map>()
            .map(
              (e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    }

    final categoriesRaw = json['categories'];
    final categories = categoriesRaw is List
        ? categoriesRaw.map((e) => e.toString()).toList()
        : grouped.keys.toList();

    return SettingsGroupedResultModel(
      grouped: grouped,
      categories: categories,
    );
  }
}
