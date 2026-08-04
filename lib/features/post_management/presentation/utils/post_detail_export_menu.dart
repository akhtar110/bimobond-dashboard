import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../services/post_detail_export_data.dart';

Future<PostDetailExportFormat?> showPostDetailExportMenu(
  BuildContext context,
) async {
  final l10n = context.l10n;
  return showModalBottomSheet<PostDetailExportFormat>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.tOr('postDetailExport', 'Export post details')),
              subtitle: Text(
                l10n.tOr(
                  'postDetailExportHint',
                  'Download post details, analytics, and moderation timeline',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.tOr('postDetailExportCsv', 'CSV (.csv)')),
              onTap: () => Navigator.pop(ctx, PostDetailExportFormat.csv),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_outlined),
              title: Text(l10n.tOr('postDetailExportExcel', 'Excel (.xlsx)')),
              onTap: () => Navigator.pop(ctx, PostDetailExportFormat.excel),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.tOr('postDetailExportPdf', 'PDF (.pdf)')),
              onTap: () => Navigator.pop(ctx, PostDetailExportFormat.pdf),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
