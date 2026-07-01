import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';

abstract final class NotificationScheduleUtils {
  static String timezoneLabel() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '-';
    final paddedHours = hours.abs().toString().padLeft(2, '0');
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    return 'UTC$sign$paddedHours:$paddedMinutes (${now.timeZoneName})';
  }

  static DateTime defaultScheduledDateTime() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      9,
      0,
    );
  }

  static bool isValidSchedule(DateTime? scheduledAt) {
    if (scheduledAt == null) return false;
    return scheduledAt.isAfter(DateTime.now());
  }

  static String? validationMessage(AppLocalizations l10n, DateTime? scheduledAt) {
    if (scheduledAt == null) {
      return l10n.t('notificationScheduleSelectDateTime');
    }
    if (!scheduledAt.isAfter(DateTime.now())) {
      return l10n.t('notificationSchedulePastError');
    }
    return null;
  }

  static String formatScheduledPreview(AppLocalizations l10n, DateTime scheduledAt) {
    final date = DateFormat.yMMMd().format(scheduledAt);
    final time = DateFormat.jm().format(scheduledAt);
    return l10n.tArgs('notificationSchedulePreview', {
      'date': date,
      'time': time,
      'timezone': timezoneLabel(),
    });
  }
}
