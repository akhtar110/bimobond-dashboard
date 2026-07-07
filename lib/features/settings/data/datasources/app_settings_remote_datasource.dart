import 'package:dio/dio.dart';

import '../models/app_setting_model.dart';

abstract class AppSettingsRemoteDataSource {
  Future<List<AppSettingModel>> listSettings();
  Future<AppSettingModel> createSetting(AppSettingModel setting);
  Future<AppSettingModel> updateSetting(AppSettingModel setting);
  Future<void> deleteSetting(String key);
}

class AppSettingsRemoteDataSourceImpl implements AppSettingsRemoteDataSource {
  const AppSettingsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<AppSettingModel>> listSettings() async {
    final response = await _dio.get('/settings/admin');
    return _parseList(response.data);
  }

  @override
  Future<AppSettingModel> createSetting(AppSettingModel setting) async {
    final response = await _dio.post(
      '/settings/admin',
      data: setting.toCreateJson(),
    );
    return _parseSingle(response.data, fallback: setting);
  }

  @override
  Future<AppSettingModel> updateSetting(AppSettingModel setting) async {
    final response = await _dio.patch(
      '/settings/admin/${setting.key}',
      data: setting.toUpdateJson(),
    );
    return _parseSingle(response.data, fallback: setting);
  }

  @override
  Future<void> deleteSetting(String key) async {
    await _dio.delete('/settings/admin/$key');
  }

  List<AppSettingModel> _parseList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final nested = data['settings'] ?? data['data'] ?? data['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => AppSettingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data.containsKey('key')) {
        return [AppSettingModel.fromJson(data)];
      }
    }
    return const [];
  }

  AppSettingModel _parseSingle(
    dynamic data, {
    required AppSettingModel fallback,
  }) {
    if (data is Map<String, dynamic>) {
      return AppSettingModel.fromJson(data);
    }
    return fallback;
  }
}
