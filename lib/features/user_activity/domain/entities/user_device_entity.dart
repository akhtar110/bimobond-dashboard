class UserDeviceEntity {
  const UserDeviceEntity({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.fcmToken,
    required this.deviceType,
    this.osVersion,
    this.appVersion,
    this.lastActiveIp,
    this.lastActiveAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String? fcmToken;
  final String deviceType;
  final String? osVersion;
  final String? appVersion;
  final String? lastActiveIp;
  final DateTime? lastActiveAt;
  final DateTime createdAt;
}
