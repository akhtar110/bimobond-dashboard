import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/analytics_entities.dart';
import '../bloc/analytics_bloc.dart';
import '../utils/analytics_date_series_filler.dart';
import '../utils/analytics_format.dart';
import '../../../../core/utils/coin_format.dart';
import '../utils/analytics_l10n.dart';
import 'analytics_charts.dart';
import 'analytics_dashboard_header.dart';
import 'analytics_grid.dart';
import 'analytics_kpi_card.dart';
import 'analytics_loading_skeleton.dart';
import 'period_engagement_card.dart';
import 'post_totals_card.dart';
import 'posts_analytics_charts_section.dart';
import 'stories_analytics_card.dart';

double _analyticsGridWidth(BoxConstraints constraints, BuildContext context) {
  final maxW = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : MediaQuery.sizeOf(context).width;
  return (maxW.clamp(0.0, 1680.0) - 32).clamp(200.0, double.infinity);
}

class AnalyticsDashboardBody extends StatelessWidget {
  const AnalyticsDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsError && state.message.isNotEmpty) {
          return Center(child: _FullError(message: state.message));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = _analyticsGridWidth(constraints, context);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1680),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: switch (state) {
                                AnalyticsInitial() =>
                                  const AnalyticsDashboardSkeleton(),
                                AnalyticsLoading(:final previous)
                                    when previous == null =>
                                  const AnalyticsDashboardSkeleton(),
                                AnalyticsLoaded s => _DashboardSections(
                                    state: s,
                                    width: width,
                                  ),
                                AnalyticsLoading(:final previous)
                                    when previous != null =>
                                  _DashboardSections(
                                    state: previous,
                                    width: width,
                                    isRefreshing: true,
                                  ),
                                _ => const Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardSections extends StatelessWidget {
  const _DashboardSections({
    required this.state,
    required this.width,
    this.isRefreshing = false,
  });

  final AnalyticsLoaded state;
  final double width;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    if (!state.isAdminDashboard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsDashboardHeader(
            isRefreshing: isRefreshing || state.isRefreshing,
          ),
          const SizedBox(height: 24),
          AnalyticsSectionCard(
            title: context.l10n.t('analyticsCreatorTitle'),
            child: Text(
              context.l10n.t('analyticsCreatorBody'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsDashboardHeader(
          isRefreshing: isRefreshing || state.isRefreshing,
        ),
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: _kpiRow(state, context),
        ),
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: [
            AnalyticsGridItem(
              desktopSpan: 6,
              tabletSpan: 6,
              child: _GrowthSection(state: state),
            ),
            AnalyticsGridItem(
              desktopSpan: 6,
              tabletSpan: 6,
              child: _DailyNewPostsSection(state: state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: [
            AnalyticsGridItem(
              desktopSpan: 12,
              tabletSpan: 6,
              child: PostsAnalyticsChartsSection(state: state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: [
            if (state.posts != null)
              AnalyticsGridItem(
                desktopSpan: 6,
                tabletSpan: 6,
                child: PostTotalsCard(posts: state.posts!),
              ),
            if (state.posts != null)
              AnalyticsGridItem(
                desktopSpan: 6,
                tabletSpan: 6,
                child: StoriesAnalyticsCard(posts: state.posts!),
              ),
          ],
        ),
        if (state.posts != null) ...[
          const SizedBox(height: 16),
          AnalyticsGrid(
            width: width,
            children: [
              AnalyticsGridItem(
                desktopSpan: 12,
                tabletSpan: 6,
                child: PeriodEngagementCard(
                  engagement: state.posts!.periodEngagement,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: [
            AnalyticsGridItem(
              desktopSpan: 4,
              tabletSpan: 6,
              child: _EngagementSection(state: state),
            ),
            if (state.showMonetization)
              AnalyticsGridItem(
                desktopSpan: 4,
                tabletSpan: 6,
                child: _MonetizationSection(state: state),
              ),
            AnalyticsGridItem(
              desktopSpan: 4,
              tabletSpan: 6,
              child: _UserGrowthSection(state: state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalyticsGrid(
          width: width,
          children: [
            AnalyticsGridItem(
              desktopSpan: 4,
              tabletSpan: 6,
              child: _ReportsSection(state: state),
            ),
            AnalyticsGridItem(
              desktopSpan: 4,
              tabletSpan: 6,
              child: _AuctionsSection(state: state),
            ),
            AnalyticsGridItem(
              desktopSpan: 4,
              tabletSpan: 6,
              child: _UsersSection(state: state),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CategoriesSection(state: state),
        const SizedBox(height: 24),
      ],
    );
  }

  List<AnalyticsGridItem> _kpiRow(AnalyticsLoaded state, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    String usd(num n) => AnalyticsFormat.usd(n, locale: locale);
    String coins(num n) => CoinFormat.coins(n, locale: locale);
    final o = state.overview;
    final m = state.monetization;
    final e = state.engagement;

    final kpis = <AnalyticsGridItem>[
      AnalyticsGridItem(
        desktopSpan: 3,
        tabletSpan: 3,
        child: AnalyticsKpiCard(
          title: l10n.t('users'),
          icon: Icons.people_alt_rounded,
          accent: scheme.primary,
          value: count(o?.usersTotal ?? state.users?.total ?? 0),
          subtitle: l10n.tArgs('analyticsInPeriod', {
            'count': count(o?.usersNewInPeriod ?? state.users?.newInPeriod ?? 0),
          }),
        ),
      ),
      AnalyticsGridItem(
        desktopSpan: 3,
        tabletSpan: 3,
        child: AnalyticsKpiCard(
          title: l10n.t('posts'),
          icon: Icons.article_rounded,
          accent: scheme.secondary,
          value: count(o?.postsTotal ?? state.posts?.total ?? 0),
          subtitle: l10n.tArgs('analyticsInPeriod', {
            'count': count(o?.postsNewInPeriod ?? state.posts?.inPeriod ?? 0),
          }),
        ),
      ),
      AnalyticsGridItem(
        desktopSpan: 3,
        tabletSpan: 3,
        child: AnalyticsKpiCard(
          title: l10n.t('analyticsEngagementSection'),
          icon: Icons.favorite_rounded,
          accent: scheme.tertiary,
          value: count(
            state.posts?.periodEngagement.views ??
                o?.totalViews ??
                e?.views ??
                0,
          ),
          subtitle: l10n.tArgs('analyticsLikesComments', {
            'likes': count(
              state.posts?.periodEngagement.likes ??
                  o?.totalLikes ??
                  e?.likes ??
                  0,
            ),
            'comments': count(
              state.posts?.periodEngagement.comments ??
                  o?.totalComments ??
                  e?.comments ??
                  0,
            ),
          }),
        ),
      ),
    ];

    if (state.showMonetization) {
      kpis.add(
        AnalyticsGridItem(
          desktopSpan: 3,
          tabletSpan: 3,
          child: AnalyticsKpiCard(
            title: l10n.t('analyticsMonetizationSection'),
            icon: Icons.payments_rounded,
            accent: scheme.primary,
            value: coins(m?.totalBalanceCoins ?? o?.walletBalances ?? 0),
            subtitle: l10n.tArgs('analyticsGiftRevenueSubtitle', {
              'giftRevenue': coins(m?.giftGrossCoins ?? 0),
              'giftCount': count(m?.giftTransactionCount ?? o?.giftsInPeriod ?? 0),
            }),
          ),
        ),
      );
    }

    return kpis;
  }
}

class _FullError extends StatelessWidget {
  const _FullError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 56, color: scheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context
                  .read<AnalyticsBloc>()
                  .add(const LoadAnalyticsDashboardEvent()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthSection extends StatelessWidget {
  const _GrowthSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final growth = state.growth;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final growthSeries = growth == null
        ? null
        : chartPointsForPeriod(
            source: growth.newUsers,
            period: growth.period,
            query: state.query,
          );
    return AnalyticsSectionCard(
      title: l10n.t('analyticsPlatformGrowth'),
      subtitle: growthSeries?.weekly == true
          ? l10n.t('analyticsPlatformGrowthSubtitleWeekly')
          : l10n.t('analyticsPlatformGrowthSubtitle'),
      error: state.errorFor('growth'),
      onRetry: () => bloc.add(const LoadGrowthAnalyticsEvent()),
      child: growth == null
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : AnalyticsMultiLineChart(
              weeklyLabels: growthSeries?.weekly ?? false,
              series: [
                AnalyticsLineSeries(
                  label: l10n.t('analyticsNewUsers'),
                  color: scheme.primary,
                  points: _chartPoints(
                    growth.newUsers,
                    growth.period,
                    state.query,
                  ),
                ),
                AnalyticsLineSeries(
                  label: l10n.t('analyticsNewPosts'),
                  color: scheme.secondary,
                  points: _chartPoints(
                    growth.newPosts,
                    growth.period,
                    state.query,
                  ),
                ),
                AnalyticsLineSeries(
                  label: l10n.t('analyticsGiftTransactions'),
                  color: scheme.tertiary,
                  points: _chartPoints(
                    growth.giftTransactions,
                    growth.period,
                    state.query,
                  ),
                ),
              ],
            ),
    );
  }
}

class _UserGrowthSection extends StatelessWidget {
  const _UserGrowthSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final users = state.users;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final userSeries = users == null
        ? null
        : chartPointsForPeriod(
            source: users.dailyNewUsers,
            period: users.period,
            query: state.query,
          );
    return AnalyticsSectionCard(
      title: l10n.t('analyticsUserGrowth'),
      subtitle: userSeries?.weekly == true
          ? l10n.t('analyticsUserGrowthSubtitleWeekly')
          : l10n.t('analyticsUserGrowthSubtitle'),
      error: state.errorFor('users'),
      onRetry: () => bloc.add(const LoadUsersAnalyticsEvent()),
      child: users == null
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : AnalyticsMultiLineChart(
              weeklyLabels: userSeries?.weekly ?? false,
              series: [
                AnalyticsLineSeries(
                  label: l10n.t('analyticsNewUsers'),
                  color: scheme.primary,
                  points: _chartPoints(
                    users.dailyNewUsers,
                    users.period,
                    state.query,
                  ),
                ),
              ],
            ),
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final users = state.users;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    return AnalyticsSectionCard(
      title: l10n.t('analyticsUsersSection'),
      error: state.errorFor('users'),
      onRetry: () => bloc.add(const LoadUsersAnalyticsEvent()),
      child: users == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('totalUsers'),
                      value: count(users.total),
                      icon: Icons.groups_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('verified'),
                      value: count(users.verified),
                      icon: Icons.verified_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('banned'),
                      value: count(users.banned),
                      icon: Icons.block_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsPieChart(
                  entries: [
                    for (final e in users.roleCounts.entries)
                      AnalyticsPieEntry(
                        label: AnalyticsL10n.roleLabel(context, e.key),
                        value: e.value.toDouble(),
                        color: _roleColor(scheme, e.key),
                      ),
                  ],
                  donut: true,
                ),
              ],
            ),
    );
  }

  Color _roleColor(ColorScheme scheme, String role) => switch (role) {
        'ADMIN' => scheme.error,
        'MODERATOR' => scheme.tertiary,
        _ => scheme.primary,
      };
}

class _DailyNewPostsSection extends StatelessWidget {
  const _DailyNewPostsSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final posts = state.posts;
    final bloc = context.read<AnalyticsBloc>();
    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);

    final series = posts == null
        ? null
        : chartPointsForPeriod(
            source: posts.dailyNewPosts,
            period: posts.period,
            query: state.query,
          );

    return AnalyticsSectionCard(
      title: l10n.t('analyticsNewPostsOverTime'),
      subtitle: series?.weekly == true
          ? l10n.t('analyticsNewPostsOverTimeSubtitle')
          : l10n.t('analyticsPlatformGrowthSubtitle'),
      error: state.errorFor('posts'),
      onRetry: () => bloc.add(const LoadPostsAnalyticsEvent()),
      child: posts == null || series == null
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : AnalyticsBarChart(
              height: 240,
              weeklyLabels: series.weekly,
              entries: [
                for (final point in series.points)
                  AnalyticsBarEntry(
                    label: AnalyticsFormat.chartBucketLabel(
                      point.$1,
                      weekly: series.weekly,
                      locale: locale,
                    ),
                    value: point.$2,
                    color: scheme.secondary,
                  ),
              ],
            ),
    );
  }
}

List<(DateTime date, double value)> _chartPoints(
  List<DailyCount> source,
  AnalyticsPeriod period,
  AnalyticsQuery query,
) {
  return chartPointsForPeriod(
    source: source,
    period: period,
    query: query,
  ).points;
}

class _EngagementSection extends StatelessWidget {
  const _EngagementSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final engagement = state.engagement;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    return AnalyticsSectionCard(
      title: l10n.t('analyticsEngagementSection'),
      subtitle: l10n.t('analyticsEngagementSubtitle'),
      error: state.errorFor('engagement'),
      onRetry: () => bloc.add(const LoadEngagementAnalyticsEvent()),
      child: engagement == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('views'),
                      value: count(engagement.views),
                      icon: Icons.visibility_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('likes'),
                      value: count(engagement.likes),
                      icon: Icons.favorite_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('comments'),
                      value: count(engagement.comments),
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('saves'),
                      value: count(engagement.saves),
                      icon: Icons.bookmark_outline_rounded,
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsReposts'),
                      value: count(engagement.reposts),
                      icon: Icons.repeat_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsBarChart(
                  height: 180,
                  entries: [
                    AnalyticsBarEntry(
                      label: l10n.t('views'),
                      value: engagement.views.toDouble(),
                      color: scheme.primary,
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('likes'),
                      value: engagement.likes.toDouble(),
                      color: scheme.secondary,
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('comments'),
                      value: engagement.comments.toDouble(),
                      color: scheme.tertiary,
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('saves'),
                      value: engagement.saves.toDouble(),
                      color: scheme.primaryContainer,
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('analyticsReposts'),
                      value: engagement.reposts.toDouble(),
                      color: scheme.secondaryContainer,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MonetizationSection extends StatelessWidget {
  const _MonetizationSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = state.monetization;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    String volume(num n) => CoinFormat.purchaseVolume(n, locale: locale);
    String coins(num n) => CoinFormat.coins(n, locale: locale);
    return AnalyticsSectionCard(
      title: l10n.t('analyticsMonetizationSection'),
      error: state.errorFor('monetization'),
      onRetry: () => bloc.add(const LoadMonetizationAnalyticsEvent()),
      child: m == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsGiftRevenue'),
                      value: coins(m.giftGrossCoins),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsFiatPurchases'),
                      value: volume(m.completedPurchaseVolume),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsWalletBalance'),
                      value: coins(m.totalBalanceCoins),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsPendingWithdrawals'),
                      value: count(m.pendingWithdrawals),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsPieChart(
                  size: 160,
                  entries: [
                    AnalyticsPieEntry(
                      label: l10n.t('gifts'),
                      value: m.giftGrossCoins,
                      color: scheme.primary,
                    ),
                    AnalyticsPieEntry(
                      label: l10n.t('analyticsFiat'),
                      value: m.completedPurchaseVolume,
                      color: scheme.secondary,
                    ),
                    AnalyticsPieEntry(
                      label: l10n.t('analyticsWallet'),
                      value: m.totalBalanceCoins,
                      color: scheme.tertiary,
                    ),
                  ],
                ),
                if (m.accountingByType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('analyticsAccountingBreakdown'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AnalyticsBarChart(
                    height: 160,
                    entries: [
                      for (var i = 0; i < m.accountingByType.length; i++)
                        AnalyticsBarEntry(
                          label: m.accountingByType.keys.elementAt(i),
                          value: m.accountingByType.values.elementAt(i),
                          color: scheme.primary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reports = state.reports;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    return AnalyticsSectionCard(
      title: l10n.t('analyticsReportsOverview'),
      error: state.errorFor('reports'),
      onRetry: () => bloc.add(const RefreshAnalyticsEvent()),
      child: reports == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('total'),
                      value: count(reports.total),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsPending'),
                      value: count(reports.byStatus['PENDING'] ?? 0),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsResolved'),
                      value: count(reports.byStatus['RESOLVED'] ?? 0),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsDismissed'),
                      value: count(reports.byStatus['DISMISSED'] ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsBarChart(
                  height: 160,
                  entries: [
                    AnalyticsBarEntry(
                      label: l10n.t('analyticsPending'),
                      value: (reports.byStatus['PENDING'] ?? 0).toDouble(),
                      color: AnalyticsChartColors.pending(scheme),
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('analyticsResolved'),
                      value: (reports.byStatus['RESOLVED'] ?? 0).toDouble(),
                      color: AnalyticsChartColors.resolved(scheme),
                    ),
                    AnalyticsBarEntry(
                      label: l10n.t('analyticsDismissed'),
                      value: (reports.byStatus['DISMISSED'] ?? 0).toDouble(),
                      color: AnalyticsChartColors.dismissed(scheme),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _AuctionsSection extends StatelessWidget {
  const _AuctionsSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auctions = state.auctions;
    final bloc = context.read<AnalyticsBloc>();

    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(num n) => AnalyticsFormat.count(n, locale: locale);
    String coins(num n) => CoinFormat.coins(n, locale: locale);
    return AnalyticsSectionCard(
      title: l10n.t('analyticsAuctionsOverview'),
      error: state.errorFor('auctions'),
      onRetry: () => bloc.add(const RefreshAnalyticsEvent()),
      child: auctions == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('total'),
                      value: count(auctions.total),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('active'),
                      value: count(auctions.byStatus['ACTIVE'] ?? 0),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('completed'),
                      value: count(auctions.byStatus['COMPLETED'] ?? 0),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('cancelled'),
                      value: count(auctions.byStatus['CANCELLED'] ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsTargetVolume'),
                      value: coins(auctions.targetVolume),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsRaisedVolume'),
                      value: coins(auctions.raisedVolume),
                    ),
                    AnalyticsMiniStat(
                      label: l10n.t('analyticsAvgRaised'),
                      value: coins(auctions.avgRaised),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsBarChart(
                  height: 140,
                  entries: [
                    for (final e in auctions.byStatus.entries)
                      AnalyticsBarEntry(
                        label: e.key,
                        value: e.value.toDouble(),
                        color: scheme.primary,
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.state});
  final AnalyticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = state.categories;
    final bloc = context.read<AnalyticsBloc>();
    final top = categories?.postsByCategory.take(8).toList() ?? [];

    final l10n = context.l10n;
    return AnalyticsSectionCard(
      title: l10n.t('analyticsCategoryDistribution'),
      subtitle: l10n.t('analyticsCategoryDistributionSubtitle'),
      error: state.errorFor('categories'),
      onRetry: () => bloc.add(const RefreshAnalyticsEvent()),
      child: categories == null
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : top.isEmpty
              ? Center(
                  child: Text(
                    l10n.t('analyticsNoCategoryData'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : Column(
                  children: [
                    for (final cat in top) ...[
                      _CategoryBar(
                        name: cat.name,
                        count: cat.count,
                        max: top.first.count,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.name,
    required this.count,
    required this.max,
    required this.color,
  });

  final String name;
  final int count;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = max <= 0 ? 0.0 : count / max;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            name,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AnalyticsFormat.count(
            count,
            locale: AnalyticsFormat.localeOf(context),
          ),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
