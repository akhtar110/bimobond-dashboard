import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_reports_usecase.dart';
import '../../../reports/domain/usecases/update_report_status_usecase.dart';
import '../../../reports/presentation/utils/report_target_navigation.dart';
import '../../../security_logs/data/datasources/user_violations_remote_datasource.dart';
import '../../../security_logs/domain/entities/log_entity.dart';
import '../../../security_logs/domain/usecases/get_logs_usecase.dart';
import '../../../security_logs/presentation/utils/log_target_navigation.dart';
import '../../../security_logs/presentation/utils/logs_labels.dart';
import '../../../security_logs/presentation/widgets/logs_detail_dialog.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/user_detail_event.dart';
import '../bloc/user_detail_state.dart';

enum AccountRiskLevel {
  low,
  medium,
  high;

  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case AccountRiskLevel.low:
        return l10n.tOr('riskLow', 'Low Risk');
      case AccountRiskLevel.medium:
        return l10n.tOr('riskMedium', 'Medium Risk');
      case AccountRiskLevel.high:
        return l10n.tOr('riskHigh', 'High Risk');
    }
  }

  Color get color {
    switch (this) {
      case AccountRiskLevel.low:
        return const Color(0xFF22C55E);
      case AccountRiskLevel.medium:
        return const Color(0xFFF59E0B);
      case AccountRiskLevel.high:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case AccountRiskLevel.low:
        return Icons.verified_user_outlined;
      case AccountRiskLevel.medium:
        return Icons.warning_amber_rounded;
      case AccountRiskLevel.high:
        return Icons.gavel_rounded;
    }
  }
}

class UserAccountRiskSection extends StatefulWidget {
  const UserAccountRiskSection({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  State<UserAccountRiskSection> createState() => _UserAccountRiskSectionState();
}

class _UserAccountRiskSectionState extends State<UserAccountRiskSection> {
  final GetLogsUseCase _getLogs = di.sl<GetLogsUseCase>();
  late final UserViolationsRemoteDataSource _violationsDataSource =
      UserViolationsRemoteDataSourceImpl(di.sl());

  int _pendingCount = 0;
  int _confirmedCount = 0;
  int _resolvedCount = 0;
  int _dismissedCount = 0;
  int _totalReportsCount = 0;
  int _adminActionsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchBackendCounts();
  }

  @override
  void didUpdateWidget(UserAccountRiskSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.isBanned != widget.user.isBanned ||
        oldWidget.user.updatedAt != widget.user.updatedAt) {
      _fetchBackendCounts();
    }
  }

  Future<void> _fetchBackendCounts() async {
    try {
      final violationsRes = await _violationsDataSource.getUserViolations(
        userId: widget.user.id,
        limit: 1,
      );

      final actionsRes = await _getLogs(LogsQuery(
        userId: widget.user.id,
        category: 'ADMIN',
        limit: 1,
      ));

      final pendingRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        status: 'PENDING',
        limit: 1,
      );

      final underReviewRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        status: 'UNDER_REVIEW',
        limit: 1,
      );

