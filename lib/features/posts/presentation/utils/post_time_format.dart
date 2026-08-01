import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Minutes since midnight for [TimeOfDay] (0–1439).
int postTimeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

TimeOfDay postMinutesToTime(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

String formatPostDisplayTime(int minutes, {String? locale}) {
  final time = postMinutesToTime(minutes);
  final now = DateTime.now();
  final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (locale != null && locale.isNotEmpty) {
    return DateFormat.jm(locale).format(dateTime);
  }
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Normalizes a start/end time pair so [from] is never after [to].
(int? from, int? to) normalizePostTimeRange({
  required bool isStart,
  required int pickedMinutes,
  int? from,
  int? to,
}) {
  var nextFrom = from;
  var nextTo = to;

  if (isStart) {
    nextFrom = pickedMinutes;
    if (nextTo != null && nextFrom > nextTo) nextTo = nextFrom;
  } else {
    nextTo = pickedMinutes;
    if (nextFrom != null && nextFrom > nextTo) nextFrom = nextTo;
  }

  return (nextFrom, nextTo);
}

int _minutesFromDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return local.hour * 60 + local.minute;
}

/// Inclusive time-of-day match for admin post filters.
bool postMatchesCreatedTimeRange(
  DateTime createdAt, {
  int? fromMinutes,
  int? toMinutes,
}) {
  if (fromMinutes == null && toMinutes == null) return true;

  final minutes = _minutesFromDateTime(createdAt);
  if (fromMinutes != null && toMinutes != null) {
    if (fromMinutes <= toMinutes) {
      return minutes >= fromMinutes && minutes <= toMinutes;
    }
    // Overnight window (e.g. 22:00 – 06:00).
    return minutes >= fromMinutes || minutes <= toMinutes;
  }
  if (fromMinutes != null) return minutes >= fromMinutes;
  return minutes <= toMinutes!;
}

/// Combined calendar-day and time-of-day match for admin post filters.
bool postMatchesCreatedDateTimeFilters(
  DateTime createdAt, {
  DateTime? from,
  DateTime? to,
  int? timeFromMinutes,
  int? timeToMinutes,
}) {
  if (from != null || to != null) {
    final day = DateTime(
      createdAt.toLocal().year,
      createdAt.toLocal().month,
      createdAt.toLocal().day,
    );
    if (from != null) {
      final fromDay = DateTime(from.year, from.month, from.day);
      if (day.isBefore(fromDay)) return false;
    }
    if (to != null) {
      final toDay = DateTime(to.year, to.month, to.day);
      if (day.isAfter(toDay)) return false;
    }
  }

  return postMatchesCreatedTimeRange(
    createdAt,
    fromMinutes: timeFromMinutes,
    toMinutes: timeToMinutes,
  );
}
