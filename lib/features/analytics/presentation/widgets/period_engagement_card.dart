import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/period_engagement_entity.dart';
import '../utils/analytics_format.dart';
import 'analytics_kpi_card.dart';

class PeriodEngagementCard extends StatelessWidget {
  const PeriodEngagementCard({
    super.key,
    required this.engagement,
  });

  final PeriodEngagementEntity engagement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    final title = l10n.t('analyticsPeriodEngagement');

    if (engagement.total == 0) {
      return AnalyticsSectionCard(
        title: title,
        child: Text(
          l10n.t('analyticsNoActivityInPeriod'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return AnalyticsSectionCard(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AnalyticsMiniStat(
            label: l10n.t('views'),
            value: AnalyticsFormat.count(engagement.views, locale: locale),
            icon: Icons.visibility_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('likes'),
            value: AnalyticsFormat.count(engagement.likes, locale: locale),
            icon: Icons.favorite_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('comments'),
            value: AnalyticsFormat.count(engagement.comments, locale: locale),
            icon: Icons.chat_bubble_outline_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('analyticsReposts'),
            value: AnalyticsFormat.count(engagement.reposts, locale: locale),
            icon: Icons.repeat_rounded,
          ),
        ],
      ),
    );
  }
}
