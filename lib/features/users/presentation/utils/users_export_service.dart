import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/file_downloader.dart';
import '../../../../injection_container.dart' as di;
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_reports_usecase.dart';
import '../../../security_logs/data/datasources/user_violations_remote_datasource.dart';
import '../../../security_logs/domain/entities/log_entity.dart';
import '../../../security_logs/domain/usecases/get_logs_usecase.dart';
import '../../../user_activity/domain/usecases/get_user_activity_devices.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_post_entity.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/get_user_posts.dart';
import '../widgets/user_account_risk_section.dart';
import '../users_ui_filter.dart';

enum UsersExportFormat {
  excel,
  csv,
  pdf,
}

class _XlsxSheet {
  const _XlsxSheet(this.name, this.xml);
  final String name;
  final String xml;
}

class UserAdminReportData {
  const UserAdminReportData({
    required this.user,
    required this.fullUserDetail,
    required this.adminActions,
    required this.auditLogs,
    required this.violations,
    required this.reportsReceived,
    required this.userPosts,
    required this.devices,
    required this.safetyScore,
    required this.riskLevel,
    required this.fetchedAt,
  });

  final UserEntity user;
  final UserDetailEntity? fullUserDetail;
  final List<LogEntity> adminActions;
  final List<LogEntity> auditLogs;
  final List<LogEntity> violations;
  final List<ReportEntity> reportsReceived;
  final List<UserPostEntity> userPosts;
  final List<Map<String, dynamic>> devices;
  final int safetyScore;
  final AccountRiskLevel riskLevel;
  final DateTime fetchedAt;
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

  /// Bulk Users Export (CSV / Excel / PDF)
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

