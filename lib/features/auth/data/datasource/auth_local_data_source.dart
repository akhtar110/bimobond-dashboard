import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(DashboardUserModel user);
  Future<DashboardUserModel?> getSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  static const String _sessionKey = 'user_session';

  @override
  Future<void> saveSession(DashboardUserModel user) async {
    final jsonString = json.encode(user.toJson());
    await _prefs.setString(_sessionKey, jsonString);
  }

  @override
  Future<DashboardUserModel?> getSession() async {
    final jsonString = _prefs.getString(_sessionKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return DashboardUserModel.fromJson(jsonMap);
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }
}
