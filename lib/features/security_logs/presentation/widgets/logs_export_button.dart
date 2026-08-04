import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/logs_bloc.dart';
import '../bloc/logs_event.dart';
import '../utils/logs_export_service.dart';

/// Export Button with Excel (.xlsx) and CSV options for Security Logs.
/// Always exports all records matching the currently active filters.
class LogsExportButton extends StatelessWidget {
  const LogsExportButton({
    super.key,
    required this.height,
    required this.isExporting,
    required this.enabled,
  });

  final double height;
  final bool isExporting;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isExporting) {
      return Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Exporting...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: PopupMenuButton<LogsExportFormat>(
          tooltip: l10n.tOr('export', 'Export'),
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          onSelected: (format) {
            context
                .read<LogsBloc>()
                .add(ExportLogsEvent(format: format));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: LogsExportFormat.excel,
              child: Row(
                children: [
                  Icon(Icons.table_chart_rounded,
                      size: 18, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Export to Excel (.xlsx)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: LogsExportFormat.csv,
              child: Row(
                children: [
                  Icon(Icons.description_rounded,
                      size: 18, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Export to CSV (.csv)'),
                ],
              ),
            ),
          ],
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.tOr('export', 'Export'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
