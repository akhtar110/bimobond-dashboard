import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/log_entity.dart';
import '../utils/log_target_navigation.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final navTargets = LogTargetNavigation.resolveAll(log);

    final usernameText = () {
      final name = log.userName?.trim();
      if (name != null && name.isNotEmpty) return '@$name';
      final display = log.displayUser.trim();
      if (display.isNotEmpty) return display.startsWith('@') ? display : '@$display';
      return '—';
    }();

    final actorIdText = log.actorId?.trim();
    final ipText = log.ipAddress?.trim();
    final descriptionText = logsDisplayTitle(l10n, log, isArabic: isArabic);

    Widget fieldRow(String label, String value, {String? copyText}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (copyText != null && copyText.isNotEmpty && copyText != '—')
              IconButton(
                tooltip: l10n.tOr('copy', 'Copy'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: copyText));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.tOr('copied', 'Copied')),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
              ),
          ],
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.tOr('logsDetailTitle', 'Log details'),
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              fieldRow(
                l10n.tOr('logsColDate', 'Date & Time'),
                dateFmt.format(log.createdAt.toLocal()),
              ),
              fieldRow(
                l10n.tOr('logsColUserName', 'Username'),
                usernameText,
              ),
              if (actorIdText != null && actorIdText.isNotEmpty)
                fieldRow(
                  l10n.tOr('logsColActorId', 'Actor ID'),
                  actorIdText,
                  copyText: actorIdText,
                ),
              if (ipText != null && ipText.isNotEmpty)
                fieldRow(
                  l10n.tOr('logsColIp', 'IP Address'),
                  ipText,
                  copyText: ipText,
                ),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Text(
                l10n.tOr('logsColDescription', 'Description'),
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: SelectableText(
                  descriptionText,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ...navTargets.map(
          (target) => FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              LogTargetNavigation.open(context, target);
            },
            icon: Icon(target.icon, size: 16),
            label: Text(target.label(isArabic)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('close')),
        ),
      ],
    );
  }
}
