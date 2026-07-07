import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/notification_type.dart';
import '../utils/notification_labels.dart';

class NotificationTypeDropdown extends StatelessWidget {
  const NotificationTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.types,
  });

  final NotificationType value;
  final ValueChanged<NotificationType> onChanged;

  /// If null, shows only admin-facing types.
  final List<NotificationType>? types;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = types ?? NotificationTypeX.adminTypes;
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<NotificationType>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.t('notificationFieldType'),
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      items: items
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(notificationComposerTypeLabel(l10n, t)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
