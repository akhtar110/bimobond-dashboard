import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/settings_cubit.dart';
import 'settings_section.dart';

class LanguageSelectorCard extends StatelessWidget {
  const LanguageSelectorCard({super.key});

  static const _english = Locale('en');
  static const _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.watch<SettingsCubit>().state.locale;

    return SettingsSection(
      title: l10n.t('languageAndRegion'),
      description: l10n.t('languageAndRegionDescription'),
      child: SettingsSurfaceCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 480;

            final englishOption = _LanguageOption(
              label: l10n.t('english'),
              subtitle: 'English (US)',
              flag: 'EN',
              selected: locale.languageCode == 'en',
              onTap: () =>
                  context.read<SettingsCubit>().switchLanguage(_english),
            );

            final arabicOption = _LanguageOption(
              label: l10n.t('arabic'),
              subtitle: 'العربية',
              flag: 'AR',
              selected: locale.languageCode == 'ar',
              onTap: () =>
                  context.read<SettingsCubit>().switchLanguage(_arabic),
            );

            if (useRow) {
              return Row(
                children: [
                  Expanded(child: englishOption),
                  const SizedBox(width: 12),
                  Expanded(child: arabicOption),
                ],
              );
            }

            return Column(
              children: [
                englishOption,
                const SizedBox(height: 12),
                arabicOption,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguageOption extends StatefulWidget {
  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<_LanguageOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252B3B)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  widget.flag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: widget.selected ? primary : theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w600,
                        color: widget.selected ? primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.grey.shade500
                            : const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle_rounded, size: 20, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
