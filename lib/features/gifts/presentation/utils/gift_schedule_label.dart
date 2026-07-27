import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';

/// Publish-status bucket used to pick an icon / color for [GiftScheduleLabel].
enum GiftScheduleStatus { availableNow, publishesTomorrow, scheduled, published }

/// Resolved label + status for a gift's publish schedule, shared by
/// [GiftCard] and the gift dialogs' preview rows.
class GiftScheduleLabel {
  const GiftScheduleLabel({required this.status, required this.text});

  final GiftScheduleStatus status;
  final String text;
}

final _giftScheduleDateFmt = DateFormat('MMM d, yyyy');

/// Builds a human-friendly publish schedule label for [gift]:
/// - "Available Now" when there is no publish date set.
/// - "Publishes Tomorrow" when scheduled for the next calendar day.
/// - "Scheduled · {date}" when scheduled further in the future.
/// - "Published on {date}" once the publish date has passed.
GiftScheduleLabel giftScheduleLabelFor(AppLocalizations l10n, GiftEntity gift) {
  final at = gift.publishedAt;
  if (at == null) {
    return GiftScheduleLabel(
      status: GiftScheduleStatus.availableNow,
      text: l10n.tOr('giftPublishedNow', 'Available Now'),
    );
  }

  final local = at.toLocal();
  final formattedDate = _giftScheduleDateFmt.format(local);

  if (gift.isScheduled) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    if (targetDay.difference(todayDay).inDays == 1) {
      return GiftScheduleLabel(
        status: GiftScheduleStatus.publishesTomorrow,
        text: l10n.tOr('giftPublishesTomorrow', 'Publishes Tomorrow'),
      );
    }
    return GiftScheduleLabel(
      status: GiftScheduleStatus.scheduled,
      text: '${l10n.tOr('giftScheduled', 'Scheduled')} · $formattedDate',
    );
  }

  final template = l10n.tOr('giftPublishedOn', 'Published on {date}');
  return GiftScheduleLabel(
    status: GiftScheduleStatus.published,
    text: template.replaceAll('{date}', formattedDate),
  );
}
