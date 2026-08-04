import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_downloader.dart';
import '../../domain/entities/log_entity.dart';

enum LogsExportFormat {
  excel,
  csv,
}

class LogsExportParams {
  const LogsExportParams({
    required this.logs,
    required this.query,
  });

  final List<LogEntity> logs;
  final LogsQuery query;

  String get activeFiltersSummary {
    final parts = <String>[];
    if (query.user != null) {
      parts.add('User: ${query.user!.username}');
    } else if (query.userId != null && query.userId!.trim().isNotEmpty) {
      parts.add('User ID: ${query.userId}');
    }
    if (query.actorRole != null && query.actorRole!.trim().isNotEmpty) {
      parts.add('Role: ${query.actorRole}');
    }
    if (query.category != null && query.category!.trim().isNotEmpty) {
      parts.add('Category: ${query.category}');
    }
    if (query.action != null && query.action!.trim().isNotEmpty) {
      parts.add('Action: ${query.action}');
    }
    if (query.from != null) {
      parts.add(
          'From: ${DateFormat('yyyy-MM-dd HH:mm').format(query.from!.toLocal())}');
    }
    if (query.to != null) {
      parts.add(
          'To: ${DateFormat('yyyy-MM-dd HH:mm').format(query.to!.toLocal())}');
    }
    if (query.deviceId != null && query.deviceId!.trim().isNotEmpty) {
      parts.add('Device: ${query.deviceId}');
    }
    return parts.isEmpty ? 'None (All Security Logs)' : parts.join(' | ');
  }
}

/// Column headers that match the displayed table column order exactly.
const List<String> _kHeaders = [
  'Date & Time',
  'User',
  'Actor Role',
  'Category',
  'Action',
  'Target',
  'IP Address',
  'Device / Agent',
  'Log ID',
  'Description',
];

class LogsExportService {
  static const List<String> headers = _kHeaders;

