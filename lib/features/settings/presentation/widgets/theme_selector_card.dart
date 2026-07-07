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
      description: l10n.t('appearanceDescription'),
      child: SettingsSurfaceCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 480;

            final lightOption = _ThemeOption(
              label: l10n.t('lightMode'),
              icon: Icons.light_mode_rounded,
              previewColors: const [
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
                Color(0xFFCBD5E1),
              ],
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
              previewColors: const [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
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
                  const SizedBox(width: 12),
                  Expanded(child: darkOption),
                ],
              );
            }

            return Column(
              children: [
                lightOption,
                const SizedBox(height: 12),
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
    required this.previewColors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> previewColors;
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
    final primary = theme.colorScheme.primary;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration.zero,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.08)
                : (_hovered
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.55)
                  : theme.colorScheme.outline.withValues(
                      alpha: _hovered ? 0.35 : 0.2,
                    ),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      for (final color in widget.previewColors)
                        Expanded(child: ColoredBox(color: color)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: selected ? primary : theme.iconTheme.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? primary : null,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
