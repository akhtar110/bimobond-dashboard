import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/localization.dart';
import '../../../core/routing/app_router.dart';
import '../../post_management/domain/entities/activity_context.dart';
import '../../post_management/domain/entities/managed_post_entity.dart';
import '../../post_management/domain/entities/post_management_route_args.dart';
import '../../users/domain/entities/user_entity.dart';
import 'bloc/reports_bloc.dart';
import 'widgets/report_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page (BLoC listener + top-level scaffold)
// ─────────────────────────────────────────────────────────────────────────────

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadReportsEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ReportsBloc>().add(LoadMoreReportsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ReportsBloc, ReportsState>(
      listenWhen: (prev, next) {
        if (next is ReportsLoaded && next.errorMessage != null) return true;
        // Fire only when a new navigation target appears.
        if (prev is ReportsLoaded && next is ReportsLoaded) {
          return prev.pendingNavigation == null &&
              next.pendingNavigation != null;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! ReportsLoaded) return;

        // ── error snackbar ────────────────────────────────────────────────
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        // ── navigation side-effect ────────────────────────────────────────
        final nav = state.pendingNavigation;
        if (nav == null) return;

        // Clear the pending flag immediately to prevent re-fire on rebuilds.
        context.read<ReportsBloc>().add(ClearNavigationEvent());

        switch (nav) {
          case NavigateToUser(:final userId, :final username, :final fullName, :final avatarUrl):
            final stubUser = UserEntity(
              id: userId,
              username: username ?? userId,
              fullName: fullName,
              avatarUrl: avatarUrl,
              isVerified: false,
              isPrivate: false,
              allowComments: true,
              allowDirectMsgs: true,
              language: 'en',
              theme: 'light',
              followerCount: 0,
              followingCount: 0,
              postCount: 0,
              totalLikes: 0,
              isBanned: false,
              roles: const [],
            );
            Navigator.pushNamed(
              context,
              AppRoutes.userDetail,
              arguments: stubUser,
            );

          case NavigateToPost(:final postId, :final commentId):
            final now = DateTime.now();
            final stubPost = ManagedPostEntity(
              id: postId,
              userId: '',
              type: 'VIDEO',
              status: 'PUBLISHED',
              viewCount: 0,
              shareCount: 0,
              downloadCount: 0,
              likeCount: 0,
              commentCount: 0,
              saveCount: 0,
              isAd: false,
              privacyStatus: 'PUBLIC',
              allowComments: true,
              allowDuets: true,
              allowStitch: true,
              isStory: false,
              isAuctionable: false,
              createdAt: now,
              updatedAt: now,
            );
            final activityCtx = commentId != null
                ? ActivityContext(
                    type: ActivityType.comment,
                    commentId: commentId,
                    activityDate: now,
                  )
                : null;
            Navigator.pushNamed(
              context,
              AppRoutes.postManagementDetail,
              arguments: PostManagementRouteArgs(
                post: stubPost,
                activityContext: activityCtx,
              ),
            );
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFF7F9FC),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportsHeader(isDark: isDark),
                  const SizedBox(height: 10),
                  _FilterBar(isDark: isDark),
                  const SizedBox(height: 10),
                  Expanded(
                    child: BlocBuilder<ReportsBloc, ReportsState>(
                      builder: (context, state) => switch (state) {
                        ReportsInitial() ||
                        ReportsLoading() =>
                          const _LoadingView(),
                        ReportsError(:final message) =>
                          _ErrorView(message: message),
                        ReportsLoaded() => _ReportsList(
                            state: state,
                            scrollController: _scrollController,
                          ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B28) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3344) : const Color(0xFFE8ECF0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('reports'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                BlocSelector<ReportsBloc, ReportsState, String>(
                  selector: (s) => s is ReportsLoaded
                      ? '${s.total} ${l10n.t('reports').toLowerCase()}'
                      : '',
                  builder: (_, subtitle) => Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade500
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: () =>
                context.read<ReportsBloc>().add(RefreshReportsEvent()),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status + type filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.isDark});
  final bool isDark;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'PENDING', value: 'PENDING'),
    (label: 'RESOLVED', value: 'RESOLVED'),
    (label: 'DISMISSED', value: 'DISMISSED'),
  ];

  static const _typeFilters = [
    (label: 'All Types', value: null),
    (label: 'Post', value: 'post'),
    (label: 'User', value: 'user'),
    (label: 'Comment', value: 'comment'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      buildWhen: (prev, next) {
        if (prev is ReportsLoaded && next is ReportsLoaded) {
          return prev.statusFilter != next.statusFilter ||
              prev.typeFilter != next.typeFilter;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        final activeStatus =
            state is ReportsLoaded ? state.statusFilter : null;
        final activeType = state is ReportsLoaded ? state.typeFilter : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _statusFilters[i];
                  final selected = activeStatus == f.value;
                  final color = _statusColor(f.value);
                  return _FilterChip(
                    label: f.label,
                    isSelected: selected,
                    color: color,
                    isDark: isDark,
                    onTap: () => context.read<ReportsBloc>().add(
                          FilterReportsEvent(
                            status: f.value,
                            type: activeType,
                          ),
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Type row
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _typeFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final f = _typeFilters[i];
                  final selected = activeType == f.value;
                  return _FilterChip(
                    label: f.label,
                    isSelected: selected,
                    isDark: isDark,
                    small: true,
                    onTap: () => context.read<ReportsBloc>().add(
                          FilterReportsEvent(
                            status: activeStatus,
                            type: f.value,
                          ),
                        ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static Color _statusColor(String? status) => switch (status) {
        'PENDING' => const Color(0xFFF59E0B),
        'RESOLVED' => const Color(0xFF10B981),
        'DISMISSED' => const Color(0xFF6B7280),
        _ => const Color(0xFF6366F1),
      };
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.color,
    this.small = false,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;
  final bool small;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;
    final bg = widget.isSelected
        ? accent
        : _hovered
            ? (widget.isDark
                ? const Color(0xFF252B3B)
                : const Color(0xFFF1F5F9))
            : (widget.isDark ? const Color(0xFF151B28) : Colors.white);
    final fg = widget.isSelected
        ? Colors.white
        : widget.isDark
            ? Colors.grey.shade300
            : const Color(0xFF374151);
    final border = widget.isSelected
        ? accent
        : widget.isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.small ? 28 : 34,
          padding: EdgeInsets.symmetric(
            horizontal: widget.small ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: border,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.small ? 11 : 12,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports list
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsList extends StatelessWidget {
  const _ReportsList({
    required this.state,
    required this.scrollController,
  });

  final ReportsLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.reports.isEmpty) {
      return const _EmptyView();
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReportCard(
                report: state.reports[index],
                isUpdating: state.updatingId == state.reports[index].id,
                onTap: () => context.read<ReportsBloc>().add(
                      OpenReportTargetEvent(state.reports[index]),
                    ),
              ),
            ),
            childCount: state.reports.length,
          ),
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        if (state.hasReachedMax && state.reports.isNotEmpty)
          SliverToBoxAdapter(child: _EndLabel(total: state.total)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Misc: loading / empty / error / end-label
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_outlined,
              size: 32,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('recentReports'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'No reports match the current filter.',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<ReportsBloc>().add(RefreshReportsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndLabel extends StatelessWidget {
  const _EndLabel({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 1,
            color: isDark
                ? const Color(0xFF2E3440)
                : const Color(0xFFE8ECF0),
          ),
          const SizedBox(width: 10),
          Text(
            'All $total reports loaded',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 1,
            color: isDark
                ? const Color(0xFF2E3440)
                : const Color(0xFFE8ECF0),
          ),
        ],
      ),
    );
  }
}
