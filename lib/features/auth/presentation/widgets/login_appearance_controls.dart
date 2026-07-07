import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';

class LoginAppearanceControls extends StatelessWidget {
  const LoginAppearanceControls({super.key});

  static const _english = Locale('en');
  static const _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LoginThemeToggle(),
                _LoginToggleDivider(
                  color: Theme.of(context).colorScheme.outline,
                ),
                const _LoginLanguageToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginThemeToggle extends StatelessWidget {
  const _LoginThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();

    final isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return _LoginToggleGroup(
      label: l10n.t('theme'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LoginToggleIcon(
            icon: Icons.light_mode_rounded,
            active: !isDark,
            activeColor: theme.colorScheme.primary,
          ),
          Switch.adaptive(
            value: isDark,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (dark) {
              cubit.switchThemeMode(
                dark ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          _LoginToggleIcon(
            icon: Icons.dark_mode_rounded,
            active: isDark,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _LoginLanguageToggle extends StatelessWidget {
  const _LoginLanguageToggle();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.select<SettingsCubit, bool>(
      (cubit) => cubit.state.locale.languageCode == 'ar',
    );
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();

    return _LoginToggleGroup(
      label: l10n.t('language'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LoginToggleText(
            label: 'EN',
            active: !isArabic,
            activeColor: theme.colorScheme.primary,
          ),
          Switch.adaptive(
            value: isArabic,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (arabic) {
              cubit.switchLanguage(
                arabic
                    ? LoginAppearanceControls._arabic
                    : LoginAppearanceControls._english,
              );
            },
          ),
          _LoginToggleText(
            label: 'AR',
            active: isArabic,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _LoginToggleGroup extends StatelessWidget {
  const _LoginToggleGroup({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }
}

class _LoginToggleIcon extends StatelessWidget {
  const _LoginToggleIcon({
    required this.icon,
    required this.active,
    required this.activeColor,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Icon(
      icon,
      size: 18,
      color: active
          ? activeColor
          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
  }
}

class _LoginToggleText extends StatelessWidget {
  const _LoginToggleText({
    required this.label,
    required this.active,
    required this.activeColor,
  });

  final String label;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: active
            ? activeColor
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
      ),
    );
  }
}

class _LoginToggleDivider extends StatelessWidget {
  const _LoginToggleDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
}
