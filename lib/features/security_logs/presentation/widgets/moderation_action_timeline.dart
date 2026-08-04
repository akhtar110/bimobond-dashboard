import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/user_audit_log_socket_service.dart';
import '../../domain/entities/log_entity.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../utils/logs_labels.dart';
import 'logs_detail_dialog.dart';

/// Append-only Moderation Action Timeline component.
///
/// Displays immutable administrative and moderation action history from the backend
/// with text search, multi-faceted filters (category, action code, actor role, date range),
/// pagination bar (`AppPaginationBar`), expandable log details, and complete Arabic/English localization.
class ModerationActionTimeline extends StatefulWidget {
  const ModerationActionTimeline({
    super.key,
    this.userId,
    this.initialCategory,
    this.pageSize = 10,
    this.showSectionHeader = true,
  });

  /// Target user ID to scope the timeline to (optional).
  final String? userId;

  /// Default category to query if unspecified (e.g. 'MODERATION' or 'ADMIN').
  final String? initialCategory;

  /// Number of records per page.
  final int pageSize;

  /// Whether to render the section header with the title and append-only notice badge.
  final bool showSectionHeader;

  @override
  State<ModerationActionTimeline> createState() => _ModerationActionTimelineState();
}

class _ModerationActionTimelineState extends State<ModerationActionTimeline> {
  final GetLogsUseCase _getLogs = di.sl<GetLogsUseCase>();
  final TextEditingController _searchController = TextEditingController();
  late final UserAuditLogSocketService _socketService = UserAuditLogSocketService();

  StreamSubscription<LogEntity>? _logSubscription;
  StreamSubscription<RealtimeSocketStatus>? _statusSubscription;
  final Set<String> _realtimeArrivalIds = {};

