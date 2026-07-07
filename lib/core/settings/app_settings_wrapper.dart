import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';

/// Clears focus before locale/theme rebuilds (web focus traversal).
class AppSettingsWrapper extends StatelessWidget {
  const AppSettingsWrapper({super.key, required this.child});

  final Widget child;

  static void releaseFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.themeMode != current.themeMode ||
          previous.locale != current.locale,
      listener: (_, _) {
        releaseFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) => releaseFocus());
      },
      child: child,
    );
  }
}

/// Routes authenticated users to the navigator; others see login / loading.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.navigator});

  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is Authenticated) return navigator;
        if (state is Unauthenticated) return const LoginPage();
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
