import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import 'setting_edit_dialog.dart';
import 'setting_item_card.dart';
import 'settings_header.dart';

/// Cards for UPLOAD_* configuration keys.
class UploadSettingsTab extends StatelessWidget {
  const UploadSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canWrite = PermissionManager.canWriteSettings(context);

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.settings != next.settings ||
          prev.isLoading != next.isLoading ||
          prev.isSeeding != next.isSeeding,
      builder: (context, state) {
        if (state.isLoading && state.settings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = state.settingsByKeys(UploadSettingKeys.all);

        if (settings.isEmpty) {
          return EmptyStateCard(
            icon: Icons.cloud_upload_outlined,
            title: l10n.tOr('settingsNoUploads', 'No upload settings'),
            message: l10n.tOr(
              'settingsNoUploadsMessage',
              'Upload limits will appear here after seeding.',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < settings.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SettingItemCard(
                setting: settings[i],
                canWrite: canWrite,
                onEdit: canWrite
                    ? () => showSettingEditDialog(context, settings[i])
                    : null,
                onDelete: null,
              ),
            ],
          ],
        );
      },
    );
  }
}
