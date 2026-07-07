import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/settings_cubit.dart';

class CompactThemeSelector extends StatelessWidget {
  const CompactThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();

    return _CompactControlShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactThemeButton(
            icon: Icons.light_mode_rounded,
            label: l10n.t('lightMode'),
            selected: themeMode == ThemeMode.light,
            onTap: () => cubit.switchThemeMode(ThemeMode.light),
          ),
          _CompactDivider(color: theme.dividerColor),
          _CompactThemeButton(
            icon: Icons.dark_mode_rounded,
            label: l10n.t('darkMode'),
            selected: themeMode == ThemeMode.dark,
            onTap: () => cubit.switchThemeMode(ThemeMode.dark),
          ),
          _CompactDivider(color: theme.dividerColor),
          _CompactThemeButton(
            icon: Icons.brightness_auto_rounded,
            label: l10n.t('systemMode'),
            selected: themeMode == ThemeMode.system,
            onTap: () => cubit.switchThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _CompactThemeButton extends StatelessWidget {
  const _CompactThemeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Icon(
            icon,
            size: 20,
            color: selected ? primary : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}

class _CompactControlShell extends StatelessWidget {
  const _CompactControlShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}

class _CompactDivider extends StatelessWidget {
  const _CompactDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }
}
