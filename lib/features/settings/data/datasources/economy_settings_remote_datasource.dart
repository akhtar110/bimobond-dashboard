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

  @override
  Future<EconomySettingModel> getSetting(String key) async {
    final response = await _dio.get('/settings/admin/$key');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return EconomySettingModel.fromJson(data, fallbackKey: key);
    }
    return EconomySettingModel(key: key, value: data?.toString() ?? '');
  }

  @override
  Future<EconomySettingModel> updateSetting(String key, String value) async {
    final response = await _dio.patch(
      '/settings/admin/$key',
      data: {'value': value},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return EconomySettingModel.fromJson(data, fallbackKey: key);
    }
    return EconomySettingModel(key: key, value: value);
  }
}
