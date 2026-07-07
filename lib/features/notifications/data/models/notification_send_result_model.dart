import '../../domain/entities/notification_send_result_entity.dart';

class NotificationSendResultModel extends NotificationSendResultEntity {
  const NotificationSendResultModel({
    super.sentCount,
    super.notificationId,
    required super.success,
  });

  factory NotificationSendResultModel.fromJson(Map<String, dynamic> json) {
    final sentCount = (json['sentCount'] as num?)?.toInt();
    final id = json['id'] as String?;
    return NotificationSendResultModel(
      sentCount: sentCount,
      notificationId: id,
      success: true,
    );
  }

  factory NotificationSendResultModel.success({
    int? sentCount,
    String? notificationId,
  }) =>
      NotificationSendResultModel(
        sentCount: sentCount,
        notificationId: notificationId,
        success: true,
      );
}
