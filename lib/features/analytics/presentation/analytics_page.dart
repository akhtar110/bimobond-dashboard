import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart' as di;
import 'bloc/analytics_bloc.dart';
import 'widgets/analytics_dashboard_body.dart';

/// Page-scoped analytics dashboard with its own [AnalyticsBloc].
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<AnalyticsBloc>()..add(const LoadAnalyticsDashboardEvent()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Match ReportsPage: fill shell content area with bounded scroll region.
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: scheme.surfaceContainerLowest,
      child: const Align(
        alignment: Alignment.topCenter,
        child: AnalyticsDashboardBody(),
      ),
    );
  }
}
