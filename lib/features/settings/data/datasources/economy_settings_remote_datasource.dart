import 'package:dio/dio.dart';

import '../../domain/entities/economy_setting_entity.dart';
import '../models/economy_setting_model.dart';

abstract class EconomySettingsRemoteDataSource {
  Future<EconomySettingModel> getSetting(String key);
  Future<EconomySettingModel> updateSetting(String key, String value);
}

class EconomySettingsRemoteDataSourceImpl
    implements EconomySettingsRemoteDataSource {
  const EconomySettingsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  static const _defaultValues = {
    EconomySettingKeys.auctionCommissionPercent: '25',
    EconomySettingKeys.coinsPerPriceUnit: '100',
  };

  @override
  Future<EconomySettingModel> getSetting(String key) async {
    try {
      final response = await _dio.get('/settings/admin/$key');
      return _parseSettingResponse(response.data, key);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      return _getSettingFallback(key);
    }
  }

  @override
  Future<EconomySettingModel> updateSetting(String key, String value) async {
    try {
      return await _patchSetting(key, value);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      await _seedDefaults();
      return _patchSetting(key, value);
    }
  }

  Future<EconomySettingModel> _patchSetting(String key, String value) async {
    final response = await _dio.patch(
      '/settings/admin/$key',
      data: {'value': value},
    );
    return _parseSettingResponse(response.data, key, fallbackValue: value);
  }

  EconomySettingModel _parseSettingResponse(
    dynamic data,
    String key, {
    String? fallbackValue,
  }) {
    if (data is Map<String, dynamic>) {
      return EconomySettingModel.fromJson(data, fallbackKey: key);
    }
    return EconomySettingModel(
      key: key,
      value: data?.toString() ?? fallbackValue ?? '',
    );
  }

  Future<EconomySettingModel> _getSettingFallback(String key) async {
    try {
      final response = await _dio.get('/settings/economy');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final value = switch (key) {
          EconomySettingKeys.coinsPerPriceUnit =>
            data['coinsPerPriceUnit']?.toString(),
          EconomySettingKeys.auctionCommissionPercent =>
            data['commissionPercent']?.toString(),
          _ => null,
        };
        if (value != null && value.isNotEmpty) {
          return EconomySettingModel(key: key, value: value);
        }
      }
    } on DioException {
      // Fall through to documented defaults.
    }

    return EconomySettingModel(
      key: key,
      value: _defaultValues[key] ?? '',
    );
  }

  Future<void> _seedDefaults() async {
    await _dio.post('/settings/admin/seed');
  }
}
