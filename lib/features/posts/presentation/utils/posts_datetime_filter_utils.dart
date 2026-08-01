import 'package:intl/intl.dart';

import '../utils/post_date_format.dart';
import '../utils/post_time_format.dart';

/// Quick date-range presets for post created-at filters.
enum PostsDateTimePreset {
  all,
  today,
  yesterday,
  last30Days,
}

/// Snapshot of date + optional time-of-day filter state.
class PostsDateTimeFilterValue {
  const PostsDateTimeFilterValue({
    this.from,
    this.to,
    this.timeFromMinutes,
    this.timeToMinutes,
  });

  final DateTime? from;
  final DateTime? to;
  final int? timeFromMinutes;
  final int? timeToMinutes;

  bool get isEmpty =>
      from == null &&
      to == null &&
      timeFromMinutes == null &&
      timeToMinutes == null;

  bool get hasDateRange => from != null || to != null;
  bool get hasTimeRange => timeFromMinutes != null || timeToMinutes != null;

  PostsDateTimeFilterValue copyWith({
    DateTime? from,
    DateTime? to,
    int? timeFromMinutes,
    int? timeToMinutes,
    bool clearDates = false,
    bool clearTimes = false,
  }) {
    return PostsDateTimeFilterValue(
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      timeFromMinutes: clearTimes ? null : (timeFromMinutes ?? this.timeFromMinutes),
      timeToMinutes: clearTimes ? null : (timeToMinutes ?? this.timeToMinutes),
    );
  }

  PostsDateTimePreset? detectPreset({DateTime? now}) {
    if (!hasDateRange) return PostsDateTimePreset.all;
    final clock = now ?? DateTime.now();
    final startOfToday = dateOnly(clock);
    final fromDay = from != null ? dateOnly(from!) : null;
    final toDay = to != null ? dateOnly(to!) : null;

    if (fromDay != null &&
        toDay != null &&
        _sameDay(fromDay, startOfToday) &&
        _sameDay(toDay, startOfToday)) {
      return PostsDateTimePreset.today;
    }

    final yesterday = startOfToday.subtract(const Duration(days: 1));
    if (fromDay != null &&
        toDay != null &&
        _sameDay(fromDay, yesterday) &&
        _sameDay(toDay, yesterday)) {
      return PostsDateTimePreset.yesterday;
    }

    final thirtyDaysAgo = dateOnly(clock.subtract(const Duration(days: 30)));
    if (fromDay != null &&
        _sameDay(fromDay, thirtyDaysAgo) &&
        (toDay == null || _sameDay(toDay, startOfToday))) {
      return PostsDateTimePreset.last30Days;
    }

    return null;
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Applies a [preset] and returns the corresponding filter value.
PostsDateTimeFilterValue postsDateTimePresetValue(
  PostsDateTimePreset preset, {
  DateTime? now,
}) {
  if (preset == PostsDateTimePreset.all) {
    return const PostsDateTimeFilterValue();
  }

  final clock = now ?? DateTime.now();
  final today = dateOnly(clock);

  final (DateTime from, DateTime to) = switch (preset) {
    PostsDateTimePreset.today => (today, today),
    PostsDateTimePreset.yesterday => (
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 1)),
      ),
    PostsDateTimePreset.last30Days => (
        today.subtract(const Duration(days: 30)),
        today,
      ),
    PostsDateTimePreset.all => (today, today),
  };

  return PostsDateTimeFilterValue(from: from, to: to);
}

String postsDateTimePresetLabel(
  PostsDateTimePreset preset,
  String Function(String key) t,
) =>
    switch (preset) {
      PostsDateTimePreset.all => t('all'),
      PostsDateTimePreset.today => t('promoDateRangeToday'),
      PostsDateTimePreset.yesterday => t('postFilterYesterday'),
      PostsDateTimePreset.last30Days => t('promoDateRange30Days'),
    };

/// Human-readable label for date-only filters (toolbar Created button, chips).
String formatPostsDateFilterLabel(
  PostsDateTimeFilterValue value, {
  String? locale,
  required String Function(String key) t,
}) {
  if (!value.hasDateRange) return t('postFilterDateTimeSection');

  final preset = value.detectPreset();
  if (preset != null) {
    return postsDateTimePresetLabel(preset, t);
  }

  final loc = (locale != null && locale.isNotEmpty) ? locale : 'en';

  if (value.from != null && value.to != null) {
    if (_sameDay(value.from!, value.to!)) {
      return formatPostDisplayDate(value.from!, locale: locale);
    }
    return '${DateFormat.MMMd(loc).format(value.from!)} – '
        '${DateFormat.MMMd(loc).format(value.to!)}';
  }
  if (value.from != null) {
    return '${t('startDate')}: ${formatPostDisplayDate(value.from!, locale: locale)}';
  }
  return '${t('endDate')}: ${formatPostDisplayDate(value.to!, locale: locale)}';
}

/// Human-readable label for combined date + time filters.
String formatPostsDateTimeFilterLabel(
  PostsDateTimeFilterValue value, {
  String? locale,
  required String Function(String key) t,
}) {
  if (value.isEmpty) return t('postFilterDateTimeSection');

  final preset = value.detectPreset();
  if (preset != null && !value.hasTimeRange) {
    return postsDateTimePresetLabel(preset, t);
  }

  final loc = (locale != null && locale.isNotEmpty) ? locale : 'en';
  final parts = <String>[];

  if (preset != null) {
    parts.add(postsDateTimePresetLabel(preset, t));
  } else if (value.from != null && value.to != null) {
    if (_sameDay(value.from!, value.to!)) {
      parts.add(formatPostDisplayDate(value.from!, locale: locale));
    } else {
      parts.add(
        '${DateFormat.MMMd(loc).format(value.from!)} – '
        '${DateFormat.MMMd(loc).format(value.to!)}',
      );
    }
  } else if (value.from != null) {
    parts.add('${t('startDate')}: ${formatPostDisplayDate(value.from!, locale: locale)}');
  } else if (value.to != null) {
    parts.add('${t('endDate')}: ${formatPostDisplayDate(value.to!, locale: locale)}');
  }

  if (value.timeFromMinutes != null && value.timeToMinutes != null) {
    parts.add(
      '${formatPostDisplayTime(value.timeFromMinutes!, locale: locale)} – '
      '${formatPostDisplayTime(value.timeToMinutes!, locale: locale)}',
    );
  } else if (value.timeFromMinutes != null) {
    parts.add(
      '${t('startTime')}: '
      '${formatPostDisplayTime(value.timeFromMinutes!, locale: locale)}',
    );
  } else if (value.timeToMinutes != null) {
    parts.add(
      '${t('endTime')}: '
      '${formatPostDisplayTime(value.timeToMinutes!, locale: locale)}',
    );
  }

  return parts.join(' · ');
}

PostsDateTimeFilterValue postsDateTimeFromFilters({
  DateTime? from,
  DateTime? to,
  int? timeFromMinutes,
  int? timeToMinutes,
}) =>
    PostsDateTimeFilterValue(
      from: from,
      to: to,
      timeFromMinutes: timeFromMinutes,
      timeToMinutes: timeToMinutes,
    );