  bool _isLoading = true;
  String? _errorMessage;
  List<LogEntity> _logs = [];

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  String? _selectedCategory;
  String? _selectedAction;
  String? _selectedActorRole;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _fetchTimelineLogs(page: 1);
    _initRealtimeSocket();
  }

  void _initRealtimeSocket() {
    _socketService.connect(targetUserId: widget.userId ?? '');

    _statusSubscription = _socketService.statusStream.listen((status) {
      if (mounted) setState(() {});
    });

    _logSubscription = _socketService.onModerationLog.listen((newLog) {
      _handleRealtimeLogArrival(newLog);
    });
  }

  void _handleRealtimeLogArrival(LogEntity newLog) {
    if (_logs.any((l) => l.id == newLog.id)) return;

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      if (newLog.targetId != widget.userId && newLog.actorId != widget.userId) {
        return;
      }
    }

    if (_selectedCategory != null &&
        newLog.category.toUpperCase() != _selectedCategory!.toUpperCase()) {
      return;
    }

    if (_selectedAction != null &&
        newLog.action.toUpperCase() != _selectedAction!.toUpperCase()) {
      return;
    }

    if (mounted) {
      setState(() {
        _logs = List<LogEntity>.of(_logs, growable: true);
        _logs.insert(0, newLog);
        _realtimeArrivalIds.add(newLog.id);
        _totalCount += 1;
      });
    }
  }

  @override
  void didUpdateWidget(ModerationActionTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.initialCategory != widget.initialCategory) {
      _selectedCategory = widget.initialCategory;
      _fetchTimelineLogs(page: 1);
      _socketService.connect(targetUserId: widget.userId ?? '');
    }
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _socketService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTimelineLogs({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = LogsQuery(
        page: page,
        limit: widget.pageSize,
        userId: widget.userId,
        category: _selectedCategory,
        action: _selectedAction,
        actorRole: _selectedActorRole,
        from: _fromDate,
        to: _toDate,
      );

      final result = await _getLogs(query);
      var fetchedLogs = List<LogEntity>.from(result.data);

      // Perform local client-side search filtering if search query is present
      final search = _searchController.text.trim().toLowerCase();
      if (search.isNotEmpty) {
        fetchedLogs = fetchedLogs.where((log) {
          final actionLbl = logsActionLabel(context.l10n, log).toLowerCase();
          final categoryLbl = log.category.toLowerCase();
          final desc = (log.description ?? '').toLowerCase();
          final user = (log.displayUser).toLowerCase();
          final actorRole = (log.actorRole ?? '').toLowerCase();
          final target = (log.displayTarget ?? '').toLowerCase();
          final reason = ((log.meta != null && log.meta!['reason'] != null)
                  ? log.meta!['reason'].toString()
                  : '')
              .toLowerCase();

          return actionLbl.contains(search) ||
              categoryLbl.contains(search) ||
              desc.contains(search) ||
              user.contains(search) ||
              actorRole.contains(search) ||
              target.contains(search) ||
              reason.contains(search);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _logs = List<LogEntity>.of(fetchedLogs, growable: true);
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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = widget.initialCategory;
      _selectedAction = null;
      _selectedActorRole = null;
      _fromDate = null;
      _toDate = null;
    });
    _fetchTimelineLogs(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header & Append-Only Notice
        if (widget.showSectionHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.tOr('moderationActionTimeline', 'Moderation Action Timeline'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RealtimeSocketStatusBadge(
                    status: _socketService.currentStatus,
                    onReconnect: () => _socketService.reconnect(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_clock_rounded, size: 13, color: scheme.primary),
                        const SizedBox(width: 5),
                        Text(
                          l10n.tOr('appendOnlyAuditNotice', 'Append-Only Permanent Audit Trail'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Search Input Field
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _fetchTimelineLogs(page: 1),
                        decoration: InputDecoration(
                          hintText: l10n.tOr(
                            'searchModerationLogs',
                            'Search moderation actions, admins, or reasons...',
                          ),
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchTimelineLogs(page: 1);
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: scheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Toggle Button
                  SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _showFilters = !_showFilters);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 38),
                        side: BorderSide(
                          color: _hasActiveFilters
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                        backgroundColor: _hasActiveFilters
                            ? scheme.primaryContainer.withValues(alpha: 0.2)
                            : null,
                      ),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: _hasActiveFilters ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.tOr('filter', 'Filter'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _hasActiveFilters ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Refresh Button
                  IconButton(
                    tooltip: l10n.tOr('refresh', 'Refresh'),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () => _fetchTimelineLogs(page: _currentPage),
                  ),
                ],
              ),

              // Expandable Filter Controls Panel
              if (_showFilters) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Dropdown Filter
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedCategory,
                        isDense: true,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface),
                        decoration: InputDecoration(
                          labelText: l10n.tOr('filterByCategory', 'Category'),
                          labelStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.tOr('filterAll', 'All Categories')),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'MODERATION',
                            child: Text(logsCategoryLabel(l10n, 'MODERATION')),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'ADMIN',
                            child: Text(logsCategoryLabel(l10n, 'ADMIN')),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                          _fetchTimelineLogs(page: 1);
                        },
                      ),
                    ),

                    // Role Dropdown Filter
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedActorRole,
                        isDense: true,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface),
                        decoration: InputDecoration(
                          labelText: l10n.tOr('filterByRole', 'Role'),
                          labelStyle: const TextStyle(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.tOr('filterAll', 'All Roles')),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'ADMIN',
                            child: Text(logsActorRoleLabel(l10n, 'ADMIN')),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'SYSTEM',
                            child: Text(logsActorRoleLabel(l10n, 'SYSTEM')),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedActorRole = val);
                          _fetchTimelineLogs(page: 1);
                        },
                      ),
                    ),

                    // Clear Filters Text Button
                    if (_hasActiveFilters)
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: Text(
                          l10n.tOr('clearFilters', 'Reset'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Timeline Records Content View
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: _buildBodyContent(context),
        ),

        // Pagination Bar Footer
        if (!_isLoading && _errorMessage == null && _totalPages > 1) ...[
          const SizedBox(height: 12),
          AppPaginationBar(
            currentPage: _currentPage,
            lastPage: _totalPages,
            total: _totalCount,
            pageSize: widget.pageSize,
            itemCount: _logs.length,
            onPageChanged: (page) => _fetchTimelineLogs(page: page),
          ),
        ],
      ],
    );
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      (_selectedCategory != null && _selectedCategory != widget.initialCategory) ||
      _selectedAction != null ||
      _selectedActorRole != null ||
      _fromDate != null ||
      _toDate != null;

  Widget _buildBodyContent(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 36, color: scheme.error),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _fetchTimelineLogs(page: _currentPage),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.tOr('retry', 'Retry')),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 44,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tOr('noModerationLogsFound', 'No moderation action records found.'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = _logs[index];
        final isLast = index == _logs.length - 1;
        return _TimelineRecordNode(
          log: item,
          isLast: isLast,
          onTap: () => showLogsDetailDialog(context, item),
        );
      },
    );
  }
}

