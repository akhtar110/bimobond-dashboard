part of 'analytics_bloc.dart';

enum AnalyticsDatePreset { last7Days, last30Days, last90Days, custom }

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

final class LoadAnalyticsDashboardEvent extends AnalyticsEvent {
  const LoadAnalyticsDashboardEvent();
}

final class LoadOverviewEvent extends AnalyticsEvent {
  const LoadOverviewEvent();
}

final class LoadUsersAnalyticsEvent extends AnalyticsEvent {
  const LoadUsersAnalyticsEvent();
}

final class LoadPostsAnalyticsEvent extends AnalyticsEvent {
  const LoadPostsAnalyticsEvent();
}

final class LoadGrowthAnalyticsEvent extends AnalyticsEvent {
  const LoadGrowthAnalyticsEvent();
}

final class LoadMonetizationAnalyticsEvent extends AnalyticsEvent {
  const LoadMonetizationAnalyticsEvent();
}

final class RefreshAnalyticsEvent extends AnalyticsEvent {
  const RefreshAnalyticsEvent();
}

final class ChangeAnalyticsDateRangeEvent extends AnalyticsEvent {
  const ChangeAnalyticsDateRangeEvent({
    required this.preset,
    this.customFrom,
    this.customTo,
  });

  final AnalyticsDatePreset preset;
  final DateTime? customFrom;
  final DateTime? customTo;

  @override
  List<Object?> get props => [preset, customFrom, customTo];
}
