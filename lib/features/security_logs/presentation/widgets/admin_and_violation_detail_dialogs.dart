import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/log_entity.dart';
import '../utils/logs_labels.dart';

Future<void> showAdminActionDetailDialog(BuildContext context, LogEntity log) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _AdminActionDetailDialog(log: log),
  );
}

Future<void> showViolationDetailDialog(BuildContext context, LogEntity log) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ViolationDetailDialog(log: log),
  );
}

class _AdminActionDetailDialog extends StatelessWidget {
  const _AdminActionDetailDialog({required this.log});

  final LogEntity log;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();

    Widget detailRow(String label, String value, {bool copyable = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
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
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.tOr('adminActionDetailTitle', 'Administrative Action Record'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              detailRow(l10n.tOr('actionType', 'Action'), actionLabel),
              detailRow(
                l10n.tOr('timestamp', 'Timestamp'),
                dateFmt.format(log.createdAt.toLocal()),
              ),
              detailRow(
                l10n.tOr('administrator', 'Administrator / Staff'),
                log.displayUser.isNotEmpty ? log.displayUser : (log.actorId ?? 'System Admin'),
                copyable: true,
              ),
              if ((log.userEmail ?? '').trim().isNotEmpty)
                detailRow(
                  l10n.tOr('staffEmail', 'Staff Email'),
                  log.userEmail!.trim(),
                  copyable: true,
                ),
              if ((log.targetId ?? '').trim().isNotEmpty)
                detailRow(
                  l10n.tOr('targetUserId', 'Target User ID'),
                  log.targetId!.trim(),
                  copyable: true,
                ),
              if ((log.description ?? '').trim().isNotEmpty)
                detailRow(
                  l10n.tOr('notesAndReason', 'Notes / Reason'),
                  log.description!.trim(),
                ),
              if (log.meta != null && log.meta!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n.tOr('actionPayloadDetails', 'Action Data Changes'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    log.meta.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tOr('close', 'Close')),
        ),
      ],
    );
  }
}

class _ViolationDetailDialog extends StatelessWidget {
  const _ViolationDetailDialog({required this.log});

  final LogEntity log;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();

    Widget detailRow(String label, String value, {bool copyable = false, Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
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
                      color: valueColor,
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

    final violationType = log.action.isNotEmpty ? log.action : 'GUIDELINE_VIOLATION';
    final severity = _severityForViolation(log);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.tOr('violationDetailTitle', 'Community Guideline Violation Record'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              detailRow(l10n.tOr('violationType', 'Violation Type'), violationType, valueColor: Colors.red),
              detailRow(l10n.tOr('severityLevel', 'Severity'), severity, valueColor: Colors.red),
              detailRow(
                l10n.tOr('timestamp', 'Timestamp'),
                dateFmt.format(log.createdAt.toLocal()),
              ),
              detailRow(
                l10n.tOr('violatorUser', 'Violator Username'),
                log.displayUser.isNotEmpty ? log.displayUser : (log.actorId ?? 'Target User'),
                copyable: true,
              ),
              if ((log.description ?? '').trim().isNotEmpty)
                detailRow(
                  l10n.tOr('violationDetails', 'Incident Details'),
                  log.description!.trim(),
                ),
              if ((log.targetType ?? '').trim().isNotEmpty)
                detailRow(
                  l10n.tOr('affectedContent', 'Affected Content'),
                  '${log.targetType} ${log.targetId ?? ''}'.trim(),
                  copyable: true,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tOr('close', 'Close')),
        ),
      ],
    );
  }

  String _severityForViolation(LogEntity log) {
    final act = log.action.toUpperCase();
    if (act.contains('BAN') || act.contains('DELETE') || act.contains('STRIKE_3')) {
      return 'HIGH (Account Risk)';
    }
    if (act.contains('WARN') || act.contains('SUSPEND') || act.contains('STRIKE_2')) {
      return 'MEDIUM (Warning / Strike)';
    }
    return 'STANDARD (Policy Violation)';
  }
}
