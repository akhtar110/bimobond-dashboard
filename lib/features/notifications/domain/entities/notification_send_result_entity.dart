class NotificationSendResultEntity {
  const NotificationSendResultEntity({
    this.sentCount,
    this.notificationId,
    required this.success,
  });

  /// Number of notifications dispatched (bulk / broadcast).
  final int? sentCount;

  /// ID of the created notification (single send).
  final String? notificationId;

  final bool success;
}
