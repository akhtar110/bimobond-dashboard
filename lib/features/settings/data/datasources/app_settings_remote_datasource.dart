import 'package:dio/dio.dart';

import '../models/app_setting_model.dart';
import '../models/settings_admin_models.dart';

abstract class AppSettingsRemoteDataSource {
  Future<List<AppSettingModel>> listSettings();
  Future<AppSettingModel> getSetting(String key);
  Future<AppSettingModel> createSetting(AppSettingModel setting);
  Future<AppSettingModel> updateSetting(AppSettingModel setting);
  Future<void> deleteSetting(String key);

  Future<SettingsGroupedResultModel> getGroupedSettings();
  Future<SettingsDefaultsModel> getDefaults();
  Future<SettingsSeedResultModel> seedSettings();

  Future<AppBrandingModel> getBranding();
  Future<AppBrandingModel> updateBranding({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  });

  Future<List<AppCurrencyModel>> listCurrencies();
  Future<AppCurrencyModel> createCurrency(AppCurrencyModel currency);
  Future<AppCurrencyModel> updateCurrency(AppCurrencyModel currency);
  Future<void> deleteCurrency(String code);
}

class AppSettingsRemoteDataSourceImpl implements AppSettingsRemoteDataSource {
  const AppSettingsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<AppSettingModel>> listSettings() async {
    final response = await _dio.get('/settings/admin');
    return _parseSettingList(response.data);
  }

  @override
  Future<AppSettingModel> getSetting(String key) async {
    final response = await _dio.get('/settings/admin/$key');
    return _parseSetting(response.data, fallbackKey: key);
  }

  @override
  Future<AppSettingModel> createSetting(AppSettingModel setting) async {
    final response = await _dio.post(
      '/settings/admin',
      data: setting.toCreateJson(),
    );
    return _parseSetting(response.data, fallback: setting);
  }

  @override
  Future<AppSettingModel> updateSetting(AppSettingModel setting) async {
    final response = await _dio.patch(
      '/settings/admin/${setting.key}',
      data: setting.toUpdateJson(),
    );
    return _parseSetting(response.data, fallback: setting);
  }

  @override
  Future<void> deleteSetting(String key) async {
    await _dio.delete('/settings/admin/$key');
  }

  @override
  Future<SettingsGroupedResultModel> getGroupedSettings() async {
    final response = await _dio.get('/settings/admin/grouped');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SettingsGroupedResultModel.fromJson(data);
    }
    if (data is Map) {
      return SettingsGroupedResultModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    return const SettingsGroupedResultModel();
  }

  @override
  Future<SettingsDefaultsModel> getDefaults() async {
    final response = await _dio.get('/settings/admin/defaults');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SettingsDefaultsModel.fromJson(data);
    }
    if (data is Map) {
      return SettingsDefaultsModel.fromJson(Map<String, dynamic>.from(data));
    }
    return const SettingsDefaultsModel();
  }

  @override
  Future<SettingsSeedResultModel> seedSettings() async {
    final response = await _dio.post('/settings/admin/seed');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SettingsSeedResultModel.fromJson(data);
    }
    if (data is Map) {
      return SettingsSeedResultModel.fromJson(Map<String, dynamic>.from(data));
    }
    return const SettingsSeedResultModel(seeded: 0);
  }

  @override
  Future<AppBrandingModel> getBranding() async {
    final response = await _dio.get('/settings/admin/branding');
    return _parseBranding(response.data);
  }

  @override
  Future<AppBrandingModel> updateBranding({
    String? appName,
    String? tagline,
    String? supportEmail,
    String? logoUrl,
  }) async {
    final response = await _dio.patch(
      '/settings/admin/branding',
      data: {
        if (appName != null) 'appName': appName,
        if (tagline != null) 'tagline': tagline,
        if (supportEmail != null) 'supportEmail': supportEmail,
        if (logoUrl != null) 'logoUrl': logoUrl,
      },
    );
    return _parseBranding(response.data);
  }

  @override
  Future<List<AppCurrencyModel>> listCurrencies() async {
    final response = await _dio.get('/settings/admin/currencies');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AppCurrencyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map) {
      final nested = data['currencies'] ?? data['data'] ?? data['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => AppCurrencyModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return const [];
  }

  @override
  Future<AppCurrencyModel> createCurrency(AppCurrencyModel currency) async {
    final response = await _dio.post(
      '/settings/admin/currencies',
      data: currency.toCreateJson(),
    );
    return _parseCurrency(response.data, fallback: currency);
  }

  @override
  Future<AppCurrencyModel> updateCurrency(AppCurrencyModel currency) async {
    final response = await _dio.patch(
      '/settings/admin/currencies/${currency.code}',
      data: currency.toPatchJson(),
    );
    return _parseCurrency(response.data, fallback: currency);
  }

  @override
  Future<void> deleteCurrency(String code) async {
    await _dio.delete('/settings/admin/currencies/$code');
  }

  List<AppSettingModel> _parseSettingList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['settings'] ?? map['data'] ?? map['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (map.containsKey('key')) {
        return [AppSettingModel.fromJson(map)];
      }
    }
    return const [];
  }

  AppSettingModel _parseSetting(
    dynamic data, {
    AppSettingModel? fallback,
    String? fallbackKey,
  }) {
    if (data is Map) {
      return AppSettingModel.fromJson(Map<String, dynamic>.from(data));
    }
    if (fallback != null) return fallback;
    return AppSettingModel(key: fallbackKey ?? '', value: '');
  }

  AppBrandingModel _parseBranding(dynamic data) {
    if (data is Map) {
      return AppBrandingModel.fromJson(Map<String, dynamic>.from(data));
    }
    return const AppBrandingModel(id: '', appName: 'DCC');
  }

  AppCurrencyModel _parseCurrency(
    dynamic data, {
    required AppCurrencyModel fallback,
  }) {
    if (data is Map) {
      return AppCurrencyModel.fromJson(Map<String, dynamic>.from(data));
    }
    return fallback;
  }
}
