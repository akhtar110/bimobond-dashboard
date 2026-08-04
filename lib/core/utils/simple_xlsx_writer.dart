import 'dart:convert';

import 'package:archive/archive.dart';

/// Minimal XLSX writer (Office Open XML) using the existing [archive] package.
abstract final class SimpleXlsxWriter {
  static List<int> encode({
    required Map<String, List<List<String>>> sheets,
  }) {
    final archive = Archive();
    final sharedStrings = <String>[];
    final stringIndex = <String, int>{};

    int indexFor(String value) {
      return stringIndex.putIfAbsent(value, () {
        sharedStrings.add(value);
        return sharedStrings.length - 1;
      });
    }

    final sheetEntries = <String>[];
    var sheetId = 1;
    for (final entry in sheets.entries) {
      final sheetPath = 'xl/worksheets/sheet$sheetId.xml';
      sheetEntries.add(
        '<sheet name="${_xmlEscape(entry.key)}" sheetId="$sheetId" r:id="rId$sheetId"/>',
      );
      final sheetBytes = utf8.encode(_sheetXml(entry.value, indexFor));
      archive.addFile(
        ArchiveFile(
          sheetPath,
          sheetBytes.length,
          sheetBytes,
        ),
      );
      sheetId++;
    }

    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        0,
        utf8.encode(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '${List.generate(sheets.length, (i) => '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join()}'
          '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
          '</Types>',
        ),
      ),
    );

    archive.addFile(
      ArchiveFile(
        '_rels/.rels',
        0,
        utf8.encode(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>',
        ),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'xl/_rels/workbook.xml.rels',
        0,
        utf8.encode(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '${List.generate(sheets.length, (i) => '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>').join()}'
          '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>'
          '</Relationships>',
        ),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'xl/workbook.xml',
        0,
        utf8.encode(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets>${sheetEntries.join()}</sheets>'
          '</workbook>',
        ),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'xl/sharedStrings.xml',
        0,
        utf8.encode(_sharedStringsXml(sharedStrings)),
      ),
    );

    return ZipEncoder().encode(archive);
  }

  static String _sharedStringsXml(List<String> strings) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'count="${strings.length}" uniqueCount="${strings.length}">',
    );
    for (final value in strings) {
      buffer.write('<si><t>${_xmlEscape(value)}</t></si>');
    }
    buffer.write('</sst>');
    return buffer.toString();
  }

  static String _sheetXml(
    List<List<String>> rows,
    int Function(String value) indexFor,
  ) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetData>',
    );

    for (var r = 0; r < rows.length; r++) {
      buffer.write('<row r="${r + 1}">');
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final cellRef = '${_columnName(c)}${r + 1}';
        final idx = indexFor(row[c]);
        buffer.write(
          '<c r="$cellRef" t="s"><v>$idx</v></c>',
        );
      }
      buffer.write('</row>');
    }

    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  static String _columnName(int index) {
    var n = index + 1;
    final buffer = StringBuffer();
    while (n > 0) {
      n--;
      buffer.writeCharCode(65 + (n % 26));
      n ~/= 26;
    }
    return buffer.toString().split('').reversed.join();
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
