import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/bloc/persistent_bloc_provider.dart';
import '../../../injection_container.dart' as di;
import 'bloc/reports_bloc.dart';
import 'reports_center_page.dart';

/// Backward-compatible alias for shell navigation.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('ReportsPage rebuilt');
    return PersistentBlocProvider<ReportsBloc>(
      debugLabel: 'ReportsPage',
      create: () => di.sl<ReportsBloc>(),
      child: const ReportsCenterPage(),
    );
  }
}
