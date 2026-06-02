import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/settings_cubit.dart';
import 'settings_section.dart';

class ThemeSelectorCard extends StatelessWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.watch<SettingsCubit>().state.themeMode == ThemeMode.dark;

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
              selected: !isDark,
              onTap: () => context.read<SettingsCubit>().switchTheme(false),
            );

            final darkOption = _ThemeOption(
              label: l10n.t('darkMode'),
              icon: Icons.dark_mode_rounded,
              previewColors: const [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
              selected: isDark,
              onTap: () => context.read<SettingsCubit>().switchTheme(true),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.selected
                ? primary.withValues(alpha: 0.08)
                : (_hovered
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected
                  ? primary.withValues(alpha: 0.55)
                  : theme.colorScheme.outline.withValues(
                      alpha: _hovered ? 0.35 : 0.2,
                    ),
              width: widget.selected ? 1.5 : 1,
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
                    color: widget.selected ? primary : theme.iconTheme.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500,
                        color: widget.selected ? primary : null,
                      ),
                    ),
                  ),
                  if (widget.selected)
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
