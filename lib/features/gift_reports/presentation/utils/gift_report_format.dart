import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';

/// Formats in-app coin amounts for gift reports (never USD).
String formatReportCoins(double value) => CoinFormat.coins(value);

String formatReportCount(int value) => value.toString();

String formatReportDate(DateTime? date) =>
    date == null ? '—' : DateFormat.yMMMd().format(date.toLocal());
