import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';

/// Compact KPI chips — width follows label/value content.
class SoundCompactOverview extends StatelessWidget {
  const SoundCompactOverview({
    super.key,
    required this.sounds,
    required this.usage,
    required this.segments,
  });

  final SoundStatsEntity sounds;
  final SoundUsageStatsEntity usage;
  final SoundSegmentStatsEntity segments;

  static const _stripHeight = 38.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat.compact();

    final items = [
      (l10n.t('soundKpiTotal'), number.format(sounds.total), Icons.library_music_outlined),
      (l10n.t('soundKpiActive'), number.format(sounds.active), Icons.check_circle_outline),
      (l10n.t('soundKpiHidden'), number.format(sounds.inactive), Icons.visibility_off_outlined),
      (l10n.t('soundKpiOriginalUploads'), number.format(sounds.originalUploads), Icons.upload_outlined),
      (l10n.tOr('soundKpiSegments', 'Segments'), number.format(segments.total), Icons.graphic_eq_outlined),
      (l10n.t('soundKpiTotalUsage'), number.format(usage.totalUseCount), Icons.equalizer_rounded),
      (l10n.t('soundKpiPosts24h'), number.format(usage.postsWithSoundLast24Hours), Icons.trending_up_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PromotionsSpace.sm;
        final useWrap = constraints.maxWidth < 720;

        final tiles = [
          for (final item in items)
            _CompactKpiTile(
              label: item.$1,
              value: item.$2,
              icon: item.$3,
            ),
        ];

        if (useWrap) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: tiles,
          );
        }

        return SizedBox(
          height: _stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  tiles[i],
                ],
              ],
            ),
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
    const widths = [72.0, 68.0, 78.0, 84.0, 76.0, 72.0, 64.0];

    return SizedBox(
      height: SoundCompactOverview._stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: PromotionsSpace.sm),
              Container(
                width: widths[i],
                height: SoundCompactOverview._stripHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
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
      message: '$value · $label',
      child: Container(
        constraints: const BoxConstraints(
          minHeight: SoundCompactOverview._stripHeight,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
