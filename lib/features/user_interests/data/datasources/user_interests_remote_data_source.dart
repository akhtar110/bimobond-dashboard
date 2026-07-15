import 'package:dio/dio.dart';

import '../models/user_interests_response_model.dart';
import '../../domain/entities/user_interest_entities.dart';

abstract class UserInterestsRemoteDataSource {
  Future<UserInterestsResponseEntity> getUserInterests(String userId);
}

class UserInterestsRemoteDataSourceImpl
    implements UserInterestsRemoteDataSource {
  UserInterestsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserInterestsResponseEntity> getUserInterests(String userId) async {
    final response = await _dio.get('/users/admin/$userId/interests');
    return UserInterestsResponseModel.fromJson(_unwrap(response.data));
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        if (nested.containsKey('interests') ||
            nested.containsKey('notInterests') ||
            nested.containsKey('meta')) {
          return nested;
        }
      }
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Invalid user interests API response');
  }
}
