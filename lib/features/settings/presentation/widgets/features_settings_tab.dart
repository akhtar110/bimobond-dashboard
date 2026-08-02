import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';
import 'setting_edit_dialog.dart';
import 'settings_section.dart';
import 'settings_switch_tile.dart';

/// Boolean feature flags from features-related categories.
class FeaturesSettingsTab extends StatelessWidget {
  const FeaturesSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.filteredSettings != next.filteredSettings ||
          prev.isLoading != next.isLoading ||
          prev.isSaving != next.isSaving,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = state.filteredSettings.where((s) {
          if (!s.isBoolean) return false;
          if (NotificationSettingKeys.all.contains(s.key)) return false;
          return s.category == AppSettingCategories.features ||
              s.category == AppSettingCategories.auction ||
              s.category == AppSettingCategories.promotion ||
              s.key.endsWith('_ENABLED');
        }).toList();

        if (settings.isEmpty) {
          return EmptyStateCard(
            icon: Icons.flag_outlined,
            title: l10n.tOr('settingsNoFeatureFlags', 'No feature flags'),
            message: l10n.tOr(
              'settingsNoFeatureFlagsMessage',
              'Feature toggles will appear here.',
            ),
          );
        }

        final canWrite = PermissionManager.canWriteSettings(context);
        final scheme = Theme.of(context).colorScheme;

        return SettingsSection(
          title: l10n.tOr('settingsTabFeatures', 'Features'),
          description: l10n.tOr(
            'settingsFeaturesDescription',
            'Enable or disable platform capabilities.',
          ),
          child: SettingsSwitchGroupCard(
            children: [
              for (var i = 0; i < settings.length; i++)
                SettingsSwitchTile(
                  title: SettingsAdminL10n.settingLabel(context, settings[i]),
                  subtitle: SettingsAdminL10n.settingDescription(
                        context,
                        settings[i],
                      ) ??
                      settings[i].key,
                  value: settings[i].boolValue,
                  enabled: canWrite && !state.isSaving,
                  showDivider: i < settings.length - 1,
                  trailing: canWrite
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.tOr('edit', 'Edit'),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  showSettingEditDialog(context, settings[i]),
                            ),
                            if (!settings[i].isProtected)
                              IconButton(
                                tooltip: l10n.tOr('delete', 'Delete'),
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: scheme.error,
                                ),
                                onPressed: () => context
                                    .read<AdminSettingsBloc>()
                                    .add(DeleteAdminSettingEvent(settings[i].key)),
                              ),
                          ],
                        )
                      : null,
                  onChanged: !canWrite || state.isSaving
                      ? null
                      : (value) {
                          context.read<AdminSettingsBloc>().add(
                                UpdateAdminSettingEvent(
                                  settings[i].copyWith(
                                    value: value ? 'true' : 'false',
                                  ),
                                ),
                              );
                        },
                ),
            ],
          ),
        );
      },
    );
  }
}
