import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/auctions_bloc.dart';

/// Toolbar date-range control for auctions (matches posts calendar button).
class AuctionsDateFilterButton extends StatelessWidget {
  const AuctionsDateFilterButton({super.key, required this.height});

  final double height;

  static const _customRangeKey = Object();

  String _label(AppLocalizations l10n, DateTimeRange? range) {
    if (range == null) return l10n.t('dateRange');
    return l10n.t('customRange');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<AuctionsBloc, AuctionsState, DateTimeRange?>(
      selector: (state) => switch (state) {
        AuctionsLoaded(:final dateRange) => dateRange,
        _ => context.read<AuctionsBloc>().activeDateRange,
      },
      builder: (context, dateRange) {
        final isActive = dateRange != null;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);
        final tooltip = isActive
            ? _label(l10n, dateRange)
            : l10n.t('dateRange');

        return Tooltip(
          message: tooltip,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<Object>(
              tooltip: tooltip,
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (item) async {
                if (item == _customRangeKey) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: dateRange,
                  );
                  if (picked != null && context.mounted) {
                    context.read<AuctionsBloc>().add(
                          UpdateAuctionDateRangeEvent(picked),
                        );
                  }
                  return;
                }
                _applyPreset(context, item as String);
              },
              itemBuilder: (context) => [
                _presetItem(context, 'all', l10n.t('filterAll'), dateRange),
                _presetItem(context, 'today', l10n.t('dateToday'), dateRange),
                _presetItem(context, '7d', l10n.t('last7Days'), dateRange),
                _presetItem(context, '30d', l10n.t('last30Days'), dateRange),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _customRangeKey,
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(l10n.t('customRange')),
                    ],
                  ),
                ),
              ],
              child: Container(
                height: height,
                width: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.date_range_outlined, size: 17, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<Object> _presetItem(
    BuildContext context,
    String value,
    String label,
    DateTimeRange? active,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _presetMatches(value, active);
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        children: [
          if (selected)
            Icon(Icons.check_rounded, size: 16, color: scheme.primary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? scheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _presetMatches(String preset, DateTimeRange? active) {
    if (preset == 'all') return active == null;
    if (active == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expected = switch (preset) {
      'today' => DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        ),
      '7d' => DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        ),
      '30d' => DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1)),
        ),
      _ => null,
    };
    if (expected == null) return false;
    return active.start == expected.start && active.end == expected.end;
  }

  void _applyPreset(BuildContext context, String preset) {
    final bloc = context.read<AuctionsBloc>();
    if (preset == 'all') {
      bloc.add(UpdateAuctionDateRangeEvent(null));
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (preset) {
      'today' => DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        ),
      '7d' => DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        ),
      '30d' => DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1)),
        ),
      _ => null,
    };
    if (range != null) {
      bloc.add(UpdateAuctionDateRangeEvent(range));
    }
  }
}
