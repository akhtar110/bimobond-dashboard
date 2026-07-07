import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../services/sound_preview_service.dart';
import 'sound_preview_widgets.dart';

class SoundTopTrendingSection extends StatelessWidget {
  const SoundTopTrendingSection({
    super.key,
    required this.sounds,
    required this.preview,
  });

  final List<SoundEntity> sounds;
  final SoundPreviewService preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = NumberFormat.compact();
    final top = sounds.take(5).toList();

    if (top.isEmpty) {
      return DashboardCard(
        padding: const EdgeInsets.all(PromotionsSpace.xl),
        child: Center(
          child: Text(
            l10n.t('soundNoTrending'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return DashboardCard(
      padding: const EdgeInsets.symmetric(
        horizontal: PromotionsSpace.md,
        vertical: PromotionsSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 48,
              columnSpacing: 20,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
              columns: [
                DataColumn(label: Text(l10n.t('soundRank'))),
                DataColumn(label: Text(l10n.t('soundName'))),
                DataColumn(label: Text(l10n.t('soundAuthor'))),
                DataColumn(label: Text(l10n.t('soundUsageCount'))),
                DataColumn(label: Text(l10n.t('soundColVisible'))),
                DataColumn(label: Text(l10n.t('soundPreview'))),
              ],
              rows: [
                for (var i = 0; i < top.length; i++)
                  DataRow(
                    cells: [
                      DataCell(Text('#${i + 1}', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            top[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(Text(top[i].author, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(compact.format(top[i].useCount), style: const TextStyle(fontSize: 12))),
                      DataCell(SoundStatusBadge(isActive: top[i].isActive)),
                      DataCell(
                        SoundPreviewButton(
                          soundId: top[i].id,
                          audioUrl: top[i].audioUrl,
                          preview: preview,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
