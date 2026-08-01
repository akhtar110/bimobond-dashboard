import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/settings_cubit.dart';
import 'settings_section.dart';

class ThemeSelectorCard extends StatefulWidget {
  const ThemeSelectorCard({super.key});

  @override
  State<ThemeSelectorCard> createState() => _ThemeSelectorCardState();
}

class _ThemeSelectorCardState extends State<ThemeSelectorCard> {
  bool? _optimisticDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = context.select<SettingsCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );

    if (_optimisticDark != null) {
      final optimisticMode =
          _optimisticDark! ? ThemeMode.dark : ThemeMode.light;
      if (optimisticMode == themeMode) {
        _optimisticDark = null;
      }
    }

    final effectiveMode = _optimisticDark == null
        ? themeMode
        : (_optimisticDark! ? ThemeMode.dark : ThemeMode.light);
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: l10n.t('appearance'),
      child: SettingsSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep options side-by-side even when this card is half-width.
            final useRow = constraints.maxWidth >= 260;

            final lightOption = _ThemeOption(
              label: l10n.t('lightMode'),
              icon: Icons.light_mode_rounded,
              selected: effectiveMode == ThemeMode.light,
              onTap: () {
                if (effectiveMode != ThemeMode.light) {
                  setState(() => _optimisticDark = false);
                  cubit.switchTheme(false);
                }
              },
            );

            final darkOption = _ThemeOption(
              label: l10n.t('darkMode'),
              icon: Icons.dark_mode_rounded,
              selected: effectiveMode == ThemeMode.dark,
              onTap: () {
                if (effectiveMode != ThemeMode.dark) {
                  setState(() => _optimisticDark = true);
                  cubit.switchTheme(true);
                }
              },
            );

            if (useRow) {
              return Row(
                children: [
                  Expanded(child: lightOption),
                  const SizedBox(width: 10),
                  Expanded(child: darkOption),
                ],
              );
            }

            return Column(
              children: [
                lightOption,
                const SizedBox(height: 10),
                darkOption,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThemeOption extends StatefulWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.08)
                : (_hovered
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : scheme.surface.withValues(alpha: 0)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: _hovered ? 0.35 : 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? primary : null,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 18, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
