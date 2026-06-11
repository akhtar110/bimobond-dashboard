import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/analytics_entities.dart';

abstract final class AnalyticsFormat {
  static final _compact = NumberFormat.compact();
  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _currencyPrecise =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _date = DateFormat('MMM d');
  static final _dateTime = DateFormat('MMM d, yyyy');

  static String count(num value) => _compact.format(value);
  static String usd(num value) =>
      value >= 1000 ? _currency.format(value) : _currencyPrecise.format(value);

  static String shortDate(DateTime date) => _date.format(date);
  static String rangeLabel(DateTime from, DateTime to) =>
      '${_dateTime.format(from)} – ${_dateTime.format(to)}';
}

/// Chart palette derived from [ColorScheme] with semantic report status colors.
abstract final class AnalyticsChartColors {
  static Color primary(ColorScheme s) => s.primary;
  static Color secondary(ColorScheme s) => s.secondary;
  static Color tertiary(ColorScheme s) => s.tertiary;

  static Color pending(ColorScheme s) => s.tertiary;
  static Color resolved(ColorScheme s) => s.primary;
  static Color dismissed(ColorScheme s) => s.outline;

  static Color grid(ColorScheme s) => s.outlineVariant.withValues(alpha: 0.4);
  static Color axisLabel(ColorScheme s) => s.onSurfaceVariant;

  static List<Color> seriesPalette(ColorScheme s) => [
        s.primary,
        s.secondary,
        s.tertiary,
        s.primaryContainer.withValues(alpha: 1),
        s.secondaryContainer.withValues(alpha: 1),
      ];
}

/// Fills missing dates in a daily series with zero counts.
List<(DateTime date, double value)> fillDailyGaps(
  List<DailyCount> series, {
  DateTime? from,
  DateTime? to,
}) {
  if (series.isEmpty) return const [];
  final start = DateTime(
    (from ?? series.first.date).year,
    (from ?? series.first.date).month,
    (from ?? series.first.date).day,
  );
  final end = DateTime(
    (to ?? series.last.date).year,
    (to ?? series.last.date).month,
    (to ?? series.last.date).day,
  );
  final map = {
    for (final p in series)
      DateTime(p.date.year, p.date.month, p.date.day): p.count.toDouble(),
  };
  final out = <(DateTime, double)>[];
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    out.add((d, map[d] ?? 0));
  }
  return out;
}
