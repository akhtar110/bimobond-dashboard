import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _compact = NumberFormat.compact();

String formatReportUsd(double value) => _currency.format(value);

String formatReportCount(int value) => _compact.format(value);

String formatReportDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat.yMMMd().format(date.toLocal());
}
