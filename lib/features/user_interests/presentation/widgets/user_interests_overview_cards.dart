import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/user_interest_entities.dart';
import '../utils/user_interests_responsive.dart';

class UserInterestsOverviewCards extends StatelessWidget {
  const UserInterestsOverviewCards({
    super.key,
    required this.meta,
    this.metrics,
  });

  final UserInterestsMetaEntity meta;
  final UserInterestsLayoutMetrics? metrics;

  static const _stripHeight = 44.0;
  static const _defaultMaxTileWidth = 148.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <_KpiItem>[
      _KpiItem(
        label: l10n.tOr('userInterestTotalInterests', 'Total Interests'),
        value: '${meta.totalInterests}',
        icon: Icons.favorite_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('userInterestTotalNotInterests', 'Total Not Interests'),
        value: '${meta.totalNotInterests}',
        icon: Icons.heart_broken_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('userInterestMinRequired', 'Minimum Required'),
        value: '${meta.minRequired}',
        icon: Icons.rule_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('userInterestMaxAllowed', 'Maximum Allowed'),
        value: '${meta.maxAllowed}',
        icon: Icons.north_rounded,
      ),
      _KpiItem(
        label: l10n.tOr(
          'userInterestMaxNotInterested',
          'Maximum Not Interested',
        ),
        value: '${meta.maxNotInterestsAllowed}',
        icon: Icons.south_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = metrics?.cardGap ?? PromotionsSpace.sm;
        final useWrap = constraints.maxWidth < 720;

        if (useWrap) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                _CompactKpiTile(item: item, maxWidth: _defaultMaxTileWidth),
            ],
          );
        }

        return SizedBox(
          height: _stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _CompactKpiTile(
                    item: items[i],
                    maxWidth: _defaultMaxTileWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _CompactKpiTile extends StatelessWidget {
  const _CompactKpiTile({
    required this.item,
    required this.maxWidth,
  });

  final _KpiItem item;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: item.label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 96, maxWidth: maxWidth),
        child: Container(
          height: UserInterestsOverviewCards._stripHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                    ),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
