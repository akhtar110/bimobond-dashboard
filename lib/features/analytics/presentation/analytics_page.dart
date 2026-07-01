import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../users/domain/entities/user_entity.dart';
import '../../../core/bloc/persistent_bloc_provider.dart';
import '../../../injection_container.dart' as di;
import 'bloc/analytics_bloc.dart';
import 'widgets/analytics_dashboard_body.dart';

/// Page-scoped analytics dashboard with its own [AnalyticsBloc].
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('AnalyticsPage rebuilt');
    return PersistentBlocProvider<AnalyticsBloc>(
      debugLabel: 'AnalyticsPage',
      create: () => di.sl<AnalyticsBloc>(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      final accessLevel = _resolveAccessLevel(authState);
      final mode = accessLevel == AnalyticsAccessLevel.creator
          ? AnalyticsDashboardMode.creator
          : AnalyticsDashboardMode.admin;
      context.read<AnalyticsBloc>().add(
            LoadAnalyticsDashboardEvent(
              mode: mode,
              accessLevel: accessLevel,
            ),
          );
    });
  }

  AnalyticsAccessLevel _resolveAccessLevel(AuthState authState) {
    if (authState is! Authenticated) return AnalyticsAccessLevel.admin;
    final roles = authState.user.roles;
    if (roles.contains(UserRole.admin)) {
      return AnalyticsAccessLevel.admin;
    }
    if (roles.contains(UserRole.moderator)) {
      return AnalyticsAccessLevel.moderator;
    }
    return AnalyticsAccessLevel.creator;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
