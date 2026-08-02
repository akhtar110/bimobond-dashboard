import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';

/// Compare factory defaults from [SettingsDefaultsEntity] with live values.
class DefaultsTab extends StatelessWidget {
  const DefaultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.defaults != next.defaults ||
          prev.settings != next.settings ||
          prev.isLoading != next.isLoading,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final defaults = state.defaults;
        final entries = <MapEntry<String, String>>[
          MapEntry(
            defaults.commissionKey,
            defaults.commissionPercent.toString(),
          ),
          MapEntry(
            defaults.coinsPerPriceUnitKey,
            defaults.coinsPerPriceUnit.toString(),
          ),
          MapEntry('DEFAULT_CURRENCY_CODE', defaults.defaultCurrencyCode),
          ...defaults.keys.entries,
        ];

        if (entries.isEmpty) {
          return EmptyStateCard(
            icon: Icons.restore_outlined,
            title: l10n.tOr('settingsNoDefaults', 'No defaults'),
            message: l10n.tOr(
              'settingsNoDefaultsMessage',
              'Factory defaults are not available.',
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++)
                _DefaultCompareRow(
                  settingKey: entries[i].key,
                  factoryDefault: entries[i].value,
                  current: state.settingByKey(entries[i].key)?.value,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DefaultCompareRow extends StatelessWidget {
  const _DefaultCompareRow({
    required this.settingKey,
    required this.factoryDefault,
    required this.current,
  });

  final String settingKey;
  final String factoryDefault;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final matches = current != null && current == factoryDefault;

    final title = SettingsAdminL10n.settingKeyLabel(context, settingKey);

    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: title == settingKey ? 'monospace' : null,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n
                .tOr('settingsDefaultValue', 'Default: {value}')
                .replaceAll('{value}', factoryDefault),
          ),
          Text(
            l10n
                .tOr('settingsCurrentValue', 'Current: {value}')
                .replaceAll(
                  '{value}',
                  current ?? l10n.tOr('settingsNotAvailable', '—'),
                ),
          ),
        ],
      ),
      trailing: Icon(
        matches ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        color: matches ? scheme.primary : scheme.tertiary,
      ),
    );
  }
}
