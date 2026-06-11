import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../analytics/presentation/widgets/analytics_kpi_card.dart';
import '../bloc/reports_center_overview_cubit.dart';

class ReportsOverviewCards extends StatelessWidget {
  const ReportsOverviewCards({super.key});

  int _crossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 640) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCenterOverviewCubit, ReportsCenterOverviewState>(
      builder: (context, state) {
        if (state.loading && state.metrics.isEmpty) {
          return const _OverviewSkeleton();
        }

        if (state.error != null && state.metrics.isEmpty) {
          return _OverviewError(
            message: state.error!,
            onRetry: () => context.read<ReportsCenterOverviewCubit>().load(),
          );
        }

        if (state.metrics.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _crossAxisCount(constraints.maxWidth);
            final spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: state.metrics.map((metric) {
                return SizedBox(
                  width: itemWidth,
                  child: AnalyticsKpiCard(
                    title: metric.label,
                    value: NumberFormat.compact().format(metric.total),
                    subtitle: metric.periodLabel ?? 'All time',
                    icon: metric.icon,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 1100
            ? 6
            : constraints.maxWidth >= 640
                ? 3
                : 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            count,
            (_) => Container(
              width: (constraints.maxWidth - 12 * (count - 1)) / count,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
