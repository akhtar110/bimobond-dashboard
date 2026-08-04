import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_downloader.dart';
import '../../domain/entities/user_entity.dart';
import '../users_ui_filter.dart';

enum UsersExportFormat {
  excel,
  csv,
}

class UsersExportParams {
  const UsersExportParams({
    required this.users,
    required this.filter,
    required this.searchQuery,
    required this.locationQuery,
    this.role,
    this.createdFrom,
    this.createdTo,
  });

  final List<UserEntity> users;
  final UsersUiFilter filter;
  final String searchQuery;
  final String locationQuery;
  final String? role;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  String get activeFiltersSummary {
    final parts = <String>[];
    if (filter != UsersUiFilter.all) parts.add('Status: ${filter.name}');
    if (searchQuery.isNotEmpty) parts.add('Search: "$searchQuery"');
    if (locationQuery.isNotEmpty) parts.add('Location: "$locationQuery"');
    if (role != null && role!.isNotEmpty) parts.add('Role: $role');
    if (createdFrom != null) {
      parts.add('From: ${DateFormat('yyyy-MM-dd').format(createdFrom!)}');
    }
    if (createdTo != null) {
      parts.add('To: ${DateFormat('yyyy-MM-dd').format(createdTo!)}');
    }
    return parts.isEmpty ? 'None (All Users)' : parts.join(' | ');
  }
}

class UsersExportService {
  static const List<String> headers = [
    'User ID',
    'Username',
    'Full Name',
    'Email',
    'Phone',
    'Status',
    'Verification',
    'Role',
    'Country',
    'City',
    'Registration Date',
    'Followers',
    'Following',
    'Posts',
  ];

