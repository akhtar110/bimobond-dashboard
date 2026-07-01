import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/analytics_entities.dart';
import '../utils/analytics_format.dart';
import 'analytics_kpi_card.dart';

class StoriesAnalyticsCard extends StatelessWidget {
  const StoriesAnalyticsCard({
    super.key,
    required this.posts,
  });

  final AnalyticsPostsEntity posts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AnalyticsSectionCard(
      title: l10n.t('analyticsStories'),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              label: l10n.t('analyticsTotalStories'),
              value: AnalyticsFormat.count(
                posts.stories,
                locale: AnalyticsFormat.localeOf(context),
              ),
              icon: Icons.auto_stories_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricTile(
              label: l10n.t('analyticsInPeriodLabel'),
              value: AnalyticsFormat.count(
                posts.storiesInPeriod,
                locale: AnalyticsFormat.localeOf(context),
              ),
              icon: Icons.timelapse_rounded,
              color: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                AnimatedCounterText(
                  text: value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
