import 'package:intl/intl.dart';

/// Formats a calendar date for admin posts API query params (`createdFrom` / `createdTo` / `date`).
String formatPostApiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatPostDisplayDate(DateTime date, {String? locale}) {
  final local = date.toLocal();
  if (locale != null && locale.isNotEmpty) {
    return DateFormat.yMMMd(locale).format(local);
  }
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

/// Formats a post's [createdAt] timestamp for list rows and detail views.
String formatPostCreatedDateTime(
  DateTime dateTime, {
  String? locale,
  bool compact = false,
}) {
  final local = dateTime.toLocal();
  final loc = (locale != null && locale.isNotEmpty) ? locale : 'en';
  final datePattern = compact ? 'MMM d' : 'MMM d, yyyy';
  final datePart = DateFormat(datePattern, loc).format(local);
  final timePart = DateFormat.jm(loc).format(local);
  return '$datePart · $timePart';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Earliest selectable day for post created-at filters.
DateTime get postFilterMinDate => DateTime(2020, 1, 1);

/// Bounds for [showDatePicker] so start/end stay in a valid range.
({DateTime firstDate, DateTime lastDate, DateTime initialDate})
postDatePickerBounds({
  required bool isStart,
  DateTime? from,
  DateTime? to,
  DateTime? preferredInitial,
}) {
  final now = dateOnly(DateTime.now());
  final start = from != null ? dateOnly(from) : null;
  final end = to != null ? dateOnly(to) : null;

  final firstDate = isStart ? postFilterMinDate : (start ?? postFilterMinDate);
  final lastDate = isStart ? (end ?? now) : now;

  final fallback = isStart ? (start ?? end ?? now) : (end ?? start ?? now);
  var initialDate = dateOnly(preferredInitial ?? fallback);

  if (initialDate.isBefore(firstDate)) initialDate = firstDate;
  if (initialDate.isAfter(lastDate)) initialDate = lastDate;

  return (firstDate: firstDate, lastDate: lastDate, initialDate: initialDate);
}

/// Normalizes a start/end pair so [from] is never after [to].
(DateTime? from, DateTime? to) normalizePostDateRange({
  required bool isStart,
  required DateTime picked,
  DateTime? from,
  DateTime? to,
}) {
  final day = dateOnly(picked);
  var nextFrom = from != null ? dateOnly(from) : null;
  var nextTo = to != null ? dateOnly(to) : null;

  if (isStart) {
    nextFrom = day;
    if (nextTo != null && nextFrom.isAfter(nextTo)) nextTo = nextFrom;
  } else {
    nextTo = day;
    if (nextFrom != null && nextFrom.isAfter(nextTo)) nextFrom = nextTo;
  }

  return (nextFrom, nextTo);
}

/// Inclusive calendar-day match for admin post date filters.
bool postMatchesCreatedDateRange(
  DateTime createdAt, {
  DateTime? from,
  DateTime? to,
}) {
  if (from == null && to == null) return true;
  final day = dateOnly(createdAt.toLocal());
  if (from != null && day.isBefore(dateOnly(from))) return false;
  if (to != null && day.isAfter(dateOnly(to))) return false;
  return true;
}