  static Future<void> exportUsers({
    required UsersExportParams params,
    required UsersExportFormat format,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    switch (format) {
      case UsersExportFormat.csv:
        final csvContent = _generateCsv(params);
        final bytes = utf8.encode(csvContent);
        await saveAndDownloadFile(
          bytes: bytes,
          fileName: 'users_export_$timestamp.csv',
          mimeType: 'text/csv; charset=utf-8',
        );
        break;

      case UsersExportFormat.excel:
        final xlsxBytes = _generateXlsx(params);
        await saveAndDownloadFile(
          bytes: xlsxBytes,
          fileName: 'users_export_$timestamp.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        break;
    }
  }

  static Future<void> exportSingleUser({
    required UserEntity user,
    required UsersExportFormat format,
  }) async {
    final cleanName = user.username.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileNamePrefix = '${cleanName}_details_$dateStr';

    switch (format) {
      case UsersExportFormat.csv:
        final csvContent = _generateSingleUserCsv(user);
        final bytes = utf8.encode(csvContent);
        await saveAndDownloadFile(
          bytes: bytes,
          fileName: '$fileNamePrefix.csv',
          mimeType: 'text/csv; charset=utf-8',
        );
        break;

      case UsersExportFormat.excel:
        final xlsxBytes = _generateSingleUserXlsx(user);
        await saveAndDownloadFile(
          bytes: xlsxBytes,
          fileName: '$fileNamePrefix.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        break;
    }
  }

  static String _roleLabel(UserEntity user) {
    if (user.roles.contains(UserRole.superAdmin)) return 'Super Admin';
    if (user.roles.includesAdmin) return 'Admin';
    if (user.roles.includesModerator) return 'Moderator';
    return 'User';
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  static List<String> _userToRow(UserEntity u) {
    return [
      u.id,
      u.username,
      u.fullName ?? '—',
      u.email ?? '—',
      u.phoneNumber ?? '—',
      u.isBanned ? 'Banned' : 'Active',
      u.isVerified ? 'Verified' : 'Unverified',
      _roleLabel(u),
      u.country ?? '—',
      u.city ?? '—',
      _formatDate(u.createdAt),
      u.followerCount.toString(),
      u.followingCount.toString(),
      u.postCount.toString(),
    ];
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      final escaped = val.replaceAll('"', '""');
      return '"$escaped"';
    }
    return val;
  }

  static String _generateCsv(UsersExportParams params) {
    final sb = StringBuffer();
    sb.write('\uFEFF');

    final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    sb.writeln('BimoBond Admin Dashboard - Users List Export');
    sb.writeln('Generated At:,$formattedNow');
    sb.writeln('Total Users Count:,${params.users.length}');
    sb.writeln('Applied Filters:,${_escapeCsv(params.activeFiltersSummary)}');
    sb.writeln();

    sb.writeln(headers.map(_escapeCsv).join(','));

    for (final user in params.users) {
      final row = _userToRow(user);
      sb.writeln(row.map(_escapeCsv).join(','));
    }

    return sb.toString();
  }



  // ── XLSX bulk export ────────────────────────────────────────────────────
  static List<int> _generateXlsx(UsersExportParams params) {
    final strings = <String>[];
    final strIdx = <String, int>{};
    int addStr(String v) => strIdx.putIfAbsent(v, () {
          final i = strings.length;
          strings.add(v);
          return i;
        });

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final ws = StringBuffer();
    ws.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="6" topLeftCell="A7" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>');
    // Column widths
    final colWidths = [14.0, 18.0, 18.0, 26.0, 16.0, 12.0, 14.0, 10.0, 14.0, 14.0, 18.0, 10.0, 10.0, 8.0];
    ws.write('<cols>');
    for (var c = 0; c < colWidths.length; c++) {
      ws.write('<col min="${c+1}" max="${c+1}" width="${colWidths[c]}" customWidth="1"/>');
    }
    ws.write('</cols><sheetData>');

    // Meta rows
    void metaRow(int r, String label, String val) {
      ws.write('<row r="$r"><c r="A$r" t="s"><v>${addStr(label)}</v></c>'
          '<c r="B$r" t="s"><v>${addStr(val)}</v></c></row>');
    }
    metaRow(1, 'BimoBond Admin Dashboard - Users Export', '');
    metaRow(2, 'Generated At', now);
    metaRow(3, 'Total Records', params.users.length.toString());
    metaRow(4, 'Applied Filters', params.activeFiltersSummary);
    ws.write('<row r="5"/>');

    // Header row
    ws.write('<row r="6">');
    for (var c = 0; c < headers.length; c++) {
      ws.write('<c r="${_col(c)}6" t="s" s="1"><v>${addStr(headers[c])}</v></c>');
    }
    ws.write('</row>');

    // Data rows
    for (var r = 0; r < params.users.length; r++) {
      final rowIdx = r + 7;
      final s = r.isOdd ? ' s="2"' : '';
      final cells = _userToRow(params.users[r]);
      ws.write('<row r="$rowIdx">');
      for (var c = 0; c < cells.length; c++) {
        ws.write('<c r="${_col(c)}$rowIdx" t="s"$s><v>${addStr(cells[c])}</v></c>');
      }
      ws.write('</row>');
    }
    ws.write('</sheetData>');
    final lastCol = _col(headers.length - 1);
    ws.write('<autoFilter ref="A6:${lastCol}6"/></worksheet>');

    return _buildZip('Users', ws.toString(), strings);
  }

  // ── XLSX single-user export ─────────────────────────────────────────────
  static List<int> _generateSingleUserXlsx(UserEntity user) {
    final strings = <String>[];
    final strIdx = <String, int>{};
    int addStr(String v) => strIdx.putIfAbsent(v, () {
          final i = strings.length;
          strings.add(v);
          return i;
        });

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final ws = StringBuffer();
    ws.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<cols>'
        '<col min="1" max="1" width="28" customWidth="1"/>'
        '<col min="2" max="2" width="40" customWidth="1"/>'
        '</cols><sheetData>');

    int row = 1;
    void titleRow(String v) {
      ws.write('<row r="$row"><c r="A$row" t="s" s="1"><v>${addStr(v)}</v></c></row>');
      row++;
    }
    void dataRow(String label, String val) {
      ws.write('<row r="$row">'
          '<c r="A$row" t="s" s="1"><v>${addStr(label)}</v></c>'
          '<c r="B$row" t="s"><v>${addStr(val)}</v></c>'
          '</row>');
      row++;
    }
    void blankRow() { ws.write('<row r="$row"/>'); row++; }

    String gps() {
      final loc = user.lastLocation;
      if (loc == null) return '—';
      final lat = loc.latitude; final lng = loc.longitude;
      return (lat == null || lng == null) ? '—' : '$lat, $lng';
    }
    String fmt(dynamic v) => v == null ? '—' : (v is DateTime ? _formatDate(v) : v.toString());

    titleRow('BimoBond Admin — User Profile Export: @${user.username}');
    dataRow('Generated At', now);
    dataRow('User ID', user.id);
    blankRow();

    titleRow('Profile Information');
    dataRow('Username', user.username);
    dataRow('Full Name', fmt(user.fullName));
    dataRow('Email', fmt(user.email));
    dataRow('Phone', fmt(user.phoneNumber));
    dataRow('Status', user.isBanned ? 'Banned' : 'Active');
    dataRow('Verification', user.isVerified ? 'Verified' : 'Unverified');
    dataRow('Role', _roleLabel(user));
    dataRow('Registration Date', fmt(user.createdAt));
    dataRow('Last Updated', fmt(user.updatedAt));
    blankRow();

    titleRow('Engagement');
    dataRow('Followers', user.followerCount.toString());
    dataRow('Following', user.followingCount.toString());
    dataRow('Posts', user.postCount.toString());
    dataRow('Total Likes', fmt(user.totalLikes));
    blankRow();

    titleRow('Location');
    dataRow('Country', fmt(user.country));
    dataRow('Region', fmt(user.region));
    dataRow('City', fmt(user.city));
    dataRow('GPS Coordinates', gps());
    blankRow();

    titleRow('Privacy & Permissions');
    dataRow('Private Profile', user.isPrivate ? 'Yes' : 'No');
    dataRow('Allow Comments', user.allowComments ? 'Yes' : 'No');
    dataRow('Allow Direct Msgs', user.allowDirectMsgs ? 'Yes' : 'No');
    dataRow('Can Post', user.canPost ? 'Yes' : 'No');
    blankRow();

    titleRow('Social Media Links');
    dataRow('Instagram', fmt(user.instagramUrl));
    dataRow('YouTube', fmt(user.youtubeUrl));
    dataRow('TikTok', fmt(user.tiktokUrl));
    dataRow('Twitter', fmt(user.twitterUrl));
    dataRow('Website', fmt(user.websiteUrl));

    ws.write('</sheetData></worksheet>');
    return _buildZip('User Profile', ws.toString(), strings);
  }

  // ── Shared XLSX builder ─────────────────────────────────────────────────
  static List<int> _buildZip(String sheetName, String sheetXml, List<String> strings) {
    final ssSb = StringBuffer();
    ssSb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' count="${strings.length}" uniqueCount="${strings.length}">');
    for (final s in strings) {
      ssSb.write('<si><t xml:space="preserve">${_xmlEsc(s)}</t></si>');
    }
    ssSb.write('</sst>');

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
        // Fills — indices 0 & 1 are RESERVED by OOXML spec
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
        '<diagonal/></border>'
        '</borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="3">'
        // 0 – default data cell
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        // 1 – header cell (bold white text on navy background)
        '<xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="center" wrapText="0"/></xf>'
        // 2 – stripe data cell (light blue-gray background)
        '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        '</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';

    final workbookXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="$sheetName" sheetId="1" r:id="rId1"/></sheets>'
        '</workbook>';

    const contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>';
    const rootRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>';
    const wbRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>';

    final archive = Archive();
    void addPart(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile.bytes(name, bytes));
    }
    addPart('[Content_Types].xml', contentTypes);
    addPart('_rels/.rels', rootRels);
    addPart('xl/workbook.xml', workbookXml);
    addPart('xl/_rels/workbook.xml.rels', wbRels);
    addPart('xl/worksheets/sheet1.xml', sheetXml);
    addPart('xl/sharedStrings.xml', ssSb.toString());
    addPart('xl/styles.xml', stylesXml);
    return ZipEncoder().encode(archive);
  }

