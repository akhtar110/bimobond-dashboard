import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/analytics_entities.dart';
import '../utils/analytics_format.dart';
import '../utils/analytics_l10n.dart';
import 'analytics_kpi_card.dart';

class PostTotalsCard extends StatelessWidget {
  const PostTotalsCard({
    super.key,
    required this.posts,
  });

  final AnalyticsPostsEntity posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = AnalyticsFormat.localeOf(context);
    String count(int n) => AnalyticsFormat.count(n, locale: locale);

    return AnalyticsSectionCard(
      title: l10n.t('analyticsPostTotals'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AnalyticsMiniStat(
            label: l10n.t('total'),
            value: count(posts.total),
            icon: Icons.layers_rounded,
          ),
          AnalyticsMiniStat(
            label: AnalyticsL10n.postStatus(context, 'PUBLISHED'),
            value: count(posts.published),
            icon: Icons.check_circle_outline_rounded,
          ),
          AnalyticsMiniStat(
            label: AnalyticsL10n.postStatus(context, 'HIDDEN'),
            value: count(posts.hidden),
            icon: Icons.visibility_off_outlined,
          ),
          AnalyticsMiniStat(
            label: AnalyticsL10n.postStatus(context, 'BANNED'),
            value: count(posts.banned),
            icon: Icons.block_rounded,
          ),
          AnalyticsMiniStat(
            label: AnalyticsL10n.postStatus(context, 'EXPIRED'),
            value: count(posts.expired),
            icon: Icons.hourglass_bottom_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('analyticsAds'),
            value: count(posts.ads),
            icon: Icons.campaign_outlined,
          ),
          AnalyticsMiniStat(
            label: l10n.t('analyticsAuctionable'),
            value: count(posts.auctionable),
            icon: Icons.gavel_rounded,
          ),
          AnalyticsMiniStat(
            label: l10n.t('analyticsNewInPeriod'),
            value: count(posts.inPeriod),
            icon: Icons.fiber_new_rounded,
          ),
        ],
      ),
    );
  }
}
