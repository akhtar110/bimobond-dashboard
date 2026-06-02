import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(DashboardUserModel user);
  Future<DashboardUserModel?> getSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage storage;
  static const String _sessionKey = 'user_session';

  AuthLocalDataSourceImpl(this.storage);

  @override
  Future<void> saveSession(DashboardUserModel user) async {
    final jsonString = json.encode(user.toJson());
    await storage.write(key: _sessionKey, value: jsonString);
  }

  @override
  Future<DashboardUserModel?> getSession() async {
    final jsonString = await storage.read(key: _sessionKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return DashboardUserModel.fromJson(jsonMap);
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    await storage.delete(key: _sessionKey);
  }
}