  static String _col(int index) {
    var result = '';
    var n = index;
    do {
      result = String.fromCharCode(65 + (n % 26)) + result;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return result;
  }

  static String _xmlEsc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');


  static String _generateSingleUserCsv(UserEntity user) {
    final sb = StringBuffer();
    sb.write('\uFEFF');
    final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    sb.writeln('BimoBond Admin Dashboard - User Detailed Profile Report');
    sb.writeln('Export Date:,$formattedNow');
    sb.writeln('User ID:,${_escapeCsv(user.id)}');
    sb.writeln('Username:,${_escapeCsv(user.username)}');
    sb.writeln();

    void addSection(String title, Map<String, dynamic> data) {
      sb.writeln('=== ${_escapeCsv(title)} ===');
      sb.writeln('Field,Value');
      data.forEach((k, v) {
        final val = v == null ? '—' : (v is DateTime ? _formatDate(v) : v.toString());
        sb.writeln('${_escapeCsv(k)},${_escapeCsv(val)}');
      });
      sb.writeln();
    }

    String formatGps(UserEntity u) {
      if (u.lastLocation == null) return '—';
      final lat = u.lastLocation!.latitude;
      final lng = u.lastLocation!.longitude;
      if (lat == null || lng == null) return '—';
      return '$lat, $lng';
    }

    addSection('1. Profile Information', {
      'User ID': user.id,
      'Firebase UID': user.firebaseUid,
      'Username': user.username,
      'Full Name': user.fullName,
      'Email': user.email,
      'Phone Number': user.phoneNumber,
      'Bio': user.bio,
      'Gender': user.gender,
      'Date of Birth': user.dateOfBirth,
      'Account Status': user.isBanned ? 'Banned' : 'Active',
      'Ban Reason': user.banReason,
      'Banned Until': user.bannedUntil,
      'Verification Status': user.isVerified ? 'Verified' : 'Unverified',
      'Verification Badge': user.verificationBadge,
      'Role': _roleLabel(user),
      'Creator Category': user.creatorCategory,
      'Account Type': user.accountType,
      'Language': user.language,
      'Theme': user.theme,
      'Registration Date': user.createdAt,
      'Last Updated': user.updatedAt,
    });

    addSection('2. Engagement Statistics', {
      'Followers': user.followerCount,
      'Following': user.followingCount,
      'Posts': user.postCount,
      'Total Likes': user.totalLikes,
    });

    addSection('3. Location & GPS', {
      'Country': user.country,
      'Region': user.region,
      'City': user.city,
      'GPS Coordinates': formatGps(user),
    });

    if (user.wallet != null) {
      addSection('4. Wallet Information', {
        'Wallet ID': user.wallet?.id,
        'Coins Balance': user.wallet?.balanceCoins,
      });
    }

    addSection('5. Privacy & Permissions', {
      'Private Profile': user.isPrivate,
      'Profile Locked': user.isProfileLocked,
      'Allow Comments': user.allowComments,
      'Allow Direct Msgs': user.allowDirectMsgs,
      'Message Permission': user.messagePermission.name,
      'Can Post': user.canPost,
      'Discoverable': user.discoverable,
      'Suggest To Contacts': user.suggestToContacts,
      'Show Activity Status': user.showActivityStatus,
      'Restricted Mode': user.restrictedMode,
      'Show Shop On Profile': user.showShopOnProfile,
      'Allow Duets Default': user.allowDuetsDefault,
      'Allow Stitch Default': user.allowStitchDefault,
      'Allow Downloads Default': user.allowDownloadsDefault,
      'Allow Reposts Default': user.allowRepostsDefault,
    });

    addSection('6. Social Media Links', {
      'Instagram': user.instagramUrl,
      'YouTube': user.youtubeUrl,
      'TikTok': user.tiktokUrl,
      'Twitter': user.twitterUrl,
      'Snapchat': user.snapchatUrl,
      'Spotify': user.spotifyUrl,
      'Website': user.websiteUrl,
    });

    return sb.toString();
  }



}
