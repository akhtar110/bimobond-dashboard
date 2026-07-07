import 'package:intl/intl.dart';

final _compact = NumberFormat.compact();

String formatCategoryReportCount(int value) => _compact.format(value);

String formatCategoryReportDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat.yMMMd().format(date.toLocal());
}