      final confirmedRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        status: 'CONFIRMED',
        limit: 1,
      );

      final resolvedRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        status: 'RESOLVED',
        limit: 1,
      );

      final dismissedRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        status: 'DISMISSED',
        limit: 1,
      );

      final allReportsRes = await di.sl<GetReports>()(
        reportedUserId: widget.user.id,
        limit: 1,
      );

      final pendingTotal = pendingRes.total + underReviewRes.total;
      final confirmedTotal = math.max(confirmedRes.total, violationsRes.meta.total);
      final resolvedTotal = resolvedRes.total;
      final dismissedTotal = dismissedRes.total;

      final sumStatus = pendingTotal + confirmedTotal + resolvedTotal + dismissedTotal;
      final totalReportsCalc = math.max(allReportsRes.total, math.max(sumStatus, widget.user.relationCounts?.reportsRecv ?? 0));

      if (mounted) {
        setState(() {
          _pendingCount = pendingTotal;
          _confirmedCount = confirmedTotal;
          _resolvedCount = resolvedTotal;
          _dismissedCount = dismissedTotal;
          _totalReportsCount = totalReportsCalc;
          _adminActionsCount = actionsRes.meta.total;
        });
      }
    } catch (_) {
      // Retain existing values or fallback gracefully
    }
  }

  int get totalReports => math.max(_totalReportsCount, _pendingCount + _confirmedCount + _resolvedCount + _dismissedCount);
  int get pendingReports => _pendingCount;
  int get confirmedReports => _confirmedCount;
  int get resolvedReports => _resolvedCount;
  int get dismissedReports => _dismissedCount;
  int get totalAdminActions => _adminActionsCount;

  AccountRiskLevel get riskLevel {
    final pending = pendingReports;
    final confirmed = confirmedReports;
    if (widget.user.isBanned || pending >= 5 || confirmed >= 3) {
      return AccountRiskLevel.high;
    }
    if (pending > 0 || confirmed > 0 || widget.user.isProfileLocked) {
      return AccountRiskLevel.medium;
    }
    return AccountRiskLevel.low;
  }

  int get safetyScore {
    final pending = pendingReports;
    final confirmed = confirmedReports;
    final penalties = (pending * 5) +
        (confirmed * 20) +
        (widget.user.isBanned ? 40 : 0) +
        (widget.user.isProfileLocked ? 10 : 0);
    return (100 - penalties).clamp(0, 100);
  }

  void _showReportsDetail(BuildContext context, {String? initialStatus}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserReportsDetailSheet(
        user: widget.user,
        initialStatus: initialStatus,
        onReportsUpdated: _fetchBackendCounts,
      ),
    ).then((_) => _fetchBackendCounts());
  }

  void _showActionsDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserAdminActionsDetailSheet(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final risk = riskLevel;

    return BlocListener<UserDetailBloc, UserDetailState>(
      listenWhen: (previous, current) {
        if (current is UserDetailLoaded) {
          if (previous is! UserDetailLoaded) return true;
          return current.isRefreshing ||
              current.actionFeedback != null ||
              current.userDetail.user.updatedAt != previous.userDetail.user.updatedAt;
        }
        return false;
      },
      listener: (context, state) {
        _fetchBackendCounts();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Section Header
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.tOr('accountRiskAndModeration', 'Account Risk & Moderation'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            _RiskBadge(riskLevel: risk),
          ],
        ),
        const SizedBox(height: 12),

        // Contextual Moderation Summary Banner
        _ContextualModerationBanner(
          riskLevel: risk,
          unresolvedReports: pendingReports,
          violations: confirmedReports,
          isBanned: widget.user.isBanned,
          isProfileLocked: widget.user.isProfileLocked,
        ),
        const SizedBox(height: 12),

        // 7 Status & Risk Metric Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 680;

            final riskCard = _RiskStatCard(
              title: l10n.tOr('riskLevel', 'Risk Level'),
              value: risk.label(context),
              subtitle: l10n.tArgs('safetyScore', {'score': '$safetyScore'}),
              icon: risk.icon,
              color: risk.color,
              onTap: null,
            );

            final totalCard = _RiskStatCard(
              title: l10n.tOr('totalReports', 'Total Reports'),
              value: '$totalReports',
              subtitle: l10n.tOr('permanentHistory', 'Permanent history'),
              icon: Icons.auto_graph_rounded,
              color: scheme.secondary,
              onTap: () => _showReportsDetail(context),
            );

            final pendingCard = _RiskStatCard(
              title: l10n.tOr('pendingReports', 'Pending Reports'),
              value: '$pendingReports',
              subtitle: pendingReports == 0
                  ? l10n.tOr('noPendingReports', 'No pending reports')
                  : l10n.tOr('requiresReview', 'Requires review'),
              icon: Icons.hourglass_top_rounded,
              color: pendingReports > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
              onTap: () => _showReportsDetail(context, initialStatus: 'pending'),
            );

            final confirmedCard = _RiskStatCard(
              title: l10n.tOr('confirmedReports', 'Confirmed Reports'),
              value: '$confirmedReports',
              subtitle: confirmedReports == 0
                  ? l10n.tOr('noViolations', 'No active strikes')
                  : l10n.tOr('affectsRisk', 'Active policy strikes'),
              icon: Icons.gavel_rounded,
              color: confirmedReports > 0 ? const Color(0xFFEF4444) : scheme.onSurfaceVariant,
              onTap: () => _showReportsDetail(context, initialStatus: 'confirmed'),
            );

            final resolvedCard = _RiskStatCard(
              title: l10n.tOr('resolvedReports', 'Resolved Reports'),
              value: '$resolvedReports',
              subtitle: l10n.tOr('zeroRiskImpact', '0 risk impact'),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _showReportsDetail(context, initialStatus: 'resolved'),
            );

            final dismissedCard = _RiskStatCard(
              title: l10n.tOr('dismissedReports', 'Dismissed Reports'),
              value: '$dismissedReports',
              subtitle: l10n.tOr('zeroRiskImpact', '0 risk impact'),
              icon: Icons.do_not_disturb_on_outlined,
              color: Colors.grey,
              onTap: () => _showReportsDetail(context, initialStatus: 'dismissed'),
            );

            final actionsCard = _RiskStatCard(
              title: l10n.tOr('adminActions', 'Admin Actions'),
              value: '$totalAdminActions',
              subtitle: l10n.tOr('penaltiesOnRecord', 'Penalties on record'),
              icon: Icons.admin_panel_settings_outlined,
              color: scheme.primary,
              onTap: () => _showActionsDetail(context),
            );

            if (isCompact) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: riskCard),
                      const SizedBox(width: 8),
                      Expanded(child: totalCard),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: pendingCard),
                      const SizedBox(width: 8),
                      Expanded(child: confirmedCard),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: resolvedCard),
                      const SizedBox(width: 8),
                      Expanded(child: dismissedCard),
                    ],
                  ),
                  const SizedBox(height: 8),
                  actionsCard,
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: riskCard),
                    const SizedBox(width: 10),
                    Expanded(child: totalCard),
                    const SizedBox(width: 10),
                    Expanded(child: actionsCard),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: pendingCard),
                    const SizedBox(width: 10),
                    Expanded(child: confirmedCard),
                    const SizedBox(width: 10),
                    Expanded(child: resolvedCard),
                    const SizedBox(width: 10),
                    Expanded(child: dismissedCard),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
}

