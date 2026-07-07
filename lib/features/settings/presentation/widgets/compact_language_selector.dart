import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/settings_cubit.dart';

class CompactLanguageSelector extends StatelessWidget {
  const CompactLanguageSelector({super.key});

  static const _english = Locale('en');
  static const _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    final languageCode = context.select<SettingsCubit, String>(
      (cubit) => cubit.state.locale.languageCode,
    );
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactLanguageButton(
            label: l10n.t('english'),
            code: 'EN',
            selected: languageCode == 'en',
            onTap: () => cubit.switchLanguage(_english),
          ),
          SizedBox(
            height: 24,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.35),
            ),
          ),
          _CompactLanguageButton(
            label: l10n.t('arabic'),
            code: 'AR',
            selected: languageCode == 'ar',
            onTap: () => cubit.switchLanguage(_arabic),
          ),
        ],
      ),
    );
  }
}

class _CompactLanguageButton extends StatelessWidget {
  const _CompactLanguageButton({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            code,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? primary : theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
