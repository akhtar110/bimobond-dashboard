import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';

/// Low-height KPI strip — single row, scrolls horizontally when space is tight.
class SoundCompactOverview extends StatelessWidget {
  const SoundCompactOverview({
    super.key,
    required this.sounds,
    required this.usage,
  });

  final SoundStatsEntity sounds;
  final SoundUsageStatsEntity usage;

  static const _stripHeight = 40.0;
  static const _minTileWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat.compact();

    final items = [
      (l10n.t('soundKpiTotal'), number.format(sounds.total), Icons.library_music_outlined),
      (l10n.t('soundKpiActive'), number.format(sounds.active), Icons.check_circle_outline),
      (l10n.t('soundKpiHidden'), number.format(sounds.inactive), Icons.visibility_off_outlined),
      (l10n.t('soundKpiOriginalUploads'), number.format(sounds.originalUploads), Icons.upload_outlined),
      (l10n.t('soundKpiTotalUsage'), number.format(usage.totalUseCount), Icons.equalizer_rounded),
      (l10n.t('soundKpiPosts24h'), number.format(usage.postsWithSoundLast24Hours), Icons.trending_up_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fitsInRow = width >= _minTileWidth * items.length + 8 * (items.length - 1);

        if (fitsInRow) {
          return SizedBox(
            height: _stripHeight,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: PromotionsSpace.sm),
                  Expanded(
                    child: _CompactKpiTile(
                      label: items[i].$1,
                      value: items[i].$2,
                      icon: items[i].$3,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return SizedBox(
          height: _stripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: PromotionsSpace.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: _minTileWidth,
                child: _CompactKpiTile(
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SoundCompactOverviewSkeleton extends StatelessWidget {
  const SoundCompactOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: SoundCompactOverview._stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: PromotionsSpace.sm),
        itemBuilder: (_, __) => Container(
          width: SoundCompactOverview._minTileWidth,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _CompactKpiTile extends StatelessWidget {
  const _CompactKpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                  ),
                  Text(
                    label,
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
    );
  }
}