      case UsersExportFormat.pdf:
        final pdfBytes = await _generateBulkUsersPdf(params);
        await saveAndDownloadFile(
          bytes: pdfBytes,
          fileName: 'users_export_$timestamp.pdf',
          mimeType: 'application/pdf',
        );
        break;
    }
  }

  /// Single User Full Administrative Report Export (Excel, CSV, PDF)
  static Future<void> exportSingleUser({
    required UserEntity user,
    required UsersExportFormat format,
  }) async {
    final cleanName = user.username.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileNamePrefix = '${cleanName}_administrative_report_$dateStr';

    final reportData = await fetchAdminReportData(user);

    switch (format) {
      case UsersExportFormat.csv:
        final csvContent = _generateSingleUserCsv(reportData);
        final bytes = utf8.encode(csvContent);
        await saveAndDownloadFile(
          bytes: bytes,
          fileName: '$fileNamePrefix.csv',
          mimeType: 'text/csv; charset=utf-8',
        );
        break;

      case UsersExportFormat.excel:
        final xlsxBytes = _generateSingleUserXlsx(reportData);
        await saveAndDownloadFile(
          bytes: xlsxBytes,
          fileName: '$fileNamePrefix.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        break;

      case UsersExportFormat.pdf:
        final pdfBytes = await _generateSingleUserPdf(reportData);
        await saveAndDownloadFile(
          bytes: pdfBytes,
          fileName: '$fileNamePrefix.pdf',
          mimeType: 'application/pdf',
        );
        break;
    }
  }

  /// Data fetcher for complete single user administrative report
  static Future<UserAdminReportData> fetchAdminReportData(UserEntity user) async {
    UserDetailEntity? fullDetail;
    List<LogEntity> auditLogs = [];
    List<LogEntity> adminActions = [];
    List<LogEntity> violations = [];
    List<ReportEntity> reportsReceived = [];
    List<UserPostEntity> posts = [];
    List<Map<String, dynamic>> devicesList = [];

    // 1. Fetch full user detail
    try {
      fullDetail = await di.sl<GetUserById>()(user.id);
    } catch (_) {}

    final targetUser = fullDetail?.user ?? user;

    // 2. Fetch logs & admin actions
    try {
      final logsRes = await di.sl<GetLogsUseCase>()(LogsQuery(
        userId: user.id,
        limit: 100,
      ));
      auditLogs = logsRes.data;

      final actionsRes = await di.sl<GetLogsUseCase>()(LogsQuery(
        userId: user.id,
        category: 'ADMIN',
        limit: 100,
      ));
      adminActions = actionsRes.data;
    } catch (_) {}

    // 3. Fetch violations
    try {
      final violsRes = await UserViolationsRemoteDataSourceImpl(di.sl())
          .getUserViolations(userId: user.id, limit: 100);
      violations = violsRes.data;
    } catch (_) {}

    // 4. Fetch reports received against user
    try {
      final reportsRes = await di.sl<GetReports>()(
        reportedUserId: user.id,
        limit: 100,
      );
      reportsReceived = reportsRes.reports;
    } catch (_) {}

    // 5. Fetch user posts
    try {
      final postsRes = await di.sl<GetUserPosts>()(user.id, page: 1, limit: 50);
      posts = postsRes.data;
    } catch (_) {}

    // 6. Devices
    if (fullDetail?.devices != null) {
      devicesList.addAll(fullDetail!.devices!);
    }
    try {
      final devRes = await di.sl<GetUserActivityDevices>()(user.id, page: 1, limit: 50);
      for (final dev in devRes.items) {
        if (!devicesList.any((d) => d['deviceId'] == dev.deviceId || d['id'] == dev.id)) {
          devicesList.add({
            'id': dev.id,
            'deviceId': dev.deviceId,
            'deviceModel': dev.deviceName ?? dev.deviceType,
            'osVersion': dev.osVersion ?? dev.appVersion,
            'ipAddress': dev.lastActiveIp,
            'lastActiveAt': dev.lastActiveAt?.toIso8601String(),
          });
        }
      }
    } catch (_) {}

    // Account risk & safety score
    final reportsCount = reportsReceived.length;
    final violsCount = violations.length;
    AccountRiskLevel risk;
    if (targetUser.isBanned || reportsCount >= 5 || violsCount >= 3) {
      risk = AccountRiskLevel.high;
    } else if (reportsCount > 0 || violsCount > 0 || targetUser.isProfileLocked) {
      risk = AccountRiskLevel.medium;
    } else {
      risk = AccountRiskLevel.low;
    }

    final penalties = (reportsCount * 5) + (violsCount * 20) + (targetUser.isBanned ? 40 : 0);
    final score = (100 - penalties).clamp(0, 100);

    return UserAdminReportData(
      user: targetUser,
      fullUserDetail: fullDetail,
      adminActions: adminActions,
      auditLogs: auditLogs,
      violations: violations,
      reportsReceived: reportsReceived,
      userPosts: posts,
      devices: devicesList,
      safetyScore: score,
      riskLevel: risk,
      fetchedAt: DateTime.now(),
    );
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

  // ── CSV Bulk Users Export ────────────────────────────────────────────────
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

  // ── ENTERPRISE PDF SINGLE USER ADMINISTRATIVE REPORT ─────────────────────
  static Future<List<int>> _generateSingleUserPdf(UserAdminReportData report) async {
    final pdf = pw.Document();
    final user = report.user;
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(report.fetchedAt);
    final reportRefId = 'RPT-${user.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').takeMax(8).toUpperCase()}';

    PdfColor riskColor;
    switch (report.riskLevel) {
      case AccountRiskLevel.high:
        riskColor = PdfColors.red700;
        break;
      case AccountRiskLevel.medium:
        riskColor = PdfColors.orange700;
        break;
      case AccountRiskLevel.low:
        riskColor = PdfColors.green700;
        break;
    }

    const navyColor = PdfColors.blueGrey900;
    const accentBlue = PdfColors.blue700;

    pw.Widget buildEnterpriseSectionHeader(String title) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const pw.BoxDecoration(
          color: navyColor,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget buildInfoRow(String label, String value, {bool isAccent = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
        ),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isAccent ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isAccent ? accentBlue : PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final avatarInitial = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: navyColor,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BIMOBOND ENTERPRISE ADMIN SYSTEM',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'EXECUTIVE USER ADMINISTRATIVE REPORT  •  Ref: $reportRefId',
                      style: const pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.red800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'STRICTLY CONFIDENTIAL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BimoBond Platform Security & Integrity Audit Record  •  Exported: $nowStr',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Enterprise User Identity Box (Stripe Dashboard Style)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    // Avatar Badge Circle
                    pw.Container(
                      width: 42,
                      height: 42,
                      decoration: const pw.BoxDecoration(
                        color: navyColor,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          avatarInitial,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '@${user.username}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          user.fullName ?? 'Name Not Provided',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'User ID: ${user.id}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      children: [
                        // Status Badge
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: user.isBanned ? PdfColors.red700 : PdfColors.green700,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            user.isBanned ? 'BANNED' : 'ACTIVE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        // Risk Badge
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: riskColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            '${report.riskLevel.name.toUpperCase()} RISK',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        'SAFETY INDEX: ${report.safetyScore} / 100',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // Executive KPI Stat Cards (4 Columns)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfKpiCard('Followers', user.followerCount.toString(), PdfColors.blue700),
              _pdfKpiCard('Following', user.followingCount.toString(), PdfColors.teal700),
              _pdfKpiCard('Posts Published', user.postCount.toString(), PdfColors.purple700),
              _pdfKpiCard(
                'Coins Balance',
                (report.fullUserDetail?.wallet?.balanceCoins ?? user.wallet?.balanceCoins ?? 0).toString(),
                PdfColors.amber700,
              ),
            ],
          ),

          // 1. Profile Information
          buildEnterpriseSectionHeader('1. Primary Account & Identity Profile'),
          buildInfoRow('User ID', user.id),
          buildInfoRow('Firebase UID', user.firebaseUid ?? '—'),
          buildInfoRow('Username', '@${user.username}', isAccent: true),
          buildInfoRow('Full Name', user.fullName ?? '—'),
          buildInfoRow('Email Address', user.email ?? '—'),
          buildInfoRow('Phone Number', user.phoneNumber ?? '—'),
          buildInfoRow('Biography / Bio', user.bio ?? '—'),
          buildInfoRow('Account Status', user.isBanned ? 'BANNED' : 'ACTIVE'),
          if (user.isBanned) buildInfoRow('Ban Reason', user.banReason ?? '—'),
          if (user.isBanned) buildInfoRow('Banned Until', _formatDate(user.bannedUntil)),
          buildInfoRow('Verification Badge', user.isVerified ? 'VERIFIED' : 'UNVERIFIED'),
          buildInfoRow('Administrative Role', _roleLabel(user)),
          buildInfoRow('Creator Category', user.creatorCategory ?? '—'),
          buildInfoRow('Account Type', user.accountType ?? '—'),
          buildInfoRow('Country / City', '${user.country ?? "—"} / ${user.city ?? "—"}'),
          buildInfoRow('Registration Date', _formatDate(user.createdAt)),
          buildInfoRow('Last Active / Seen', _formatDate(user.lastActive ?? user.updatedAt)),
          buildInfoRow('Realtime Presence', user.isOnlineOverride == true ? 'Online' : 'Offline'),

          // 2. Moderation History & Actions
          buildEnterpriseSectionHeader('2. Administrative Moderation Timeline (${report.adminActions.length})'),
          if (report.adminActions.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('No administrative actions recorded.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Date & Time', 'Administrator', 'Role', 'Action Type', 'Reason / Target'],
              data: report.adminActions.map((a) {
                final adminName = a.displayUser.isNotEmpty ? a.displayUser : (a.userName ?? a.actorRole ?? 'Admin');
                return [
                  _formatDate(a.createdAt),
                  adminName,
                  a.actorRole ?? 'ADMIN',
                  a.action,
                  a.description ?? a.displayTarget ?? '—',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: navyColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),

          // 3. Violations Log
          buildEnterpriseSectionHeader('3. Community Guidelines Violations (${report.violations.length})'),
          if (report.violations.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('No guideline violations recorded on account.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Date & Time', 'Action', 'Category', 'Description / Target', 'Actor Role'],
              data: report.violations.map((v) => [
                _formatDate(v.createdAt),
                v.action,
                v.category,
                v.description ?? v.displayTarget ?? '—',
                v.actorRole ?? 'SYSTEM',
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),

          // 4. Reports Received
          buildEnterpriseSectionHeader('4. Reports Filed Against User (${report.reportsReceived.length})'),
          if (report.reportsReceived.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('No user reports on record.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Date & Time', 'Reporter', 'Reason', 'Status', 'Target Type'],
              data: report.reportsReceived.map((r) => [
                _formatDate(r.createdAt),
                '@${r.reporter?.username ?? 'Anonymous'}',
                r.reason,
                r.status,
                r.targetType,
              ]).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),

          // 5. Registered Devices & Sessions
          buildEnterpriseSectionHeader('5. Registered Devices & Active Sessions (${report.devices.length})'),
          if (report.devices.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('No registered sessions or devices recorded.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Device ID', 'Model', 'OS / Platform', 'IP Address', 'Last Active'],
              data: report.devices.map((d) {
                final devId = d['deviceId']?.toString() ?? d['id']?.toString() ?? '—';
                final model = d['deviceModel']?.toString() ?? d['model']?.toString() ?? '—';
                final os = d['osVersion']?.toString() ?? d['platform']?.toString() ?? '—';
                final ip = d['ipAddress']?.toString() ?? d['ip']?.toString() ?? '—';
                final lastActive = d['lastActiveAt'] != null
                    ? _formatDate(DateTime.tryParse(d['lastActiveAt'].toString()))
                    : '—';
                return [devId, model, os, ip, lastActive];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfKpiCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 122,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ── ENTERPRISE PDF BULK USERS DIRECTORY REPORT ───────────────────────────
  static Future<List<int>> _generateBulkUsersPdf(UsersExportParams params) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final totalCount = params.users.length;
    final verifiedCount = params.users.where((u) => u.isVerified).length;
    final bannedCount = params.users.where((u) => u.isBanned).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BIMOBOND ENTERPRISE ADMIN SYSTEM',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'USERS DIRECTORY REPORT  •  Generated: $nowStr',
                      style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    _pdfMiniTag('TOTAL: $totalCount', PdfColors.blue700),
                    pw.SizedBox(width: 4),
                    _pdfMiniTag('VERIFIED: $verifiedCount', PdfColors.green700),
                    pw.SizedBox(width: 4),
                    _pdfMiniTag('BANNED: $bannedCount', PdfColors.red700),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Applied Filters: ${params.activeFiltersSummary}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: params.users.map(_userToRow).toList(),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfMiniTag(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ── ENTERPRISE XLSX BULK USERS EXPORT ─────────────────────────────────────
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
        '<sheetViews><sheetView workbookViewId="0" showGridLines="1">'
        '<pane ySplit="6" topLeftCell="A7" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>');

    // Dynamic auto column widths
    final colWidths = List<double>.filled(headers.length, 12.0);
    for (var c = 0; c < headers.length; c++) {
      colWidths[c] = headers[c].length.toDouble() + 4.0;
    }
    for (final user in params.users) {
      final rowCells = _userToRow(user);
      for (var c = 0; c < rowCells.length && c < colWidths.length; c++) {
        final len = rowCells[c].length.toDouble() + 4.0;
        if (len > colWidths[c]) colWidths[c] = len;
      }
    }

    ws.write('<cols>');
    for (var c = 0; c < colWidths.length; c++) {
      final w = colWidths[c].clamp(10.0, 45.0);
      ws.write('<col min="${c + 1}" max="${c + 1}" width="$w" customWidth="1"/>');
    }
    ws.write('</cols><sheetData>');

    void metaRow(int r, String label, String val, {int style = 13}) {
      ws.write('<row r="$r">'
          '<c r="A$r" t="s" s="12"><v>${addStr(label)}</v></c>'
          '<c r="B$r" t="s" s="$style"><v>${addStr(val)}</v></c>'
          '</row>');
    }

    ws.write('<row r="1" ht="28" customHeight="1">'
        '<c r="A1" t="s" s="3"><v>${addStr('BimoBond Enterprise Admin System — Users Directory Export')}</v></c>'
        '</row>');
    metaRow(2, 'Generated At', now);
    metaRow(3, 'Total Records', '${params.users.length} Users');
    metaRow(4, 'Applied Filters', params.activeFiltersSummary);
    ws.write('<row r="5"/>');

    // Header row (Row 6)
    ws.write('<row r="6" ht="22" customHeight="1">');
    for (var c = 0; c < headers.length; c++) {
      ws.write('<c r="${_col(c)}6" t="s" s="1"><v>${addStr(headers[c])}</v></c>');
    }
    ws.write('</row>');

    // Data rows
    for (var r = 0; r < params.users.length; r++) {
      final rowIdx = r + 7;
      final u = params.users[r];
      final cells = _userToRow(u);

      ws.write('<row r="$rowIdx">');
      for (var c = 0; c < cells.length; c++) {
        int cellStyle = r.isOdd ? 2 : 0;
        final cellVal = cells[c];

        if (c == 5) {
          cellStyle = u.isBanned ? 8 : 7;
        } else if (c == 6) {
          cellStyle = u.isVerified ? 7 : 0;
        } else if (c >= 11) {
          cellStyle = 10;
        }

        ws.write('<c r="${_col(c)}$rowIdx" t="s" s="$cellStyle"><v>${addStr(cellVal)}</v></c>');
      }
      ws.write('</row>');
    }

    ws.write('</sheetData>');
    final lastCol = _col(headers.length - 1);
    ws.write('<autoFilter ref="A6:${lastCol}6"/></worksheet>');

    return _buildZip('Users Directory', ws.toString(), strings);
  }

  // ── ENTERPRISE XLSX SINGLE USER REPORT EXPORT ────────────────────────────
  static List<int> _generateSingleUserXlsx(UserAdminReportData report) {
    final strings = <String>[];
    final strIdx = <String, int>{};
    int addStr(String v) => strIdx.putIfAbsent(v, () {
          final i = strings.length;
          strings.add(v);
          return i;
        });

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(report.fetchedAt);
    final user = report.user;
    final fmt = (dynamic v) => v == null ? '—' : (v is DateTime ? _formatDate(v) : v.toString());

    // Sheet 1: Executive Overview & Profile
    final ws1 = StringBuffer();
    ws1.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0" showGridLines="1"/></sheetViews>'
        '<cols>'
        '<col min="1" max="1" width="30" customWidth="1"/>'
        '<col min="2" max="2" width="48" customWidth="1"/>'
        '<col min="3" max="3" width="22" customWidth="1"/>'
        '<col min="4" max="4" width="22" customWidth="1"/>'
        '</cols><sheetData>');

    int row = 1;
    void bannerRow(String title) {
      ws1.write('<row r="$row" ht="28" customHeight="1">'
          '<c r="A$row" t="s" s="3"><v>${addStr(title)}</v></c>'
          '</row>');
      row++;
    }

    void sectionHeaderRow(String v) {
      ws1.write('<row r="$row" ht="22" customHeight="1">'
          '<c r="A$row" t="s" s="4"><v>${addStr(v)}</v></c>'
          '<c r="B$row" t="s" s="4"><v>${addStr('')}</v></c>'
          '</row>');
      row++;
    }

    void dataRow(String label, String val, {int valStyle = 0}) {
      ws1.write('<row r="$row">'
          '<c r="A$row" t="s" s="12"><v>${addStr(label)}</v></c>'
          '<c r="B$row" t="s" s="$valStyle"><v>${addStr(val)}</v></c>'
          '</row>');
      row++;
    }

    void blankRow() {
      ws1.write('<row r="$row"/>');
      row++;
    }

    String gps() {
      final loc = user.lastLocation;
      if (loc == null) return '—';
      final lat = loc.latitude;
      final lng = loc.longitude;
      return (lat == null || lng == null) ? '—' : '$lat, $lng';
    }

    bannerRow('BIMOBOND ENTERPRISE ADMIN REPORT: @${user.username}');

    ws1.write('<row r="$row">'
        '<c r="A$row" t="s" s="12"><v>${addStr('Report Export Date')}</v></c>'
        '<c r="B$row" t="s" s="13"><v>${addStr(now)}</v></c>'
        '</row>');
    row++;
    ws1.write('<row r="$row">'
        '<c r="A$row" t="s" s="12"><v>${addStr('Target User ID')}</v></c>'
        '<c r="B$row" t="s" s="13"><v>${addStr(user.id)}</v></c>'
        '</row>');
    row++;
    blankRow();

    // Executive KPI Summary Grid
    int riskStyle = 7;
    if (report.riskLevel == AccountRiskLevel.high) {
      riskStyle = 8;
    } else if (report.riskLevel == AccountRiskLevel.medium) {
      riskStyle = 9;
    }

    ws1.write('<row r="$row" ht="18" customHeight="1">'
        '<c r="A$row" t="s" s="5"><v>${addStr('RISK ASSESSMENT LEVEL')}</v></c>'
        '<c r="B$row" t="s" s="5"><v>${addStr('CALCULATED SAFETY SCORE')}</v></c>'
        '<c r="C$row" t="s" s="5"><v>${addStr('ACCOUNT STATUS')}</v></c>'
        '<c r="D$row" t="s" s="5"><v>${addStr('TOTAL POSTS')}</v></c>'
        '</row>');
    row++;
    ws1.write('<row r="$row" ht="24" customHeight="1">'
        '<c r="A$row" t="s" s="$riskStyle"><v>${addStr('${report.riskLevel.name.toUpperCase()} RISK')}</v></c>'
        '<c r="B$row" t="s" s="6"><v>${addStr('${report.safetyScore} / 100')}</v></c>'
        '<c r="C$row" t="s" s="${user.isBanned ? 8 : 7}"><v>${addStr(user.isBanned ? 'BANNED' : 'ACTIVE')}</v></c>'
        '<c r="D$row" t="s" s="6"><v>${addStr(user.postCount.toString())}</v></c>'
        '</row>');
    row++;
    blankRow();

    sectionHeaderRow('1. Identity & Profile Information');
    dataRow('Username', user.username);
    dataRow('Full Name', fmt(user.fullName));
    dataRow('Email', fmt(user.email));
    dataRow('Phone Number', fmt(user.phoneNumber));
    dataRow('Account Status', user.isBanned ? 'Banned' : 'Active', valStyle: user.isBanned ? 8 : 7);
    if (user.isBanned) dataRow('Ban Reason', fmt(user.banReason));
    if (user.isBanned) dataRow('Banned Until', fmt(user.bannedUntil));
    dataRow('Verification Status', user.isVerified ? 'Verified' : 'Unverified', valStyle: user.isVerified ? 7 : 0);
    dataRow('Verification Badge', fmt(user.verificationBadge));
    dataRow('Role', _roleLabel(user));
    dataRow('Creator Category', fmt(user.creatorCategory));
    dataRow('Account Type', fmt(user.accountType));
    dataRow('Registration Date', fmt(user.createdAt));
    dataRow('Last Active / Seen', fmt(user.lastActive ?? user.updatedAt));
    dataRow('Online Status', user.isOnlineOverride == true ? 'Online' : 'Offline');
    blankRow();

    sectionHeaderRow('2. Engagement & Financial Wallet');
    dataRow('Followers', user.followerCount.toString(), valStyle: 10);
    dataRow('Following', user.followingCount.toString(), valStyle: 10);
    dataRow('Posts Published', user.postCount.toString(), valStyle: 10);
    dataRow('Total Likes', fmt(user.totalLikes), valStyle: 10);
    dataRow('Coins Balance', (report.fullUserDetail?.wallet?.balanceCoins ?? user.wallet?.balanceCoins ?? 0).toString(), valStyle: 10);
    dataRow('Wallet ID', report.fullUserDetail?.wallet?.id ?? user.wallet?.id ?? '—');
    blankRow();

    sectionHeaderRow('3. Location & Privacy Settings');
    dataRow('Country / Region / City', '${user.country ?? "—"} / ${user.region ?? "—"} / ${user.city ?? "—"}');
    dataRow('GPS Coordinates', gps());
    dataRow('Private Profile', user.isPrivate ? 'Yes' : 'No');
    dataRow('Profile Locked', user.isProfileLocked ? 'Yes' : 'No');
    dataRow('Allow Comments', user.allowComments ? 'Yes' : 'No');
    dataRow('Allow Direct Msgs', user.allowDirectMsgs ? 'Yes' : 'No');
    dataRow('Can Post', user.canPost ? 'Yes' : 'No');
    blankRow();

    sectionHeaderRow('4. Social Media External Links');
    dataRow('Instagram', fmt(user.instagramUrl));
    dataRow('YouTube', fmt(user.youtubeUrl));
    dataRow('TikTok', fmt(user.tiktokUrl));
    dataRow('Twitter', fmt(user.twitterUrl));
    dataRow('Website', fmt(user.websiteUrl));

    ws1.write('</sheetData></worksheet>');

    // Sheet 2: Admin Actions
    final ws2 = StringBuffer();
    ws2.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0" showGridLines="1"/></sheetViews>'
        '<cols>'
        '<col min="1" max="1" width="20" customWidth="1"/>'
        '<col min="2" max="2" width="24" customWidth="1"/>'
        '<col min="3" max="3" width="14" customWidth="1"/>'
        '<col min="4" max="4" width="20" customWidth="1"/>'
        '<col min="5" max="5" width="40" customWidth="1"/>'
        '<col min="6" max="6" width="35" customWidth="1"/>'
        '</cols><sheetData>');
    ws2.write('<row r="1" ht="22" customHeight="1">'
        '<c r="A1" t="s" s="1"><v>${addStr('Date & Time')}</v></c>'
        '<c r="B1" t="s" s="1"><v>${addStr('Administrator')}</v></c>'
        '<c r="C1" t="s" s="1"><v>${addStr('Role')}</v></c>'
        '<c r="D1" t="s" s="1"><v>${addStr('Action Type')}</v></c>'
        '<c r="E1" t="s" s="1"><v>${addStr('Reason / Description')}</v></c>'
        '<c r="F1" t="s" s="1"><v>${addStr('Metadata / Changes')}</v></c>'
        '</row>');
    for (var i = 0; i < report.adminActions.length; i++) {
      final a = report.adminActions[i];
      final rIdx = i + 2;
      final adminName = a.displayUser.isNotEmpty ? a.displayUser : (a.userName ?? a.actorRole ?? 'Admin');
      final s = i.isOdd ? 2 : 0;
      ws2.write('<row r="$rIdx">'
          '<c r="A$rIdx" t="s" s="$s"><v>${addStr(_formatDate(a.createdAt))}</v></c>'
          '<c r="B$rIdx" t="s" s="$s"><v>${addStr(adminName)}</v></c>'
          '<c r="C$rIdx" t="s" s="$s"><v>${addStr(a.actorRole ?? "ADMIN")}</v></c>'
          '<c r="D$rIdx" t="s" s="$s"><v>${addStr(a.action)}</v></c>'
          '<c r="E$rIdx" t="s" s="$s"><v>${addStr(a.description ?? a.displayTarget ?? "—")}</v></c>'
          '<c r="F$rIdx" t="s" s="$s"><v>${addStr(a.meta != null ? a.meta.toString() : "—")}</v></c>'
          '</row>');
    }
    ws2.write('</sheetData></worksheet>');

    // Sheet 3: Violations
    final ws3 = StringBuffer();
    ws3.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0" showGridLines="1"/></sheetViews>'
        '<cols>'
        '<col min="1" max="1" width="20" customWidth="1"/>'
        '<col min="2" max="2" width="18" customWidth="1"/>'
        '<col min="3" max="3" width="18" customWidth="1"/>'
        '<col min="4" max="4" width="40" customWidth="1"/>'
        '<col min="5" max="5" width="16" customWidth="1"/>'
        '</cols><sheetData>');
    ws3.write('<row r="1" ht="22" customHeight="1">'
        '<c r="A1" t="s" s="1"><v>${addStr('Date & Time')}</v></c>'
        '<c r="B1" t="s" s="1"><v>${addStr('Action')}</v></c>'
        '<c r="C1" t="s" s="1"><v>${addStr('Category')}</v></c>'
        '<c r="D1" t="s" s="1"><v>${addStr('Description / Target')}</v></c>'
        '<c r="E1" t="s" s="1"><v>${addStr('Actor Role')}</v></c>'
        '</row>');
    for (var i = 0; i < report.violations.length; i++) {
      final v = report.violations[i];
      final rIdx = i + 2;
      final s = i.isOdd ? 2 : 0;
      ws3.write('<row r="$rIdx">'
          '<c r="A$rIdx" t="s" s="$s"><v>${addStr(_formatDate(v.createdAt))}</v></c>'
          '<c r="B$rIdx" t="s" s="$s"><v>${addStr(v.action)}</v></c>'
          '<c r="C$rIdx" t="s" s="$s"><v>${addStr(v.category)}</v></c>'
          '<c r="D$rIdx" t="s" s="$s"><v>${addStr(v.description ?? v.displayTarget ?? "—")}</v></c>'
          '<c r="E$rIdx" t="s" s="$s"><v>${addStr(v.actorRole ?? "SYSTEM")}</v></c>'
          '</row>');
    }
    ws3.write('</sheetData></worksheet>');

    // Sheet 4: Devices & Sessions
    final ws4 = StringBuffer();
    ws4.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0" showGridLines="1"/></sheetViews>'
        '<cols>'
        '<col min="1" max="1" width="30" customWidth="1"/>'
        '<col min="2" max="2" width="22" customWidth="1"/>'
        '<col min="3" max="3" width="20" customWidth="1"/>'
        '<col min="4" max="4" width="22" customWidth="1"/>'
        '<col min="5" max="5" width="22" customWidth="1"/>'
        '</cols><sheetData>');
    ws4.write('<row r="1" ht="22" customHeight="1">'
        '<c r="A1" t="s" s="1"><v>${addStr('Device ID')}</v></c>'
        '<c r="B1" t="s" s="1"><v>${addStr('Model')}</v></c>'
        '<c r="C1" t="s" s="1"><v>${addStr('OS / Platform')}</v></c>'
        '<c r="D1" t="s" s="1"><v>${addStr('IP Address')}</v></c>'
        '<c r="E1" t="s" s="1"><v>${addStr('Last Active')}</v></c>'
        '</row>');
    for (var i = 0; i < report.devices.length; i++) {
      final d = report.devices[i];
      final rIdx = i + 2;
      final s = i.isOdd ? 2 : 0;
      final devId = d['deviceId']?.toString() ?? d['id']?.toString() ?? '—';
      final model = d['deviceModel']?.toString() ?? d['model']?.toString() ?? '—';
      final os = d['osVersion']?.toString() ?? d['platform']?.toString() ?? '—';
      final ip = d['ipAddress']?.toString() ?? d['ip']?.toString() ?? '—';
      final lastActive = d['lastActiveAt'] != null
          ? _formatDate(DateTime.tryParse(d['lastActiveAt'].toString()))
          : '—';
      ws4.write('<row r="$rIdx">'
          '<c r="A$rIdx" t="s" s="$s"><v>${addStr(devId)}</v></c>'
          '<c r="B$rIdx" t="s" s="$s"><v>${addStr(model)}</v></c>'
          '<c r="C$rIdx" t="s" s="$s"><v>${addStr(os)}</v></c>'
          '<c r="D$rIdx" t="s" s="$s"><v>${addStr(ip)}</v></c>'
          '<c r="E$rIdx" t="s" s="$s"><v>${addStr(lastActive)}</v></c>'
          '</row>');
    }
    ws4.write('</sheetData></worksheet>');

    final sheets = [
      _XlsxSheet('Executive Summary & Profile', ws1.toString()),
      _XlsxSheet('Admin Actions', ws2.toString()),
      _XlsxSheet('Violations', ws3.toString()),
      _XlsxSheet('Devices & Sessions', ws4.toString()),
    ];

    return _buildZipMultiSheet(sheets, strings);
  }

  // ── Shared XLSX Builders ─────────────────────────────────────────────────
  static List<int> _buildZip(String sheetName, String sheetXml, List<String> strings) {
    return _buildZipMultiSheet([_XlsxSheet(sheetName, sheetXml)], strings);
  }

  static List<int> _buildZipMultiSheet(List<_XlsxSheet> sheets, List<String> strings) {
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
        '<fonts count="9" x14ac:knownFonts="1">'
        '<font><sz val="10"/><name val="Calibri"/><family val="2"/><color rgb="FF1E293B"/></font>'
        '<font><b/><sz val="10.5"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="15"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="9"/><color rgb="FF475569"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="14"/><color rgb="FF0F172A"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FF15803D"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FFB91C1C"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="10"/><color rgb="FFC2410C"/><name val="Calibri"/><family val="2"/></font>'
        '</fonts>'
        '<fills count="11">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFF8FAFC"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF0F172A"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF0F172A"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1D4ED8"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F9"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFDCFCE7"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFFEE2E2"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFFEF3C7"/><bgColor indexed="64"/></patternFill></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFE2E8F0"/><bgColor indexed="64"/></patternFill></fill>'
        '</fills>'
        '<borders count="4">'
        '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border>'
        '<left style="thin"><color rgb="FFCBD5E1"/></left>'
        '<right style="thin"><color rgb="FFCBD5E1"/></right>'
        '<top style="thin"><color rgb="FFCBD5E1"/></top>'
        '<bottom style="thin"><color rgb="FFCBD5E1"/></bottom>'
        '<diagonal/>'
        '</border>'
        '<border><left/><right/><top/><bottom style="medium"><color rgb="FF0F172A"/></bottom><diagonal/></border>'
        '<border>'
        '<left style="thin"><color rgb="FF94A3B8"/></left>'
        '<right style="thin"><color rgb="FF94A3B8"/></right>'
        '<top style="thin"><color rgb="FF94A3B8"/></top>'
        '<bottom style="thin"><color rgb="FF94A3B8"/></bottom>'
        '<diagonal/>'
        '</border>'
        '</borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="14">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        '<xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center" wrapText="0"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>'
        '<xf numFmtId="0" fontId="2" fillId="4" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="3" fillId="5" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="4" fillId="6" borderId="3" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="5" fillId="0" borderId="3" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="6" fillId="7" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="7" fillId="8" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="8" fillId="9" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf>'
        '<xf numFmtId="0" fontId="4" fillId="10" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
        '</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';

    final wbSb = StringBuffer();
    wbSb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>');
    for (var i = 0; i < sheets.length; i++) {
      wbSb.write('<sheet name="${_xmlEsc(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>');
    }
    wbSb.write('</sheets></workbook>');

    final typesSb = StringBuffer();
    typesSb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');
    for (var i = 0; i < sheets.length; i++) {
      typesSb.write('<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
    }
    typesSb.write('</Types>');

    const rootRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>';

    final wbRelsSb = StringBuffer();
    wbRelsSb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    for (var i = 0; i < sheets.length; i++) {
      wbRelsSb.write('<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>');
    }
    wbRelsSb.write('<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>');
    wbRelsSb.write('<Relationship Id="rId${sheets.length + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>');
    wbRelsSb.write('</Relationships>');

    final archive = Archive();
    void addPart(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile.bytes(name, bytes));
    }

    addPart('[Content_Types].xml', typesSb.toString());
    addPart('_rels/.rels', rootRels);
    addPart('xl/workbook.xml', wbSb.toString());
    addPart('xl/_rels/workbook.xml.rels', wbRelsSb.toString());
    for (var i = 0; i < sheets.length; i++) {
      addPart('xl/worksheets/sheet${i + 1}.xml', sheets[i].xml);
    }
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

  // ── CSV Single User Administrative Report Generator ──────────────────────
  static String _generateSingleUserCsv(UserAdminReportData report) {
    final sb = StringBuffer();
    sb.write('\uFEFF');
    final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(report.fetchedAt);
    final user = report.user;

    sb.writeln('BimoBond Enterprise Admin Dashboard - User Administrative Report');
    sb.writeln('Export Date:,$formattedNow');
    sb.writeln('User ID:,${_escapeCsv(user.id)}');
    sb.writeln('Username:,${_escapeCsv(user.username)}');
    sb.writeln('Risk Level:,${_escapeCsv(report.riskLevel.name.toUpperCase())}');
    sb.writeln('Safety Score:,${report.safetyScore}/100');
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
      'Last Active / Seen': user.lastActive ?? user.updatedAt,
      'Online Status': user.isOnlineOverride == true ? 'Online' : 'Offline',
    });

    addSection('2. Engagement Statistics', {
      'Followers': user.followerCount,
      'Following': user.followingCount,
      'Posts': user.postCount,
      'Total Likes': user.totalLikes,
      'Coins Balance': report.fullUserDetail?.wallet?.balanceCoins ?? user.wallet?.balanceCoins ?? 0,
      'Wallet ID': report.fullUserDetail?.wallet?.id ?? user.wallet?.id,
    });

    addSection('3. Location & GPS', {
      'Country': user.country,
      'Region': user.region,
      'City': user.city,
      'GPS Coordinates': formatGps(user),
    });

    sb.writeln('=== 4. Administrative Moderation Actions & Timeline ===');
    sb.writeln('Date & Time,Administrator,Role,Action Type,Reason / Description,Changes / Metadata');
    for (final a in report.adminActions) {
      final adminName = a.displayUser.isNotEmpty ? a.displayUser : (a.userName ?? a.actorRole ?? 'Admin');
      sb.writeln('${_escapeCsv(_formatDate(a.createdAt))},${_escapeCsv(adminName)},${_escapeCsv(a.actorRole ?? "ADMIN")},${_escapeCsv(a.action)},${_escapeCsv(a.description ?? a.displayTarget ?? "—")},${_escapeCsv(a.meta != null ? a.meta.toString() : "—")}');
    }
    sb.writeln();

    sb.writeln('=== 5. Community Guidelines Violations ===');
    sb.writeln('Date & Time,Action,Category,Description / Target,Actor Role');
    for (final v in report.violations) {
      sb.writeln('${_escapeCsv(_formatDate(v.createdAt))},${_escapeCsv(v.action)},${_escapeCsv(v.category)},${_escapeCsv(v.description ?? v.displayTarget ?? "—")},${_escapeCsv(v.actorRole ?? "SYSTEM")}');
    }
    sb.writeln();

    sb.writeln('=== 6. Security & Audit Log History ===');
    sb.writeln('Date & Time,Category,Action,Description,IP Address');
    for (final l in report.auditLogs.take(25)) {
      sb.writeln('${_escapeCsv(_formatDate(l.createdAt))},${_escapeCsv(l.category)},${_escapeCsv(l.action)},${_escapeCsv(l.description ?? l.displayTarget ?? "—")},${_escapeCsv(l.ipAddress ?? "—")}');
    }
    sb.writeln();

    sb.writeln('=== 7. Reports Received Against User ===');
    sb.writeln('Date & Time,Reporter,Reason,Status,Target Type,Target ID');
    for (final r in report.reportsReceived) {
      final targetId = r.postId ?? r.commentId ?? r.reportedUserId ?? r.id;
      sb.writeln('${_escapeCsv(_formatDate(r.createdAt))},${_escapeCsv("@${r.reporter?.username ?? 'Anonymous'}")},${_escapeCsv(r.reason)},${_escapeCsv(r.status)},${_escapeCsv(r.targetType)},${_escapeCsv(targetId)}');
    }
    sb.writeln();

    sb.writeln('=== 8. Devices & Registered Sessions ===');
    sb.writeln('Device ID,Model,OS / Platform,IP Address,Last Active');
    for (final d in report.devices) {
      final devId = d['deviceId']?.toString() ?? d['id']?.toString() ?? '—';
      final model = d['deviceModel']?.toString() ?? d['model']?.toString() ?? '—';
      final os = d['osVersion']?.toString() ?? d['platform']?.toString() ?? '—';
      final ip = d['ipAddress']?.toString() ?? d['ip']?.toString() ?? '—';
      final lastActive = d['lastActiveAt'] != null ? _formatDate(DateTime.tryParse(d['lastActiveAt'].toString())) : '—';
      sb.writeln('${_escapeCsv(devId)},${_escapeCsv(model)},${_escapeCsv(os)},${_escapeCsv(ip)},${_escapeCsv(lastActive)}');
    }
    sb.writeln();

    addSection('9. Privacy & Permissions', {
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
    });

    addSection('10. Social Media Links', {
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

extension _StringExt on String {
  String takeMax(int max) => length > max ? substring(0, max) : this;
}
