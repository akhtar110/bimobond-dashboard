part of 'analytics_bloc.dart';

enum AnalyticsDatePreset { last7Days, last30Days, last90Days, custom }

enum AnalyticsDashboardMode { admin, creator }

enum AnalyticsAccessLevel { admin, moderator, creator }

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

final class LoadAnalyticsDashboardEvent extends AnalyticsEvent {
  const LoadAnalyticsDashboardEvent({
    this.mode = AnalyticsDashboardMode.admin,
    this.accessLevel = AnalyticsAccessLevel.admin,
  });

  final AnalyticsDashboardMode mode;
  final AnalyticsAccessLevel accessLevel;

  @override
  List<Object?> get props => [mode, accessLevel];
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

final class LoadEngagementAnalyticsEvent extends AnalyticsEvent {
  const LoadEngagementAnalyticsEvent();
}

final class LoadMonetizationAnalyticsEvent extends AnalyticsEvent {
  const LoadMonetizationAnalyticsEvent();
}

final class RefreshAnalyticsEvent extends AnalyticsEvent {
  const RefreshAnalyticsEvent();
}

/// Documented alias — use [RefreshAnalyticsEvent].
typedef RefreshAnalyticsDashboardEvent = RefreshAnalyticsEvent;

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
