import 'post_time_format.dart';

String formatPostsTimeRangeLabel({
  required int? fromMinutes,
  required int? toMinutes,
  String? locale,
  required String Function(String key) t,
}) {
  if (fromMinutes == null && toMinutes == null) {
    return t('postFilterTimeRange');
  }

  if (fromMinutes != null && toMinutes != null) {
    return '${formatPostDisplayTime(fromMinutes, locale: locale)} – '
        '${formatPostDisplayTime(toMinutes, locale: locale)}';
  }
  if (fromMinutes != null) {
    return '${t('startTime')}: ${formatPostDisplayTime(fromMinutes, locale: locale)}';
  }
  return '${t('endTime')}: ${formatPostDisplayTime(toMinutes!, locale: locale)}';
}
