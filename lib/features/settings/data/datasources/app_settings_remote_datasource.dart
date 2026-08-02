import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/media_url_resolver.dart';
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

  /// Uploads a logo image via `POST /posts/upload` and returns the CDN URL.
  Future<String> uploadBrandingLogo(Uint8List bytes, String filename);

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
    // Admin API requires an absolute logo URL (see settings admin-api.md).
    final absoluteLogoUrl =
        logoUrl == null ? null : _toAbsoluteLogoUrl(logoUrl);
    final response = await _dio.patch(
      '/settings/admin/branding',
      data: {
        if (appName != null) 'appName': appName,
        if (tagline != null) 'tagline': tagline,
        if (supportEmail != null) 'supportEmail': supportEmail,
        if (absoluteLogoUrl != null) 'logoUrl': absoluteLogoUrl,
      },
    );
    return _parseBranding(response.data);
  }

  @override
  Future<String> uploadBrandingLogo(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw Exception('Logo upload failed: empty file');
    }
    final safeName =
        filename.trim().isEmpty ? 'branding-logo.png' : filename.trim();
    final lower = safeName.toLowerCase();
    final contentType = lower.endsWith('.svg')
        ? DioMediaType('image', 'svg+xml')
        : lower.endsWith('.png')
            ? DioMediaType('image', 'png')
            : lower.endsWith('.webp')
                ? DioMediaType('image', 'webp')
                : lower.endsWith('.gif')
                    ? DioMediaType('image', 'gif')
                    : DioMediaType('image', 'jpeg');

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'files',
        MultipartFile.fromBytes(
          bytes,
          filename: safeName,
          contentType: contentType,
        ),
      ),
    );

    final response = await _dio.post(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final extracted = _extractUploadUrl(response.data);
    if (extracted == null || extracted.isEmpty) {
      throw Exception(
        'Logo upload failed: no URL returned from server: ${response.data}',
      );
    }

    // PATCH /settings/admin/branding expects an absolute URL, not `/uploads/...`.
    final absolute = _toAbsoluteLogoUrl(extracted);
    if (!_isAbsoluteHttpUrl(absolute)) {
      throw Exception(
        'Logo upload failed: could not build absolute URL from: $extracted',
      );
    }
    return absolute;
  }

  /// Parses `POST /posts/upload` across Map/List shapes used by the API.
  String? _extractUploadUrl(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      return _parseUploadEntry(data);
    }

    if (data is List && data.isNotEmpty) {
      for (final item in data) {
        final parsed = _parseUploadEntry(item);
        if (parsed != null) return parsed;
      }
      return null;
    }

    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final topUrls = map['urls'];
    if (topUrls is List && topUrls.isNotEmpty) {
      for (final item in topUrls) {
        final parsed = _parseUploadEntry(item);
        if (parsed != null) return parsed;
      }
    }

    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      final nestedUrls = nestedMap['urls'];
      if (nestedUrls is List && nestedUrls.isNotEmpty) {
        for (final item in nestedUrls) {
          final parsed = _parseUploadEntry(item);
          if (parsed != null) return parsed;
        }
      }
      final fromNested = _extractUploadUrl(nestedMap);
      if (fromNested != null) return fromNested;
    } else if (nested is List || nested is String) {
      final fromNested = _extractUploadUrl(nested);
      if (fromNested != null) return fromNested;
    }

    return _parseUploadEntry(
      map['url'] ?? map['path'] ?? map['location'] ?? map['file'],
    );
  }

  String? _parseUploadEntry(dynamic entry) {
    if (entry == null) return null;
    if (entry is String) {
      final text = entry.trim();
      if (text.isEmpty) return null;
      // Never treat data URLs / raw payloads as an upload result.
      if (text.startsWith('data:') ||
          text.startsWith('{') ||
          text.startsWith('[')) {
        return null;
      }
      return text;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      for (final key in ['url', 'path', 'location', 'file']) {
        final parsed = _parseUploadEntry(map[key]);
        if (parsed != null) return parsed;
      }
      return null;
    }
    return null;
  }

  /// Branding `logoUrl` must be absolute (`https://…`).
  String _toAbsoluteLogoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (_isAbsoluteHttpUrl(trimmed)) return trimmed;

    // Prefer the `/uploads/…` segment when the API returns a longer path.
    final uploadsIndex = trimmed.indexOf('/uploads/');
    final path = uploadsIndex >= 0
        ? trimmed.substring(uploadsIndex)
        : (trimmed.startsWith('/') ? trimmed : '/$trimmed');

    return resolveMediaUrl(path) ?? path;
  }

  bool _isAbsoluteHttpUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

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
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        // Prefer nested payload when it looks like the branding object.
        if (nestedMap.containsKey('appName') ||
            nestedMap.containsKey('logoUrl') ||
            nestedMap.containsKey('id')) {
          map = nestedMap;
        }
      }
    }
    if (map == null) {
      return const AppBrandingModel(id: '', appName: 'DCC');
    }

    final model = AppBrandingModel.fromJson(map);
    final logoUrl = model.logoUrl?.trim();
    if (logoUrl == null || logoUrl.isEmpty) return model;

    final absolute = _toAbsoluteLogoUrl(logoUrl);
    if (absolute == logoUrl) return model;
    return AppBrandingModel(
      id: model.id,
      appName: model.appName,
      tagline: model.tagline,
      supportEmail: model.supportEmail,
      logoUrl: absolute,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
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