class _TimelineRecordNode extends StatelessWidget {
  const _TimelineRecordNode({
    required this.log,
    required this.isLast,
    required this.onTap,
  });

  final LogEntity log;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final actionLabel = logsActionLabel(l10n, log);
    final categoryLabel = logsCategoryLabel(l10n, log.category);

    final (icon, color) = _getVisualsForAction(log.action, log.category, scheme);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    final reasonStr = _extractReason(log);
    final adminStr = _extractAdmin(log, l10n);

    return IntrinsicHeight(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Node Circle & Connector Line
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Record Body Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Action Title + Category Badge
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
                            horizontal: 7,
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

                    // Reason / Description
                    if (reasonStr.isNotEmpty) ...[
                      Text(
                        '${l10n.tOr('actionReason', 'Reason')}: $reasonStr',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Meta Row: Admin Actor, Timestamp, IP Address
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 13,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          adminStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(log.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (log.ipAddress != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.wifi_rounded,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.ipAddress!,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // View Details Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractReason(LogEntity log) {
    if (log.meta != null && log.meta!['reason'] != null) {
      final r = log.meta!['reason'].toString().trim();
      if (r.isNotEmpty) return r;
    }
    if (log.description != null && log.description!.trim().isNotEmpty) {
      return log.description!.trim();
    }
    if (log.displayTarget != null) {
      return log.displayTarget!;
    }
    return '';
  }

  String _extractAdmin(LogEntity log, AppLocalizations l10n) {
    final user = log.displayUser.trim();
    if (user.isNotEmpty) return user;
    if (log.actorRole != null && log.actorRole!.isNotEmpty) {
      return logsActorRoleLabel(l10n, log.actorRole);
    }
    return l10n.tOr('logsActorRoleSystem', 'SYSTEM');
  }

  (IconData, Color) _getVisualsForAction(
    String action,
    String category,
    ColorScheme scheme,
  ) {
    final act = action.toUpperCase();
    if (act.contains('BAN') || act.contains('DELETE') || act.contains('BLOCK')) {
      return (Icons.block_rounded, const Color(0xFFEF4444));
    }
    if (act.contains('UNBAN') || act.contains('VERIFY') || act.contains('APPROVE')) {
      return (Icons.verified_user_rounded, const Color(0xFF22C55E));
    }
    if (act.contains('WARN') || act.contains('REPORT')) {
      return (Icons.warning_amber_rounded, const Color(0xFFF59E0B));
    }
    return (Icons.gavel_rounded, scheme.primary);
  }
}

class _RealtimeSocketStatusBadge extends StatelessWidget {
  const _RealtimeSocketStatusBadge({
    required this.status,
    required this.onReconnect,
  });

  final RealtimeSocketStatus status;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = switch (status) {
      RealtimeSocketStatus.connected => const Color(0xFF22C55E),
      RealtimeSocketStatus.connecting ||
      RealtimeSocketStatus.reconnecting =>
        const Color(0xFFF59E0B),
      RealtimeSocketStatus.disconnected ||
      RealtimeSocketStatus.error =>
        const Color(0xFFEF4444),
    };

    final text = switch (status) {
      RealtimeSocketStatus.connected => l10n.tOr('liveSocketConnected', 'LIVE'),
      RealtimeSocketStatus.connecting => l10n.tOr('connecting', 'Connecting...'),
      RealtimeSocketStatus.reconnecting => l10n.tOr('reconnecting', 'Reconnecting...'),
      RealtimeSocketStatus.disconnected ||
      RealtimeSocketStatus.error =>
        l10n.tOr('offline', 'Offline'),
    };

    return InkWell(
      onTap: (status == RealtimeSocketStatus.disconnected ||
              status == RealtimeSocketStatus.error)
          ? onReconnect
          : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

