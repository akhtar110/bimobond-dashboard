class UserDeviceEntity {
  const UserDeviceEntity({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.deviceName,
    this.macAddress,
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

  /// Stable device/install id from login / logout.
  final String deviceId;

  /// Human-readable label (e.g. "Hazem's iPhone").
  final String? deviceName;

  /// Client-reported hardware id when available.
  final String? macAddress;

  /// Cleared to null by server-side logout for this install.
  final String? fcmToken;
  final String deviceType;
  final String? osVersion;
  final String? appVersion;
  final String? lastActiveIp;
  final DateTime? lastActiveAt;
  final DateTime createdAt;

  bool get hasPushToken => fcmToken != null && fcmToken!.trim().isNotEmpty;
}
