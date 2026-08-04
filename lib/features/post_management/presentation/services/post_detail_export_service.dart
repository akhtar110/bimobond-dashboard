import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/file_download.dart';
import '../../../../core/utils/simple_xlsx_writer.dart';
import 'post_detail_export_data.dart';

abstract final class PostDetailExportService {
  static Future<void> export({
    required PostDetailExportData data,
    required PostDetailExportFormat format,
  }) async {
    switch (format) {
      case PostDetailExportFormat.csv:
        await _exportCsv(data);
      case PostDetailExportFormat.excel:
        await _exportExcel(data);
      case PostDetailExportFormat.pdf:
        await _exportPdf(data);
    }
  }

  static Future<void> _exportCsv(PostDetailExportData data) async {
    final buffer = StringBuffer();
    _writeCsvSection(buffer, 'Post Details', data.details);
    if (data.analyticsRows.isNotEmpty) {
      buffer.writeln();
      _writeCsvSection(buffer, 'Analytics', data.analyticsRows);
    }
    if (data.timeline.isNotEmpty) {
      buffer.writeln();
      _writeCsvSection(buffer, 'Moderation Timeline', data.timeline);
    }
    buffer.writeln();
    buffer.writeln('"Generated At","${data.generatedAt.toIso8601String()}"');

    final bytes = Uint8List.fromList(utf8.encode('\uFEFF${buffer.toString()}'));
    await downloadFileBytes(
      bytes: bytes,
      filename: '${data.filenameBase}.csv',
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  static void _writeCsvSection(
    StringBuffer buffer,
    String title,
    List<PostDetailExportRow> rows,
  ) {
    buffer.writeln('"$title"');
    buffer.writeln('"Field","Value"');
    for (final row in rows) {
      buffer.writeln(
        '"${_escapeCsv(row.field)}","${_escapeCsv(row.value)}"',
      );
    }
  }

  static String _escapeCsv(String value) =>
      value.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', ' ');

  static Future<void> _exportExcel(PostDetailExportData data) async {
    final sheets = <String, List<List<String>>>{
      'Post Details': _rowsToTable(data.details),
    };
    if (data.analyticsRows.isNotEmpty) {
      sheets['Analytics'] = _rowsToTable(data.analyticsRows);
    }
    if (data.timeline.isNotEmpty) {
      sheets['Timeline'] = _rowsToTable(data.timeline);
    }

    final encoded = SimpleXlsxWriter.encode(sheets: sheets);
    await downloadFileBytes(
      bytes: Uint8List.fromList(encoded),
      filename: '${data.filenameBase}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static List<List<String>> _rowsToTable(List<PostDetailExportRow> rows) {
    return [
      const ['Field', 'Value'],
      ...rows.map((row) => [row.field, row.value]),
    ];
  }

  static Future<void> _exportPdf(PostDetailExportData data) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Post Details Export',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated: ${data.generatedAt.toLocal()}'),
          pw.SizedBox(height: 16),
          _pdfSection('Post Details', data.details),
          if (data.analyticsRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _pdfSection('Analytics', data.analyticsRows),
          ],
          if (data.timeline.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _pdfSection('Moderation Timeline', data.timeline),
          ],
        ],
      ),
    );

    final bytes = await doc.save();
    await downloadFileBytes(
      bytes: Uint8List.fromList(bytes),
      filename: '${data.filenameBase}.pdf',
      mimeType: 'application/pdf',
    );
  }

  static pw.Widget _pdfSection(String title, List<PostDetailExportRow> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Field', 'Value'],
          data: rows.map((row) => [row.field, row.value]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FixedColumnWidth(160),
            1: const pw.FlexColumnWidth(),
          },
        ),
      ],
    );
  }
}
