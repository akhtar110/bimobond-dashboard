import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../post_reports/domain/entities/post_report_entities.dart';
import '../../bloc/post_management_bloc.dart';
import '../../utils/post_detail_labels.dart';
import 'investigation_theme.dart';
import 'post_surface_card.dart';

class PostAdvancedAnalyticsSection extends StatelessWidget {
  const PostAdvancedAnalyticsSection({
    super.key,
    this.onViewFullTimeline,
  });

  final VoidCallback? onViewFullTimeline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PostManagementBloc, PostManagementState>(
      buildWhen: (prev, curr) {
        if (curr is! PostManagementLoaded) return false;
        if (prev is! PostManagementLoaded) return true;
        return prev.isAnalyticsLoading != curr.isAnalyticsLoading ||
            prev.analyticsError != curr.analyticsError ||
            prev.analyticsDetail != curr.analyticsDetail;
      },
      builder: (context, state) {
        if (state is! PostManagementLoaded) return const SizedBox.shrink();

        if (state.isAnalyticsLoading && state.analyticsDetail == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.analyticsError != null && state.analyticsDetail == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.analyticsError!, textAlign: TextAlign.center),
                const SizedBox(height: InvestigationTheme.s12),
                FilledButton(
                  onPressed: () => context
                      .read<PostManagementBloc>()
                      .add(LoadPostAdvancedAnalyticsEvent()),
                  child: Text(l10n.t('retry')),
                ),
              ],
            ),
          );
        }

        final detail = state.analyticsDetail;
        if (detail == null) return const SizedBox.shrink();

        final metrics = detail.metrics;
        final summary = detail.moderationSummary;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tOr('advancedAnalytics', 'Advanced Analytics'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: InvestigationTheme.s8),
            Wrap(
              spacing: InvestigationTheme.s8,
              runSpacing: InvestigationTheme.s8,
              children: [
                _RateChip(
                  label: l10n.tOr('engagementRate', 'Engagement Rate'),
                  value: '${metrics.engagementRate.toStringAsFixed(2)}%',
                ),
                _RateChip(
                  label: l10n.tOr('completionRate', 'Completion Rate'),
                  value: '${metrics.completionRate.toStringAsFixed(1)}%',
                ),
                _RateChip(
                  label: l10n.tOr('retentionRate', 'Retention Rate'),
                  value: '${metrics.viewerRetentionRate.toStringAsFixed(1)}%',
                ),
                _RateChip(
                  label: l10n.tOr('watchTime', 'Watch Time'),
                  value: _formatWatchTime(metrics.totalWatchTimeSeconds),
                ),
              ],
            ),
            const SizedBox(height: InvestigationTheme.s16),
            Text(
              l10n.tOr('trafficSources', 'Traffic Sources'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: InvestigationTheme.s8),
            _TrafficBreakdown(breakdown: metrics.trafficSourceBreakdown),
            if (summary != null) ...[
              const SizedBox(height: InvestigationTheme.s16),
              _ModerationSummaryCard(
                summary: summary,
                onViewFullTimeline: onViewFullTimeline,
              ),
            ],
          ],
        );
      },
    );
  }

  static String _formatWatchTime(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrafficBreakdown extends StatelessWidget {
  const _TrafficBreakdown({required this.breakdown});

  final PostReportTrafficSourceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (l10n.tOr('forYou', 'For You'), breakdown.forYou),
      (l10n.tOr('profile', 'Profile'), breakdown.profile),
      (l10n.tOr('search', 'Search'), breakdown.search),
      (l10n.tOr('hashtags', 'Hashtags'), breakdown.hashtags),
      (l10n.tOr('shares', 'Shares'), breakdown.shares),
    ];
    final total = breakdown.total;

    return Column(
      children: items.map((item) {
        final fraction = total > 0 ? item.$2 / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  item.$1,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  '${item.$2}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ModerationSummaryCard extends StatelessWidget {
  const _ModerationSummaryCard({
    required this.summary,
    this.onViewFullTimeline,
  });

  final PostReportModerationSummary summary;
  final VoidCallback? onViewFullTimeline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final moderator = summary.latestModerator;
    final preview = summary.actionTimeline.take(3).toList();

    return PostSurfaceCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tOr('moderationSummary', 'Moderation Summary'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (moderator != null) ...[
            const SizedBox(height: InvestigationTheme.s12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: moderator.avatarUrl != null &&
                          moderator.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(moderator.avatarUrl!)
                      : null,
                  child: moderator.avatarUrl == null ||
                          moderator.avatarUrl!.isEmpty
                      ? Text(
                          moderator.displayName.isNotEmpty
                              ? moderator.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moderator.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@${moderator.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (summary.latestStatusChangeReason != null) ...[
            const SizedBox(height: InvestigationTheme.s8),
            Text(
              l10n.tOr('latestStatusChangeReason', 'Latest status change'),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(summary.latestStatusChangeReason!),
          ],
          if (summary.latestActionDate != null) ...[
            const SizedBox(height: InvestigationTheme.s4),
            Text(
              DateFormat.yMMMd().add_jm().format(summary.latestActionDate!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (preview.isNotEmpty) ...[
            const SizedBox(height: InvestigationTheme.s12),
            ...preview.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
                child: Row(
                  children: [
                    Icon(
                      postStatusIcon(log.status),
                      size: 14,
                      color: postStatusColorFromScheme(scheme, log.status),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        postStatusLabel(l10n, log.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(log.createdAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (onViewFullTimeline != null) ...[
            const SizedBox(height: InvestigationTheme.s8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewFullTimeline,
                child: Text(l10n.tOr('viewFullTimeline', 'View Full Timeline')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