  static Future<void> exportLogs({
    required LogsExportParams params,
    required LogsExportFormat format,
  }) async {
    if (params.logs.isEmpty) {
      throw Exception('No data to export.');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    switch (format) {
      case LogsExportFormat.csv:
        final csvContent = _generateCsv(params);
        final bytes = utf8.encode(csvContent);
        await saveAndDownloadFile(
          bytes: bytes,
          fileName: 'logs_export_$timestamp.csv',
          mimeType: 'text/csv; charset=utf-8',
        );
        break;

      case LogsExportFormat.excel:
        final xlsxBytes = _generateXlsx(params);
        if (xlsxBytes.isEmpty) {
          throw Exception('Failed to generate Excel file.');
        }
        await saveAndDownloadFile(
          bytes: xlsxBytes,
          fileName: 'logs_export_$timestamp.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared row helpers
  // ─────────────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal());

  static String _userLabel(LogEntity log) {
    final primary = log.displayUser;
    final secondary = log.secondaryUserLabel;
    if (primary.isNotEmpty) {
      return secondary != null ? '$primary ($secondary)' : primary;
    }
    return log.actorId ?? '—';
  }

  static String _description(LogEntity log) {
    final desc = log.description?.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    final meta = log.meta;
    if (meta != null && meta.isNotEmpty) return meta.toString();
    return '—';
  }

  static List<String> _rowCells(LogEntity log) => [
        _formatDate(log.createdAt),
        _userLabel(log),
        log.actorRole ?? '—',
        log.category,
        log.action,
        log.displayTarget ?? '—',
        log.ipAddress ?? '—',
        log.device ?? '—',
        log.id,
        _description(log),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // CSV
  // ─────────────────────────────────────────────────────────────────────────

  static String _csvCell(String val) {
    if (val.contains(',') ||
        val.contains('"') ||
        val.contains('\n') ||
        val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  static String _generateCsv(LogsExportParams params) {
    final sb = StringBuffer();
    sb.write('\uFEFF'); // UTF-8 BOM — Excel auto-detects UTF-8
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    sb.writeln('BimoBond Admin Dashboard - Security Logs Export');
    sb.writeln('Generated At:,$now');
    sb.writeln('Total Records:,${params.logs.length}');
    sb.writeln('Applied Filters:,${_csvCell(params.activeFiltersSummary)}');
    sb.writeln();
    sb.writeln(_kHeaders.map(_csvCell).join(','));
    for (final log in params.logs) {
      sb.writeln(_rowCells(log).map(_csvCell).join(','));
    }
    return sb.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Proper OOXML .xlsx (ZIP of XML parts)
  //
  // Element order inside <worksheet> (ECMA-376 §18.3.1.99):
  //   sheetPr? → dimension? → sheetViews? → sheetFormatPr? → cols? →
  //   sheetData → (autoFilter, etc.)
  // ─────────────────────────────────────────────────────────────────────────

  static List<int> _generateXlsx(LogsExportParams params) {
    // ── Shared-string table ────────────────────────────────────────────────
    final strings = <String>[];
    final strIdx = <String, int>{};

    int addStr(String v) => strIdx.putIfAbsent(v, () {
          final i = strings.length;
          strings.add(v);
          return i;
        });

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // ── Worksheet XML ──────────────────────────────────────────────────────
    final ws = StringBuffer();
    ws.write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet'
        ' xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        ' xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"'
        ' mc:Ignorable="x14ac"'
        ' xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">');

    // Total rows = 4 meta + 1 blank + 1 header + data rows
    final totalRows = 6 + params.logs.length;
    final lastDataCol = _colLetter(_kHeaders.length - 1);
    ws.write('<dimension ref="A1:$lastDataCol$totalRows"/>');

    // sheetViews — freeze first 6 rows (4 meta + blank + header)
    ws.write('<sheetViews>'
        '<sheetView tabSelected="1" workbookViewId="0">'
        '<pane ySplit="6" topLeftCell="A7" activePane="bottomLeft" state="frozen"/>'
        '<selection pane="bottomLeft" activeCell="A7" sqref="A7"/>'
        '</sheetView>'
        '</sheetViews>');

    ws.write('<sheetFormatPr defaultRowHeight="15" x14ac:dyDescent="0.25"/>');

    // Column widths
    ws.write('<cols>');
    final widths = [22, 24, 13, 13, 22, 22, 18, 28, 34, 42];
    for (var c = 0; c < widths.length; c++) {
      ws.write(
          '<col min="${c + 1}" max="${c + 1}" width="${widths[c]}" bestFit="0" customWidth="1"/>');
    }
    ws.write('</cols>');

    // sheetData
    ws.write('<sheetData>');

    // Helper: write a shared-string cell
    String sc(String colRow, String value, {int style = 0}) =>
        '<c r="$colRow" t="s" s="$style"><v>${addStr(value)}</v></c>';

    // ── Meta rows (rows 1-4) ─────────────────────────────────────────────
    ws.write('<row r="1" spans="1:2">'
        '${sc('A1', 'BimoBond Admin - Security Logs Export')}'
        '</row>');
    ws.write('<row r="2" spans="1:2">'
        '${sc('A2', 'Generated At')}${sc('B2', now)}'
        '</row>');
    ws.write('<row r="3" spans="1:2">'
        '${sc('A3', 'Total Records')}${sc('B3', params.logs.length.toString())}'
        '</row>');
    ws.write('<row r="4" spans="1:2">'
        '${sc('A4', 'Applied Filters')}${sc('B4', params.activeFiltersSummary)}'
        '</row>');

    // Row 5: blank separator
    ws.write('<row r="5"/>');

    // ── Header row (row 6) — style index 1 ───────────────────────────────
    ws.write('<row r="6" spans="1:${_kHeaders.length}" s="1" customFormat="1">');
    for (var c = 0; c < _kHeaders.length; c++) {
      ws.write(sc('${_colLetter(c)}6', _kHeaders[c], style: 1));
    }
    ws.write('</row>');

    // ── Data rows (rows 7+) ───────────────────────────────────────────────
    for (var r = 0; r < params.logs.length; r++) {
      final rowIdx = r + 7;
      final rowStyle = r.isOdd ? 2 : 0;
      final cells = _rowCells(params.logs[r]);
      ws.write(
          '<row r="$rowIdx" spans="1:${cells.length}" s="$rowStyle" customFormat="${r.isOdd ? 1 : 0}">');
      for (var c = 0; c < cells.length; c++) {
        ws.write(sc('${_colLetter(c)}$rowIdx', cells[c], style: rowStyle));
      }
      ws.write('</row>');
    }

    ws.write('</sheetData>');

    // AutoFilter on header row
    ws.write('<autoFilter ref="A6:${lastDataCol}6"/>');
    ws.write('</worksheet>');

    // ── Shared strings XML ────────────────────────────────────────────────
    final ssSb = StringBuffer();
    ssSb.write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' count="${strings.length}" uniqueCount="${strings.length}">');
    for (final s in strings) {
      // xml:space="preserve" keeps leading/trailing whitespace; required for
      // Arabic and other bidirectional/whitespace-sensitive strings.
      ssSb.write('<si><t xml:space="preserve">${_xmlEsc(s)}</t></si>');
    }
    ssSb.write('</sst>');

    // ── Styles XML ────────────────────────────────────────────────────────
    //
    // OOXML fill indices 0 & 1 are RESERVED (none + gray125).
    // Custom fills start at index 2.
    //
    // Fill index map:
    //   0 = none (required)
    //   1 = gray125 (required)
    //   2 = stripe background (#F1F5F9)
    //   3 = header background (#1E293B)
    //
    // Font index map:
    //   0 = default (Calibri 11)
    //   1 = header  (Calibri 11 bold white)
    //
    // Border index map:
    //   0 = none (required)
    //   1 = thin light border (#E2E8F0)
    //
    // cellXfs (style) index map:
    //   0 = default cell  (font 0, fill 0, border 1, wrap+top)
    //   1 = header cell   (font 1, fill 3, border 1, no wrap, vcenter)
    //   2 = stripe cell   (font 0, fill 2, border 1, wrap+top)
    const stylesXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"'
        ' mc:Ignorable="x14ac"'
        ' xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">'
        // Fonts
        '<fonts count="2" x14ac:knownFonts="1">'
        '<font><sz val="11"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '</fonts>'
        // Fills
        '<fills count="4">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F9"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1E293B"/><bgColor indexed="64"/></patternFill></fill>'
        '</fills>'
        // Borders
        '<borders count="2">'
        '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border>'
        '<left style="thin"><color rgb="FFE2E8F0"/></left>'
        '<right style="thin"><color rgb="FFE2E8F0"/></right>'
        '<top style="thin"><color rgb="FFE2E8F0"/></top>'
        '<bottom style="thin"><color rgb="FFE2E8F0"/></bottom>'
        '<diagonal/>'
        '</border>'
        '</borders>'
        // cellStyleXfs (base formats — required)
        '<cellStyleXfs count="1">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
        '</cellStyleXfs>'
        // cellXfs (applied formats)
        '<cellXfs count="3">'
        // 0 – default data cell
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        // 1 – header cell (bold, white text, navy fill)
        '<xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="center" wrapText="0"/></xf>'
        // 2 – stripe data cell
        '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        '</cellXfs>'
        // cellStyles
        '<cellStyles count="1">'
        '<cellStyle name="Normal" xfId="0" builtinId="0"/>'
        '</cellStyles>'
        '</styleSheet>';

    // ── Workbook XML ──────────────────────────────────────────────────────
    const workbookXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook'
        ' xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<fileVersion appName="xl" lastEdited="5" lowestEdited="5" rupBuild="9303"/>'
        '<workbookPr defaultThemeVersion="124226"/>'
        '<bookViews><workbookView xWindow="0" yWindow="0" windowWidth="20000" windowHeight="15000"/></bookViews>'
        '<sheets><sheet name="Security Logs" sheetId="1" r:id="rId1"/></sheets>'
        '<calcPr calcId="145621"/>'
        '</workbook>';

    // ── [Content_Types].xml ───────────────────────────────────────────────
    const contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml"'
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml"'
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/sharedStrings.xml"'
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
        '<Override PartName="/xl/styles.xml"'
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>';

    // ── Root relationships ─────────────────────────────────────────────────
    const rootRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>';

    // ── Workbook relationships ─────────────────────────────────────────────
    const wbRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>';

    // ── Assemble ZIP (no compression on XML so Excel can stream-parse) ─────
    final archive = Archive();

    void addPart(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile.bytes(name, bytes));
    }

    addPart('[Content_Types].xml', contentTypes);
    addPart('_rels/.rels', rootRels);
    addPart('xl/workbook.xml', workbookXml);
    addPart('xl/_rels/workbook.xml.rels', wbRels);
    addPart('xl/worksheets/sheet1.xml', ws.toString());
    addPart('xl/sharedStrings.xml', ssSb.toString());
    addPart('xl/styles.xml', stylesXml);

    return ZipEncoder().encode(archive);
  }

  /// Zero-based column index → Excel column letter: 0→A, 25→Z, 26→AA …
  static String _colLetter(int index) {
    var result = '';
    var n = index;
    do {
      result = String.fromCharCode(65 + (n % 26)) + result;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return result;
  }

  /// XML-escape a string, preserving Arabic and all Unicode code-points.
  static String _xmlEsc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      // Remove XML-invalid control characters (keep \t \n \r).
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}
