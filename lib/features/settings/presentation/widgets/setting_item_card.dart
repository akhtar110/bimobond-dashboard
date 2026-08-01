import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../utils/settings_admin_l10n.dart';

/// Modern card for a single admin setting row.
class SettingItemCard extends StatelessWidget {
  const SettingItemCard({
    super.key,
    required this.setting,
    required this.canWrite,
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final AppSettingEntity setting;
  final bool canWrite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final updated = setting.updatedAt != null
        ? DateFormat.yMMMd().add_jm().format(setting.updatedAt!.toLocal())
        : l10n.tOr('settingsNotAvailable', '—');
    final label = SettingsAdminL10n.settingLabel(context, setting);
    final description =
        SettingsAdminL10n.settingDescription(context, setting);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canWrite) ...[
                  IconButton(
                    tooltip: l10n.tOr('edit', 'Edit'),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                  if (!setting.isProtected)
                    IconButton(
                      tooltip: l10n.tOr('delete', 'Delete'),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: scheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              setting.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: setting.isJson ? 'monospace' : null,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(
                  label: SettingsAdminL10n.settingTypeLabel(
                    context,
                    setting.type,
                  ),
                  color: scheme.secondaryContainer,
                  fg: scheme.onSecondaryContainer,
                ),
                _Badge(
                  label: setting.isPublic
                      ? l10n.tOr('settingsPublic', 'Public')
                      : l10n.tOr('settingsPrivate', 'Private'),
                  color: setting.isPublic
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  fg: setting.isPublic
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                if (setting.category != null)
                  _Badge(
                    label: SettingsAdminL10n.categoryLabel(
                      context,
                      setting.category,
                    ),
                    color: scheme.surfaceContainerHigh,
                    fg: scheme.onSurfaceVariant,
                  ),
                _Badge(
                  label: l10n
                      .tOr('settingsSortOrderBadge', 'Order {n}')
                      .replaceAll('{n}', '${setting.sortOrder}'),
                  color: scheme.surfaceContainerHigh,
                  fg: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n
                  .tOr('settingsUpdatedAt', 'Updated {date}')
                  .replaceAll('{date}', updated),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.fg,
  });

  final String label;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
