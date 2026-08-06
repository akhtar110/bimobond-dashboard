import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../post_reports/domain/entities/post_report_entities.dart';
import '../../../../reports/presentation/utils/report_detail_labels.dart';
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

  static Color _accentFor(String key, ColorScheme scheme) {
    return switch (key) {
      'FOR_YOU' => const Color(0xFF2563EB),
      'FOLLOWING' => const Color(0xFF7C3AED),
      'PROFILE' => const Color(0xFF0891B2),
      'SEARCH' => const Color(0xFFD97706),
      'HASHTAGS' => const Color(0xFF059669),
      'SHARES' => const Color(0xFFDB2777),
      'SOUND' => const Color(0xFF9333EA),
      'LIVE' => const Color(0xFFDC2626),
      'NOTIFICATION' => const Color(0xFFF59E0B),
      'SAVED' => const Color(0xFF0284C7),
      'LIKED' => const Color(0xFFE11D48),
      'REPOST' => const Color(0xFF16A34A),
      'CHAT' => const Color(0xFF0EA5E9),
      'EXPLORE' => const Color(0xFF0D9488),
      'STORY' => const Color(0xFFC026D3),
      'RECOMMENDED' => const Color(0xFF6D28D9),
      'PROMOTION' => const Color(0xFFEA580C),
      'EXTERNAL' => const Color(0xFF475569),
      'OTHER' => scheme.outline,
      _ => scheme.primary,
    };
  }

  static IconData _iconFor(String key) {
    return switch (key) {
      'FOR_YOU' => Icons.home_outlined,
      'FOLLOWING' => Icons.people_outline_rounded,
      'PROFILE' => Icons.person_outline_rounded,
      'SEARCH' => Icons.search_rounded,
      'HASHTAGS' => Icons.tag_rounded,
      'SHARES' => Icons.share_outlined,
      'SOUND' => Icons.music_note_outlined,
      'LIVE' => Icons.videocam_outlined,
      'NOTIFICATION' => Icons.notifications_none_rounded,
      'SAVED' => Icons.bookmark_border_rounded,
      'LIKED' => Icons.favorite_border_rounded,
      'REPOST' => Icons.repeat_rounded,
      'CHAT' => Icons.chat_bubble_outline_rounded,
      'EXPLORE' => Icons.explore_outlined,
      'STORY' => Icons.auto_stories_outlined,
      'RECOMMENDED' => Icons.auto_awesome_outlined,
      'PROMOTION' => Icons.campaign_outlined,
      'EXTERNAL' => Icons.open_in_new_rounded,
      'OTHER' => Icons.more_horiz_rounded,
      _ => Icons.bar_chart_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final entries = breakdown.sortedEntries;
    final total = breakdown.total;

    if (entries.isEmpty) {
      return Text(
        ReportDetailLabels.noTrafficSourceData(l10n),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      children: entries.map((e) {
        final label = ReportDetailLabels.trafficSourceLabel(l10n, e.key);
        final accent = _accentFor(e.key, scheme);
        final icon = _iconFor(e.key);
        final fraction = total > 0 ? e.value / total : 0.0;
        final pct = (fraction * 100).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: accent),
              ),
              const SizedBox(width: InvestigationTheme.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${e.value}',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                        backgroundColor: accent.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
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
