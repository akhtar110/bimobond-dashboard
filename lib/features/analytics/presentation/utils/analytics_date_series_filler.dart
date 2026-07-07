import '../../domain/entities/analytics_entities.dart';

/// Fills missing dates in sparse daily analytics series with zero counts.
List<DailyCount> fillMissingDates(
  List<DailyCount> source,
  DateTime from,
  DateTime to,
) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  if (end.isBefore(start)) return const [];

  final map = <DateTime, int>{
    for (final point in source)
      DateTime(point.date.year, point.date.month, point.date.day): point.count,
  };

  final filled = <DailyCount>[];
  for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
    filled.add(DailyCount(date: day, count: map[day] ?? 0));
  }
  return filled;
}

/// Uses API period bounds when available, otherwise query-derived range.
List<DailyCount> fillDailySeriesForPeriod({
  required List<DailyCount> source,
  required AnalyticsPeriod? period,
  required AnalyticsQuery query,
}) {
  final from = period?.from ??
      query.from ??
      DateTime.now().subtract(Duration(days: query.days));
  final to = period?.to ?? query.to ?? DateTime.now();
  return fillMissingDates(source, from, to);
}

DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Sums daily points into Monday-based weeks.
List<DailyCount> aggregateWeekly(List<DailyCount> daily) {
  if (daily.isEmpty) return const [];

  final buckets = <DateTime, int>{};
  for (final point in daily) {
    final weekStart = _startOfWeek(point.date);
    buckets[weekStart] = (buckets[weekStart] ?? 0) + point.count;
  }

  return buckets.entries
      .map((e) => DailyCount(date: e.key, count: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

/// Daily for short ranges (≤10 days), weekly otherwise — keeps charts readable.
List<DailyCount> aggregateSeriesForChart(List<DailyCount> daily) {
  if (daily.isEmpty) return const [];
  if (daily.length <= 10) return daily;
  return aggregateWeekly(daily);
}

/// Fills period gaps then aggregates for chart display.
List<DailyCount> chartSeriesForPeriod({
  required List<DailyCount> source,
  required AnalyticsPeriod? period,
  required AnalyticsQuery query,
}) {
  final filled = fillDailySeriesForPeriod(
    source: source,
    period: period,
    query: query,
  );
  return aggregateSeriesForChart(filled);
}

List<(DateTime date, double value)> toChartPoints(List<DailyCount> series) {
  return series.map((p) => (p.date, p.count.toDouble())).toList();
}

/// Fills, aggregates, and returns chart points plus whether labels are weekly.
({List<(DateTime date, double value)> points, bool weekly}) chartPointsForPeriod({
  required List<DailyCount> source,
  required AnalyticsPeriod? period,
  required AnalyticsQuery query,
}) {
  final filled = fillDailySeriesForPeriod(
    source: source,
    period: period,
    query: query,
  );
  final weekly = filled.length > 10;
  final aggregated = aggregateSeriesForChart(filled);
  return (points: toChartPoints(aggregated), weekly: weekly);
}
