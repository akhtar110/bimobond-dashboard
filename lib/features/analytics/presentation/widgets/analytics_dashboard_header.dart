import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/analytics_bloc.dart';

class AnalyticsDashboardHeader extends StatelessWidget {
  const AnalyticsDashboardHeader({this.isRefreshing = false, super.key});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 720;
          final controls = _HeaderControls(isRefreshing: isRefreshing);

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderTitles(theme: theme, scheme: scheme),
                const SizedBox(height: 14),
                controls,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _HeaderTitles(theme: theme, scheme: scheme)),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderTitles extends StatelessWidget {
  const _HeaderTitles({required this.theme, required this.scheme});
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('analytics'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('analyticsSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({required this.isRefreshing});
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final bloc = context.read<AnalyticsBloc>();
    final state = bloc.state;
    final preset =
        state is AnalyticsLoaded ? state.preset : AnalyticsDatePreset.last30Days;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DateRangeSelector(current: preset),
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          child: IconButton(
            tooltip: l10n.t('refresh'),
            onPressed: isRefreshing
                ? null
                : () => bloc.add(const RefreshAnalyticsEvent()),
            icon: isRefreshing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: scheme.onSurfaceVariant),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.t('analyticsExportComingSoon')),
                behavior: SnackBarBehavior.floating,
                backgroundColor: scheme.inverseSurface,
              ),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(l10n.t('analyticsExport')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<AnalyticsDatePreset>(
      tooltip: l10n.t('analyticsDateRange'),
      onSelected: (preset) async {
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
      },
      itemBuilder: (_) => [
        for (final p in AnalyticsDatePreset.values)
          PopupMenuItem(value: p, child: Text(_label(p, l10n))),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.date_range_rounded, size: 16),
        label: Text(_label(current, l10n)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
