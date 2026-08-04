import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../../security_logs/domain/entities/log_entity.dart';
import '../../../security_logs/domain/usecases/get_logs_usecase.dart';
import '../../../security_logs/presentation/utils/logs_labels.dart';
import '../../../security_logs/presentation/widgets/logs_detail_dialog.dart';
import '../../../security_logs/presentation/widgets/moderation_action_timeline.dart';
import '../../domain/entities/user_entity.dart';

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

  int? _violationsCount;
  int? _adminActionsCount;

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
      final violationsRes = await _getLogs(LogsQuery(
        userId: widget.user.id,
        category: 'MODERATION',
        limit: 1,
      ));

      final actionsRes = await _getLogs(LogsQuery(
        userId: widget.user.id,
        category: 'ADMIN',
        limit: 1,
      ));

      if (mounted) {
        setState(() {
          _violationsCount = violationsRes.meta.total;
          _adminActionsCount = actionsRes.meta.total;
        });
      }
    } catch (_) {
      // Retain zero fallback without creating mock numbers
    }
  }

  AccountRiskLevel get riskLevel {
    final reports = totalReports;
    final violations = totalViolations;
    if (widget.user.isBanned || reports >= 5 || violations >= 3) {
      return AccountRiskLevel.high;
    }
    if (reports > 0 || violations > 0 || widget.user.isProfileLocked) {
      return AccountRiskLevel.medium;
    }
    return AccountRiskLevel.low;
  }

  int get totalReports => widget.user.relationCounts?.reportsRecv ?? 0;
  int get totalViolations => _violationsCount ?? 0;
  int get totalAdminActions => _adminActionsCount ?? 0;

  void _showReportsDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserReportsDetailSheet(user: widget.user, reportsCount: totalReports),
    );
  }

  void _showViolationsDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserViolationsDetailSheet(user: widget.user, violationsCount: totalViolations),
    );
  }

  void _showActionsDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserAdminActionsDetailSheet(user: widget.user, actionsCount: totalAdminActions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final risk = riskLevel;
    final isHighRisk = risk == AccountRiskLevel.high;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: isHighRisk ? risk.color : scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tOr('accountRiskAndModeration', 'Account Risk & Moderation'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            _RiskBadge(riskLevel: risk),
          ],
        ),
        const SizedBox(height: 12),

        // High Risk Highlight Warning Banner
        if (isHighRisk) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: risk.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: risk.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.report_problem_rounded, color: risk.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tOr(
                      'highRiskAccountNotice',
                      'High Risk Account Notice: Multiple flags or active penalties detected. Admin review recommended.',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: risk.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 4 Summary Metric Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;

            final riskCard = _RiskStatCard(
              title: l10n.tOr('riskLevel', 'Risk Level'),
              value: risk.label(context),
              subtitle: l10n.tOr('safetyIndex', 'Safety Index'),
              icon: risk.icon,
              color: risk.color,
              onTap: null,
            );

            final reportsCard = _RiskStatCard(
              title: l10n.tOr('reportsReceived', 'Reports Received'),
              value: '$totalReports',
              subtitle: l10n.tOr('clickForBreakdown', 'Click for breakdown'),
              icon: Icons.flag_outlined,
              color: totalReports > 0 ? const Color(0xFFF59E0B) : scheme.onSurfaceVariant,
              onTap: () => _showReportsDetail(context),
            );

            final violationsCard = _RiskStatCard(
              title: l10n.tOr('violationsHistory', 'Violations History'),
              value: '$totalViolations',
              subtitle: l10n.tOr('guidelineBreaches', 'Guideline breaches'),
              icon: Icons.gavel_outlined,
              color: totalViolations > 0 ? const Color(0xFFEF4444) : scheme.onSurfaceVariant,
              onTap: () => _showViolationsDetail(context),
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
                      const SizedBox(width: 10),
                      Expanded(child: reportsCard),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: violationsCard),
                      const SizedBox(width: 10),
                      Expanded(child: actionsCard),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: riskCard),
                const SizedBox(width: 10),
                Expanded(child: reportsCard),
                const SizedBox(width: 10),
                Expanded(child: violationsCard),
                const SizedBox(width: 10),
                Expanded(child: actionsCard),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Live Backend Append-Only Moderation Action Timeline
        ModerationActionTimeline(
          userId: widget.user.id,
          pageSize: 5,
        ),
      ],
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

class _UserReportsDetailSheet extends StatelessWidget {
  const _UserReportsDetailSheet({required this.user, required this.reportsCount});
  final UserEntity user;
  final int reportsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _UserRiskLogsDetailSheet(
      user: user,
      title: '${l10n.tOr('reportsAgainst', 'Reports Against')} @${user.username}',
      icon: Icons.flag_rounded,
      iconColor: Colors.orange,
      defaultCategory: 'MODERATION',
      defaultAction: 'REPORT_CREATE',
      emptyMessage: l10n.tOr('noReportsFound', 'No reports found for this user.'),
    );
  }
}

class _UserViolationsDetailSheet extends StatelessWidget {
  const _UserViolationsDetailSheet({required this.user, required this.violationsCount});
  final UserEntity user;
  final int violationsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _UserRiskLogsDetailSheet(
      user: user,
      title: '${l10n.tOr('guidelineViolations', 'Community Guideline Violations')} (@${user.username})',
      icon: Icons.gavel_rounded,
      iconColor: Colors.red,
      defaultCategory: 'MODERATION',
      emptyMessage: l10n.tOr('noViolationsFound', 'No guideline violations found.'),
    );
  }
}

class _UserAdminActionsDetailSheet extends StatelessWidget {
  const _UserAdminActionsDetailSheet({required this.user, required this.actionsCount});
  final UserEntity user;
  final int actionsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _UserRiskLogsDetailSheet(
      user: user,
      title: '${l10n.tOr('adminActionLogs', 'Administrative Action Logs')} (@${user.username})',
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
    this.defaultAction,
    required this.emptyMessage,
  });

  final UserEntity user;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? defaultCategory;
  final String? defaultAction;
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
        action: widget.defaultAction,
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
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.72,
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                              label: Text(l10n.tOr('retry', 'Retry')),
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
                              final actionLabel = logsActionLabel(l10n, item);
                              final categoryLabel = logsCategoryLabel(l10n, item.category);

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

