import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/analytics_entities.dart';
import 'analytics_date_series_filler.dart';

abstract final class AnalyticsFormat {
  static NumberFormat _compact([String? locale]) =>
      NumberFormat.compact(locale: locale ?? 'en');

  static NumberFormat _currency([String? locale]) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: locale);

  static NumberFormat _currencyPrecise([String? locale]) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2, locale: locale);

  static String count(num value, {String? locale}) =>
      _compact(locale).format(value);

  static String usd(num value, {String? locale}) {
    final cur = value >= 1000 ? _currency(locale) : _currencyPrecise(locale);
    return cur.format(value);
  }

  static String shortDate(DateTime date, {String? locale}) =>
      DateFormat.MMMd(locale ?? 'en').format(date);

  /// Label for a weekly bucket (week start date).
  static String weekLabel(DateTime weekStart, {String? locale}) {
    final code = locale ?? 'en';
    final end = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat.MMMd(code);
    return '${fmt.format(weekStart)} – ${fmt.format(end)}';
  }

  static String chartBucketLabel(
    DateTime date, {
    required bool weekly,
    String? locale,
  }) {
    if (weekly) return weekLabel(date, locale: locale);
    return shortDate(date, locale: locale);
  }

  static String rangeLabel(DateTime from, DateTime to, {String? locale}) {
    final fmt = DateFormat.yMMMd(locale ?? 'en');
    return '${fmt.format(from)} – ${fmt.format(to)}';
  }

  static String localeOf(BuildContext context) =>
      Localizations.localeOf(context).toString();
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
  final filled = fillMissingDates(series, start, end);
  final aggregated = aggregateSeriesForChart(filled);
  return toChartPoints(aggregated);
}
