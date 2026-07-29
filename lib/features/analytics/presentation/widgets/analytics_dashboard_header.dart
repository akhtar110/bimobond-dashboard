import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/analytics_bloc.dart';
import '../utils/analytics_responsive.dart';

/// Compact analytics top bar — title + date/refresh, no border or subtitle.
class AnalyticsDashboardHeader extends StatelessWidget {
  const AnalyticsDashboardHeader({
    this.isRefreshing = false,
    this.metrics,
    super.key,
  });

  final bool isRefreshing;
  final AnalyticsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = metrics ??
            AnalyticsLayoutMetrics(
              getAnalyticsDeviceType(constraints.maxWidth),
            );
        final compact = m.isCompact || constraints.maxWidth < 720;
        final stackControls = constraints.maxWidth < 560;

        final titleStyle =
            (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
              color: scheme.onSurface,
              height: 1.05,
            );

        final title = Text(
          l10n.t('analytics'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        );

        final controls = _HeaderControls(
          isRefreshing: isRefreshing,
          compact: compact,
          gap: m.controlGap,
        );

        if (stackControls) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                SizedBox(height: m.headerGap),
                controls,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              SizedBox(width: m.controlGap),
              controls,
            ],
          ),
        );
      },
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({
    required this.isRefreshing,
    required this.compact,
    required this.gap,
  });

  final bool isRefreshing;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<AnalyticsBloc>();
    final state = bloc.state;
    final preset =
        state is AnalyticsLoaded ? state.preset : AnalyticsDatePreset.last30Days;
    final controlSize = compact ? 36.0 : 40.0;

    final refreshBtn = Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isRefreshing
            ? null
            : () => bloc.add(const RefreshAnalyticsEvent()),
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: controlSize,
          height: controlSize,
          child: Center(
            child: isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: compact ? 18 : 20,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DateRangeSelector(current: preset),
        refreshBtn,
      ],
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({required this.current});

  final AnalyticsDatePreset current;

  String _label(AnalyticsDatePreset p, AppLocalizations l10n) => switch (p) {
        AnalyticsDatePreset.last7Days => l10n.t('analyticsLast7Days'),
        AnalyticsDatePreset.last30Days => l10n.t('analyticsLast30Days'),
        AnalyticsDatePreset.last90Days => l10n.t('analyticsLast90Days'),
        AnalyticsDatePreset.custom => l10n.t('analyticsCustomRange'),
      };

  Future<void> _onSelected(
    BuildContext context,
    AnalyticsDatePreset preset,
  ) async {
    if (preset == AnalyticsDatePreset.custom) {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
      );
      if (!context.mounted || range == null) return;
      context.read<AnalyticsBloc>().add(
            ChangeAnalyticsDateRangeEvent(
              preset: AnalyticsDatePreset.custom,
              customFrom: range.start,
              customTo: range.end,
            ),
          );
      return;
    }
    context.read<AnalyticsBloc>().add(
          ChangeAnalyticsDateRangeEvent(preset: preset),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopupMenuButton<AnalyticsDatePreset>(
      tooltip: l10n.t('analyticsDateRange'),
      onSelected: (preset) => _onSelected(context, preset),
      itemBuilder: (_) => [
        for (final p in AnalyticsDatePreset.values)
          PopupMenuItem(value: p, child: Text(_label(p, l10n))),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.date_range_rounded, size: 16),
        label: Text(_label(current, l10n)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
