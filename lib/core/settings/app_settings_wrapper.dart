import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../theme/app_theme.dart';

/// Applies theme, text direction, and locale overrides without rebuilding
/// [MaterialApp] (keeps the navigator and route stack stable).
class AppSettingsWrapper extends StatelessWidget {
  const AppSettingsWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) =>
          previous.themeMode != current.themeMode ||
          previous.locale != current.locale,
      builder: (context, settings) {
        final locale = settings.locale;
        final isDark = settings.themeMode == ThemeMode.dark;
        final theme = isDark
            ? AppTheme.darkTheme(locale)
            : AppTheme.lightTheme(locale);
        final textDirection = locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;

        return Theme(
          data: theme,
          child: Localizations.override(
            context: context,
            locale: locale,
            child: Directionality(
              textDirection: textDirection,
              child: child,
            ),
          ),
        );
      },
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
