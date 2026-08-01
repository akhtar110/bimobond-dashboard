import '../../domain/entities/user_device_entity.dart';

class UserDeviceModel extends UserDeviceEntity {
  const UserDeviceModel({
    required super.id,
    required super.userId,
    required super.deviceId,
    super.deviceName,
    super.macAddress,
    super.fcmToken,
    required super.deviceType,
    super.osVersion,
    super.appVersion,
    super.lastActiveIp,
    super.lastActiveAt,
    required super.createdAt,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: _optionalString(json['deviceName']),
      macAddress: _optionalString(json['macAddress']),
      fcmToken: _optionalString(json['fcmToken']),
      deviceType: json['deviceType']?.toString() ?? 'Unknown',
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      lastActiveIp: json['lastActiveIp'] as String?,
      lastActiveAt: _parseDate(json['lastActiveAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