class _ContextualModerationBanner extends StatelessWidget {
  const _ContextualModerationBanner({
    required this.riskLevel,
    required this.unresolvedReports,
    required this.violations,
    required this.isBanned,
    required this.isProfileLocked,
  });

  final AccountRiskLevel riskLevel;
  final int unresolvedReports;
  final int violations;
  final bool isBanned;
  final bool isProfileLocked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (riskLevel == AccountRiskLevel.low) {
      const greenColor = Color(0xFF22C55E);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: greenColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: greenColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: greenColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: greenColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tOr('accountUnderControl', isArabic ? 'حالة الحساب مستقرة' : 'Account Under Control'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: greenColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tOr(
                      'noActiveModerationIssues',
                      isArabic
                          ? 'لا توجد بلاغات معلقة أو قيود نشطة. تم معالجة جميع البلاغات.'
                          : 'No active pending reports or account restrictions. All reports processed.',
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: greenColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // High or Medium Risk Contextual Banner
    final bannerColor = riskLevel.color;
    final factors = <String>[];

    if (unresolvedReports > 0) {
      factors.add(isArabic ? 'البلاغات غير المعالجة: $unresolvedReports' : 'Unresolved Reports: $unresolvedReports');
    }
    if (violations > 0) {
      factors.add(isArabic ? 'المخالفات النشطة: $violations' : 'Active Violations: $violations');
    }
    if (isBanned) {
      factors.add(isArabic ? 'الحساب محظور' : 'Account Banned');
    }
    if (isProfileLocked) {
      factors.add(isArabic ? 'الملف الشخصي مقيد' : 'Profile Restricted');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              riskLevel == AccountRiskLevel.high ? Icons.gavel_rounded : Icons.warning_amber_rounded,
              size: 20,
              color: bannerColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLevel == AccountRiskLevel.high
                      ? l10n.tOr('highRiskAccountNotice', isArabic ? 'حساب مرتفع المخاطر' : 'High Risk Account Notice')
                      : l10n.tOr('mediumRiskAccountNotice', isArabic ? 'حساب متوسط المخاطر' : 'Medium Risk Account Notice'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                  ),
                ),
                if (factors.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: factors.map((factor) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bannerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          factor,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: bannerColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riskLevel});

  final AccountRiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: riskLevel.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: riskLevel.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: riskLevel.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            riskLevel.label(context),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: riskLevel.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskStatCard extends StatefulWidget {
  const _RiskStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_RiskStatCard> createState() => _RiskStatCardState();
}

class _RiskStatCardState extends State<_RiskStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isClickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered && isClickable
                  ? widget.color.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: _isHovered && isClickable ? 0.06 : 0.02),
                blurRadius: _isHovered && isClickable ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.icon, size: 18, color: widget.color),
                  if (isClickable)
                    Icon(
                      context.isRtl ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  fontSize: 11.5,
                ),
              ),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated detail sheet for Reports Received against the user's content
class _UserReportsDetailSheet extends StatefulWidget {
  const _UserReportsDetailSheet({
    required this.user,
    this.initialStatus,
    this.onReportsUpdated,
  });

