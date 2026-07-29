import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';
import 'setting_edit_dialog.dart';
import 'setting_item_card.dart';

/// Collapsible category section containing setting cards.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.category,
    required this.settings,
    this.initiallyExpanded = true,
  });

  final String category;
  final List<AppSettingEntity> settings;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canWrite = PermissionManager.canWriteSettings(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            SettingsAdminL10n.categoryLabel(context, category),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            l10n
                .tOr('settingsGroupCount', '{count} settings')
                .replaceAll('{count}', '${settings.length}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
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
                    ? () => _confirmDelete(context, settings[i].key)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String key) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tOr('deleteSettingTitle', 'Delete setting?')),
        content: Text(
          l10n
              .tOr('deleteSettingMessage', 'Remove setting {key}?')
              .replaceAll('{key}', key),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.tOr('cancel', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.tOr('delete', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminSettingsBloc>().add(DeleteAdminSettingEvent(key));
    }
  }
}
