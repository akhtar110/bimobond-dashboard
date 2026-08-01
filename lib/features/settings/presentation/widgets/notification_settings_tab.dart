import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';
import 'settings_header.dart';
import 'settings_section.dart';
import 'settings_switch_tile.dart';

/// Switches for NOTIFICATIONS_* settings with immediate patch on toggle.
class NotificationSettingsTab extends StatelessWidget {
  const NotificationSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canWrite = PermissionManager.canWriteSettings(context);

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.settings != next.settings ||
          prev.isLoading != next.isLoading ||
          prev.isSaving != next.isSaving ||
          prev.isSeeding != next.isSeeding,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = state.settingsByKeys(NotificationSettingKeys.all);

        if (settings.isEmpty) {
          return EmptyStateCard(
            icon: Icons.notifications_outlined,
            title: l10n.tOr('settingsNoNotifications', 'No notification settings'),
            message: l10n.tOr(
              'settingsNoNotificationsMessage',
              'Seed defaults or create notification toggles.',
            ),
            action: canWrite
                ? FilledButton.tonalIcon(
                    onPressed: state.isSeeding
                        ? null
                        : () => confirmAndSeedAdminSettings(context),
                    icon: state.isSeeding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.grass_outlined, size: 18),
                    label: Text(l10n.tOr('seedSettings', 'Seed defaults')),
                  )
                : null,
          );
        }

        return SettingsSection(
          title: l10n.tOr('tabNotifications', 'Notifications'),
          description: l10n.tOr(
            'settingsNotificationsDescription',
            'Control global and channel notification delivery.',
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