  final UserEntity user;
  final String? initialStatus;
  final VoidCallback? onReportsUpdated;

  @override
  State<_UserReportsDetailSheet> createState() => _UserReportsDetailSheetState();
}

class _UserReportsDetailSheetState extends State<_UserReportsDetailSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GetReports _getReports = di.sl<GetReports>();

  bool _isLoading = true;
  String? _errorMessage;
  List<ReportEntity> _reports = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;
  String? _selectedStatus;
  final bool _sortNewestFirst = true;
  String? _updatingReportId;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(ReportEntity report, String newStatus) async {
    if (_updatingReportId != null) return;
    setState(() => _updatingReportId = report.id);

    try {
      await di.sl<UpdateReportStatus>()(
        id: report.id,
        status: newStatus,
      );

      await _fetchReports(page: _currentPage);
      widget.onReportsUpdated?.call();

      if (mounted) {
        try {
          context.read<UserDetailBloc>().add(RefreshUserDetailEvent());
        } catch (_) {}

        final msg = newStatus == 'RESOLVED'
            ? context.l10n.tOr('reportResolved', 'Report marked as resolved')
            : (newStatus == 'DISMISSED'
                ? context.l10n.tOr('reportDismissed', 'Report ignored')
                : context.l10n.tOr('reportReopened', 'Report reopened'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(msg),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingReportId = null);
      }
    }
  }

  Future<void> _fetchReports({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final search = _searchController.text.trim();
      final result = await _getReports(
        page: page,
        limit: 10,
        reportedUserId: widget.user.id,
        status: _selectedStatus,
        search: search.isNotEmpty ? search : null,
        sortOrder: _sortNewestFirst ? 'DESC' : 'ASC',
      );

      if (mounted) {
        setState(() {
          _reports = List<ReportEntity>.of(result.reports, growable: true);
          _currentPage = page;
          _lastPage = result.lastPage;
          _totalCount = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_jm();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.orange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.tArgs('reportsAgainstUser', {'username': widget.user.username})} ($_totalCount)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _fetchReports(page: 1),
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: l10n.tOr('search', 'Search...'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                tooltip: l10n.tOr('filterByStatus', 'Filter Status'),
                onSelected: (val) {
                  setState(() => _selectedStatus = val);
                  _fetchReports(page: 1);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: null,
                    child: Text(l10n.tOr('all', 'All')),
                  ),
                  PopupMenuItem(
                    value: 'pending',
                    child: Text(l10n.tOr('statusPending', 'Pending')),
                  ),
                  PopupMenuItem(
                    value: 'resolved',
                    child: Text(l10n.tOr('statusResolved', 'Resolved')),
                  ),
                  PopupMenuItem(
                    value: 'dismissed',
                    child: Text(l10n.tOr('statusDismissed', 'Dismissed')),
                  ),
                ],
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _selectedStatus == null
                            ? l10n.tOr('all', 'All')
                            : _selectedStatus!.toUpperCase(),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 36, color: scheme.error),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: TextStyle(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _fetchReports(page: 1),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 40,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.tOr('noReportsFound', 'No reports found for this user.'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _reports.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              final canOpenTarget = ReportTargetNavigation.canOpen(report);

                              return Material(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _ReportStatusBadge(status: report.status),
                                          const Spacer(),
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFmt.format(report.createdAt.toLocal()),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '${l10n.tOr('reporter', 'Reporter')}: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '@${report.reporter?.username ?? l10n.tOr('anonymous', 'Anonymous')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${l10n.tOr('reportReason', 'Reason')}: ${report.reason}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                       const SizedBox(height: 8),
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.end,
                                         children: [
                                           if (canOpenTarget)
                                             TextButton.icon(
                                               style: TextButton.styleFrom(
                                                 visualDensity: VisualDensity.compact,
                                                 padding: const EdgeInsets.symmetric(
                                                   horizontal: 8,
                                                   vertical: 4,
                                                 ),
                                               ),
                                               onPressed: () => ReportTargetNavigation.open(context, report),
                                               icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                               label: Text(
                                                 l10n.tOr('reportedContent', 'Reported Content'),
                                                 style: const TextStyle(fontSize: 11),
                                               ),
                                             ),
                                           const SizedBox(width: 8),
                                           if (_updatingReportId == report.id)
                                             const SizedBox(
                                               width: 16,
                                               height: 16,
                                               child: CircularProgressIndicator(strokeWidth: 2),
                                             )
                                           else ...[
                                             if (!report.isResolved)
                                               OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   visualDensity: VisualDensity.compact,
                                                   padding: const EdgeInsets.symmetric(
                                                     horizontal: 8,
                                                     vertical: 4,
                                                   ),
                                                   minimumSize: Size.zero,
                                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                   side: BorderSide(color: scheme.primary),
                                                 ),
                                                 onPressed: () => _updateStatus(report, 'RESOLVED'),
                                                 icon: Icon(Icons.check_circle_outline_rounded, size: 14, color: scheme.primary),
                                                 label: Text(
                                                   l10n.t('resolve'),
                                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.primary),
                                                 ),
                                               ),
                                             if (!report.isResolved) const SizedBox(width: 6),
                                             if (!report.isDismissed)
                                               OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   visualDensity: VisualDensity.compact,
                                                   padding: const EdgeInsets.symmetric(
                                                     horizontal: 8,
                                                     vertical: 4,
                                                   ),
                                                   minimumSize: Size.zero,
                                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                   side: BorderSide(color: scheme.outlineVariant),
                                                 ),
                                                 onPressed: () => _updateStatus(report, 'DISMISSED'),
                                                 icon: Icon(Icons.do_not_disturb_outlined, size: 14, color: scheme.onSurfaceVariant),
                                                 label: Text(
                                                   l10n.t('ignore'),
                                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                                                 ),
                                               ),
                                             if (report.isResolved || report.isDismissed)
                                               OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   visualDensity: VisualDensity.compact,
                                                   padding: const EdgeInsets.symmetric(
                                                     horizontal: 8,
                                                     vertical: 4,
                                                   ),
                                                   minimumSize: Size.zero,
                                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                   side: BorderSide(color: scheme.tertiary),
                                                 ),
                                                 onPressed: () => _updateStatus(report, 'PENDING'),
                                                 icon: Icon(Icons.undo_rounded, size: 14, color: scheme.tertiary),
                                                 label: Text(
                                                   l10n.t('reopen'),
                                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.tertiary),
                                                 ),
                                               ),
                                           ],
                                         ],
                                       ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          if (_lastPage > 1) ...[
            const SizedBox(height: 8),
            AppPaginationBar(
              currentPage: _currentPage,
              lastPage: _lastPage,
              total: _totalCount,
              pageSize: 10,
              itemCount: _reports.length,
              onPageChanged: (page) => _fetchReports(page: page),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = switch (status.toLowerCase()) {
      'pending' => const Color(0xFFF59E0B),
      'resolved' => const Color(0xFF22C55E),
      'dismissed' => Colors.grey,
      _ => Colors.blue,
    };

    final label = switch (status.toLowerCase()) {
      'pending' => l10n.tOr('statusPending', 'Pending'),
      'resolved' => l10n.tOr('statusResolved', 'Resolved'),
      'dismissed' => l10n.tOr('statusDismissed', 'Dismissed'),
      _ => status.toUpperCase(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Dedicated detail sheet for Moderator Administrative Actions
class _UserAdminActionsDetailSheet extends StatelessWidget {
  const _UserAdminActionsDetailSheet({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _UserRiskLogsDetailSheet(
      user: user,
      title: l10n.tArgs('adminLogsOfUser', {'username': user.username}),
      icon: Icons.admin_panel_settings_rounded,
      iconColor: Colors.blue,
      defaultCategory: 'ADMIN',
      emptyMessage: l10n.tOr('noAdminActionsFound', 'No administrative actions on record.'),
    );
  }
}

class _UserRiskLogsDetailSheet extends StatefulWidget {
  const _UserRiskLogsDetailSheet({
    required this.user,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.defaultCategory,
    required this.emptyMessage,
  });

  final UserEntity user;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? defaultCategory;
  final String emptyMessage;

  @override
  State<_UserRiskLogsDetailSheet> createState() => _UserRiskLogsDetailSheetState();
}

class _UserRiskLogsDetailSheetState extends State<_UserRiskLogsDetailSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GetLogsUseCase _getLogs = di.sl<GetLogsUseCase>();

  bool _isLoading = true;
  String? _errorMessage;
  List<LogEntity> _logs = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String? _selectedCategory;
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = LogsQuery(
        userId: widget.user.id,
        category: _selectedCategory,
        page: page,
        limit: 15,
      );

      final result = await _getLogs(query);
      var fetched = List<LogEntity>.from(result.data);

      final search = _searchController.text.trim().toLowerCase();
      if (search.isNotEmpty) {
        fetched = fetched.where((log) {
          final desc = log.description?.toLowerCase() ?? '';
          final act = log.action.toLowerCase();
          final cat = log.category.toLowerCase();
          final target = log.displayTarget?.toLowerCase() ?? '';
          return desc.contains(search) ||
              act.contains(search) ||
              cat.contains(search) ||
              target.contains(search);
        }).toList();
      }

      if (!_sortNewestFirst) {
        fetched.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (mounted) {
        setState(() {
          _logs = fetched;
          _currentPage = result.meta.page;
          _totalPages = result.meta.totalPages;
          _totalCount = result.meta.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_jm();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.title} ($_totalCount)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search and Filter bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _fetchLogs(page: 1),
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: l10n.tOr('search', 'Search...'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<bool>(
                tooltip: l10n.tOr('sort', 'Sort'),
                onSelected: (sortNewest) {
                  setState(() => _sortNewestFirst = sortNewest);
                  _fetchLogs(page: 1);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Text(l10n.tOr('sortNewestFirst', 'Newest First')),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: Text(l10n.tOr('sortOldestFirst', 'Oldest First')),
                  ),
                ],
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sortNewestFirst
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.sort_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 36, color: scheme.error),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: TextStyle(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _fetchLogs(page: 1),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.t('retry')),
                            ),
                          ],
                        ),
                      )
                    : _logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 40,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.emptyMessage,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _logs.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _logs[index];
                              final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                              final actionLabel = logsDisplayTitle(l10n, item, isArabic: isArabic);
                              final categoryLabel = logsCategoryLabel(l10n, item.category);
                              final navTargets = LogTargetNavigation.resolveAll(item);

                              return Material(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => showLogsDetailDialog(context, item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: widget.iconColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            widget.icon,
                                            size: 18,
                                            color: widget.iconColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      actionLabel,
                                                      style: theme.textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: scheme.surfaceContainerHighest,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      categoryLabel,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: scheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.description ?? item.displayTarget ?? '—',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: scheme.onSurfaceVariant,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                              if (navTargets.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: navTargets.map((target) {
                                                    return ActionChip(
                                                      avatar: Icon(target.icon, size: 14),
                                                      label: Text(
                                                        target.label(isArabic),
                                                        style: const TextStyle(fontSize: 11),
                                                      ),
                                                      visualDensity: VisualDensity.compact,
                                                      onPressed: () =>
                                                          LogTargetNavigation.open(context, target),
                                                    );
                                                  }).toList(growable: false),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: scheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    dateFmt.format(item.createdAt.toLocal()),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: scheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  if (item.actorRole != null) ...[
                                                    const SizedBox(width: 10),
                                                    Icon(
                                                      Icons.admin_panel_settings_outlined,
                                                      size: 12,
                                                      color: scheme.onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      item.actorRole!,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: scheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          if (_totalPages > 1) ...[
            const SizedBox(height: 8),
            AppPaginationBar(
              currentPage: _currentPage,
              lastPage: _totalPages,
              total: _totalCount,
              pageSize: 15,
              itemCount: _logs.length,
              onPageChanged: (page) => _fetchLogs(page: page),
            ),
          ],
        ],
      ),
    );
  }
}
