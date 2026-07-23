import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import 'setting_edit_dialog.dart';
import 'setting_item_card.dart';

/// Boolean feature flags from features-related categories.
class FeaturesSettingsTab extends StatelessWidget {
  const FeaturesSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.filteredSettings != next.filteredSettings ||
          prev.isLoading != next.isLoading,
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

        return _SettingsListPanel(
          settings: settings,
          categoryLabel: l10n.tOr('settingsTabFeatures', 'Features'),
        );
      },
    );
  }
}

class _SettingsListPanel extends StatelessWidget {
  const _SettingsListPanel({
    required this.settings,
    required this.categoryLabel,
  });

  final List<AppSettingEntity> settings;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final canWrite = PermissionManager.canWriteSettings(context);

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
            onDelete: canWrite && !settings[i].isProtected
                ? () => context
                    .read<AdminSettingsBloc>()
                    .add(DeleteAdminSettingEvent(settings[i].key))
                : null,
          ),
        ],
      ],
    );
  }
}
