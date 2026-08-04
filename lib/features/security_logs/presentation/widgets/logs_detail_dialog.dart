import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/log_entity.dart';
import '../utils/logs_labels.dart';

Future<void> showLogsDetailDialog(BuildContext context, LogEntity log) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _LogsDetailDialog(log: log),
  );
}

class _LogsDetailDialog extends StatelessWidget {
  const _LogsDetailDialog({required this.log});

  final LogEntity log;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();

    Widget row(String label, String value, {bool copyable = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (copyable && value != '—')
              IconButton(
                tooltip: l10n.tOr('copy', 'Copy'),
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.tOr('copied', 'Copied')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
              ),
          ],
        ),
      );
    }

    final actionLabel = logsActionLabel(l10n, log);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('logsDetailTitle', 'Log details')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              row(
                l10n.tOr('logsColDate', 'Date / Time'),
                dateFmt.format(log.createdAt.toLocal()),
              ),
              row(l10n.tOr('logsColUser', 'User'), logsDash(log.displayUser)),
              if ((log.userName ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColUserName', 'Username'),
                  log.userName!.trim(),
                  copyable: true,
                ),
              if ((log.actorId ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColActorId', 'Actor ID'),
                  log.actorId!.trim(),
                  copyable: true,
                ),
              row(
                l10n.tOr('logsColActorRole', 'Actor role'),
                logsActorRoleLabel(l10n, log.actorRole),
              ),
              row(
                l10n.tOr('logsColCategory', 'Category'),
                logsCategoryLabel(l10n, log.category),
              ),
              row(l10n.tOr('logsColAction', 'Action'), actionLabel),
              if (log.action.trim().isNotEmpty &&
                  actionLabel != log.action.trim())
                row(
                  l10n.tOr('logsColActionCode', 'Action code'),
                  log.action.trim(),
                  copyable: true,
                ),
              if ((log.targetType ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColTargetType', 'Target type'),
                  log.targetType!.trim(),
                ),
              if ((log.targetId ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColTargetId', 'Target ID'),
                  log.targetId!.trim(),
                  copyable: true,
                ),
              if ((log.permission ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColPermission', 'Permission'),
                  log.permission!.trim(),
                  copyable: true,
                ),
              if ((log.description ?? '').trim().isNotEmpty)
                row(
                  l10n.tOr('logsColDescription', 'Description'),
                  log.description!.trim(),
                ),
              if (log.meta != null) ...[
                if (log.meta!['previousValue'] != null || log.meta!['oldValue'] != null || log.meta!['oldRole'] != null)
                  row(
                    l10n.tOr('previousValue', 'Previous value'),
                    '${log.meta!['previousValue'] ?? log.meta!['oldValue'] ?? log.meta!['oldRole']}',
                  ),
                if (log.meta!['newValue'] != null || log.meta!['newRole'] != null)
                  row(
                    l10n.tOr('newValue', 'New value'),
                    '${log.meta!['newValue'] ?? log.meta!['newRole']}',
                  ),
                if (log.meta!['reason'] != null || log.meta!['banReason'] != null)
                  row(
                    l10n.tOr('reason', 'Reason'),
                    '${log.meta!['reason'] ?? log.meta!['banReason']}',
                  ),
              ],
              row(
                l10n.tOr('logsColIp', 'IP Address'),
                logsDash(log.ipAddress),
                copyable: true,
              ),
              row(
                l10n.tOr('logsColUserAgent', 'User agent'),
                logsDash(log.userAgent),
              ),
              row(
                l10n.tOr('logsColDeviceId', 'Device ID'),
                logsDash(log.deviceId),
                copyable: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('close')),
        ),
      ],
    );
  }
}
