import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/reports_query_params.dart';
import '../bloc/reports_bloc.dart';
import '../utils/report_target_navigation.dart';
import '../widgets/report_action_bar.dart';
import '../widgets/report_card.dart';
import '../widgets/report_card_theme.dart';
import '../utils/moderation_filter_labels.dart';
import '../utils/reports_center_theme.dart';
import '../utils/reports_responsive.dart';
import '../widgets/report_status_chip.dart';
import '../widgets/reports_pagination_bar.dart';

class ModerationReportsTab extends StatefulWidget {
  const ModerationReportsTab({
    super.key,
    this.denseLayout = false,
  });

  final bool denseLayout;

  @override
  State<ModerationReportsTab> createState() => _ModerationReportsTabState();
}

class _ModerationReportsTabState extends State<ModerationReportsTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

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
    if (!mounted) return;
    if (!reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width)) return;
    if (!reportsShouldLoadMore(_scrollController)) return;
    context.read<ReportsBloc>().add(LoadMoreReportsEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<ReportsBloc, ReportsState>(
      listenWhen: (prev, next) =>
          next is ReportsLoaded && next.errorMessage != null,
      listener: (context, state) {
        if (state is! ReportsLoaded || state.errorMessage == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: scheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          widget.denseLayout ? 0 : 12,
          widget.denseLayout ? 0 : 8,
          widget.denseLayout ? 0 : 12,
          widget.denseLayout ? 0 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.denseLayout) ...[
              const _ModerationToolbar(),
              const SizedBox(height: 10),
              const _FilterBar(),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, state) => switch (state) {
                  ReportsInitial() || ReportsLoading() =>
                    const _LoadingView(),
                  ReportsError(:final message) => _ErrorView(message: message),
                  ReportsLoaded() => widget.denseLayout
                      ? _ModerationTable(
                          state: state,
                          scrollController: _scrollController,
                        )
                      : _ReportsCardList(
                          state: state,
                          scrollController: _scrollController,
                        ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationTable extends StatelessWidget {
  const _ModerationTable({
    required this.state,
    required this.scrollController,
  });

  final ReportsLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending =
        state.reports.where((r) => r.status == 'PENDING').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ModerationTableLayout.fromWidth(constraints.maxWidth);

        return DecoratedBox(
          decoration: ReportsCenterTheme.dataPanel(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModerationSummaryBar(
                showing: state.reports.length,
                total: state.total,
                pending: pending,
              ),
              if (state.isLoadingMore)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              _ModerationTableHeader(scheme: scheme, layout: layout),
              Expanded(
                child: state.reports.isEmpty
                    ? const _EmptyView()
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: state.reports.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        itemBuilder: (context, index) {
                          final report = state.reports[index];
                          return _ModerationTableRow(
                            report: report,
                            layout: layout,
                            isUpdating: state.updatingId == report.id,
                            onOpen: ReportTargetNavigation.canOpen(report)
                                ? () => ReportTargetNavigation.open(
                                      context,
                                      report,
                                    )
                                : null,
                          );
                        },
                      ),
              ),
              if (state.hasReachedMax && state.reports.isNotEmpty)
                _TableFooter(total: state.total),
              if (reportsUseDesktopPagination(
                MediaQuery.sizeOf(context).width,
              ))
                ReportsPaginationBar(
                  page: state.currentPage,
                  totalPages: state.lastPage,
                  total: state.total,
                  pageSize: 15,
                  itemCount: state.reports.length,
                  itemLabel: 'reports',
                  onPage: (page) => context.read<ReportsBloc>().add(
                        GoToReportsPageEvent(page),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ModerationTableLayout {
  const _ModerationTableLayout({
    required this.typeWidth,
    required this.compactStatus,
    required this.shortDate,
    required this.actionsAsMenu,
    required this.stackMeta,
    required this.hideReporter,
    required this.hideTarget,
  });

  final double typeWidth;
  final bool compactStatus;
  final bool shortDate;
  final bool actionsAsMenu;
  final bool stackMeta;
  final bool hideReporter;
  final bool hideTarget;

  static _ModerationTableLayout fromWidth(double width) {
    if (width >= 1080) {
      return const _ModerationTableLayout(
        typeWidth: 72,
        compactStatus: false,
        shortDate: false,
        actionsAsMenu: false,
        stackMeta: false,
        hideReporter: false,
        hideTarget: false,
      );
    }
    if (width >= 860) {
      return const _ModerationTableLayout(
        typeWidth: 64,
        compactStatus: true,
        shortDate: true,
        actionsAsMenu: false,
        stackMeta: false,
        hideReporter: false,
        hideTarget: false,
      );
    }
    if (width >= 680) {
      return const _ModerationTableLayout(
        typeWidth: 56,
        compactStatus: true,
        shortDate: true,
        actionsAsMenu: true,
        stackMeta: true,
        hideReporter: false,
        hideTarget: false,
      );
    }
    return const _ModerationTableLayout(
      typeWidth: 52,
      compactStatus: true,
      shortDate: true,
      actionsAsMenu: true,
      stackMeta: true,
      hideReporter: true,
      hideTarget: true,
    );
  }

  String formatDate(DateTime date) {
    if (shortDate) {
      return DateFormat('dd MMM yy · HH:mm').format(date);
    }
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}

class _ModerationSummaryBar extends StatelessWidget {
  const _ModerationSummaryBar({
    required this.showing,
    required this.total,
    required this.pending,
  });

  final int showing;
  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          _SummaryPill(
            label: l10n.t('showingLabel'),
            value: '$showing / $total',
            color: scheme.onSurface,
            bg: scheme.surfaceContainerHighest,
          ),
          const SizedBox(width: 8),
          _SummaryPill(
            label: l10n.t('pending'),
            value: '$pending',
            color: scheme.onTertiaryContainer,
            bg: scheme.tertiaryContainer,
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label · $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ModerationTableHeader extends StatelessWidget {
  const _ModerationTableHeader({
    required this.scheme,
    required this.layout,
  });

  final ColorScheme scheme;
  final _ModerationTableLayout layout;

  TextStyle get _style => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.45,
        color: scheme.onSurfaceVariant,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: layout.stackMeta
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: layout.typeWidth,
                      child: Text(l10n.t('columnType'), style: _style),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(l10n.t('reportReason'), style: _style),
                    ),
                    if (!layout.hideReporter)
                      Expanded(
                        flex: 2,
                        child: Text(l10n.t('reporter'), style: _style),
                      ),
                    if (!layout.hideTarget)
                      Expanded(
                        flex: 2,
                        child: Text(l10n.t('target'), style: _style),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: layout.actionsAsMenu ? 36 : 88,
                      child: Text(l10n.t('status'), style: _style),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: layout.shortDate ? 108 : 128,
                      child: Text(l10n.t('columnDate'), style: _style),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: layout.actionsAsMenu ? 36 : 96,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(l10n.t('actions'), style: _style),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: layout.typeWidth,
                  child: Text(l10n.t('columnType'), style: _style),
                ),
                Expanded(
                  flex: 3,
                  child: Text(l10n.t('reportReason'), style: _style),
                ),
                if (!layout.hideReporter)
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('reporter'), style: _style),
                  ),
                if (!layout.hideTarget)
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('target'), style: _style),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.t('status'), style: _style),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.t('columnDate'), style: _style),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(l10n.t('actions'), style: _style),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModerationTableRow extends StatefulWidget {
  const _ModerationTableRow({
    required this.report,
    required this.layout,
    required this.isUpdating,
    this.onOpen,
  });

  final ReportEntity report;
  final _ModerationTableLayout layout;
  final bool isUpdating;
  final VoidCallback? onOpen;

  @override
  State<_ModerationTableRow> createState() => _ModerationTableRowState();
}

class _ModerationTableRowState extends State<_ModerationTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final report = widget.report;
    final layout = widget.layout;
    final (typeIcon, typeColor) =
        ReportCardTheme.targetTypeVisual(scheme, report.targetType);
    final dateText = layout.formatDate(report.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onOpen != null && !widget.isUpdating
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Material(
        color: _hovered
            ? scheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.isUpdating ? null : widget.onOpen,
          child: AnimatedOpacity(
            opacity: widget.isUpdating ? 0.55 : 1,
            duration: ReportCardTheme.animDuration,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
              child: layout.stackMeta
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ModerationPrimaryCells(
                          report: report,
                          layout: layout,
                          typeIcon: typeIcon,
                          typeColor: typeColor,
                        ),
                        const SizedBox(height: 8),
                        _ModerationMetaCells(
                          report: report,
                          layout: layout,
                          dateText: dateText,
                          isUpdating: widget.isUpdating,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ..._ModerationPrimaryCells.buildWidgets(
                          context: context,
                          report: report,
                          layout: layout,
                          typeIcon: typeIcon,
                          typeColor: typeColor,
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ReportStatusChip(
                              status: report.status,
                              compact: layout.compactStatus,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            dateText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ReportActionBar(
                            report: report,
                            isUpdating: widget.isUpdating,
                            dense: true,
                            overflowMenu: layout.actionsAsMenu,
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

class _ModerationPrimaryCells extends StatelessWidget {
  const _ModerationPrimaryCells({
    required this.report,
    required this.layout,
    required this.typeIcon,
    required this.typeColor,
  });

  final ReportEntity report;
  final _ModerationTableLayout layout;
  final IconData typeIcon;
  final Color typeColor;

  static List<Widget> buildWidgets({
    required BuildContext context,
    required ReportEntity report,
    required _ModerationTableLayout layout,
    required IconData typeIcon,
    required Color typeColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return [
      SizedBox(
        width: layout.typeWidth,
        child: Row(
          children: [
            Icon(typeIcon, size: 15, color: typeColor),
            if (layout.typeWidth >= 64) ...[
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.targetType.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          report.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            height: 1.25,
          ),
        ),
      ),
      if (!layout.hideReporter)
        Expanded(
          flex: 2,
          child: Text(
            report.reporter?.displayName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      if (!layout.hideTarget)
        Expanded(
          flex: 2,
          child: Text(
            _targetLabel(report, l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildWidgets(
        context: context,
        report: report,
        layout: layout,
        typeIcon: typeIcon,
        typeColor: typeColor,
      ),
    );
  }

  static String _targetLabel(ReportEntity report, AppLocalizations l10n) {
    return switch (report.targetType) {
      'user' =>
        report.reportedUser?.username != null
            ? '@${report.reportedUser!.username}'
            : (report.reportedUser?.displayName ??
                report.reportedUserId ??
                '—'),
      'post' =>
        report.post?.description?.isNotEmpty == true
            ? report.post!.description!
            : (report.postId ?? report.post?.id ?? '—'),
      'comment' => l10n.tArgs(
          'reportCommentTarget',
          {'id': report.commentId ?? '—'},
        ),
      _ => '—',
    };
  }
}

class _ModerationMetaCells extends StatelessWidget {
  const _ModerationMetaCells({
    required this.report,
    required this.layout,
    required this.dateText,
    required this.isUpdating,
  });

  final ReportEntity report;
  final _ModerationTableLayout layout;
  final String dateText;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        const Spacer(),
        ReportStatusChip(
          status: report.status,
          compact: layout.compactStatus,
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: layout.shortDate ? 120 : 140,
          ),
          child: Text(
            dateText,
            maxLines: 2,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: layout.actionsAsMenu ? 36 : 112,
          child: ReportActionBar(
            report: report,
            isUpdating: isUpdating,
            dense: true,
            overflowMenu: layout.actionsAsMenu,
          ),
        ),
      ],
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Center(
        child: Text(
          l10n.tArgs('allReportsLoaded', {'total': '$total'}),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ReportsCardList extends StatelessWidget {
  const _ReportsCardList({
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
                onTap: ReportTargetNavigation.canOpen(state.reports[index])
                    ? () => ReportTargetNavigation.open(
                          context,
                          state.reports[index],
                        )
                    : () {},
              ),
            ),
            childCount: state.reports.length,
          ),
        ),
        if (state.isLoadingMore)
          SliverToBoxAdapter(
            child: ReportsLoadMoreFooter(isLoading: true),
          ),
        if (reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width) &&
            state.hasReachedMax &&
            state.reports.isNotEmpty)
          SliverToBoxAdapter(
            child: ReportsLoadMoreFooter(
              hasReachedMax: true,
              total: state.total,
            ),
          ),
        if (!reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width))
          SliverToBoxAdapter(
            child: ReportsPaginationBar(
              page: state.currentPage,
              totalPages: state.lastPage,
              total: state.total,
              pageSize: 15,
              itemCount: state.reports.length,
              itemLabel: 'reports',
              showTopBorder: false,
              onPage: (page) => context.read<ReportsBloc>().add(
                    GoToReportsPageEvent(page),
                  ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _ModerationToolbar extends StatelessWidget {
  const _ModerationToolbar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: BlocSelector<ReportsBloc, ReportsState, (int, int)?>(
            selector: (s) {
              if (s is! ReportsLoaded) return null;
              return (s.reports.length, s.total);
            },
            builder: (_, counts) {
              final label = counts == null
                  ? ''
                  : l10n.tArgs('showingReportsCount', {
                      'shown': '${counts.$1}',
                      'total': '${counts.$2}',
                    });
              return Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          child: IconButton(
            onPressed: () =>
                context.read<ReportsBloc>().add(RefreshReportsEvent()),
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: l10n.t('refresh'),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  bool _showAdvanced = false;
  final _searchController = TextEditingController();
  final _reporterIdController = TextEditingController();
  final _reportedUserIdController = TextEditingController();
  final _postIdController = TextEditingController();
  final _commentIdController = TextEditingController();
  final _storyIdController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _reporterIdController.dispose();
    _reportedUserIdController.dispose();
    _postIdController.dispose();
    _commentIdController.dispose();
    _storyIdController.dispose();
    super.dispose();
  }

  void _applyAdvanced(BuildContext context, ReportsQueryParams base) {
    context.read<ReportsBloc>().add(
          FilterReportsEvent(
            status: base.status,
            type: base.type,
            reporterId: _reporterIdController.text.trim().isEmpty
                ? null
                : _reporterIdController.text.trim(),
            reportedUserId: _reportedUserIdController.text.trim().isEmpty
                ? null
                : _reportedUserIdController.text.trim(),
            postId: _postIdController.text.trim().isEmpty
                ? null
                : _postIdController.text.trim(),
            commentId: _commentIdController.text.trim().isEmpty
                ? null
                : _commentIdController.text.trim(),
            storyId: _storyIdController.text.trim().isEmpty
                ? null
                : _storyIdController.text.trim(),
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            sortBy: base.sortBy,
            sortOrder: base.sortOrder,
            startDate: base.startDate,
            endDate: base.endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final statusFilters = ModerationFilterLabels.statusOptions(l10n);
    final typeFilters = ModerationFilterLabels.typeOptions(l10n);

    return BlocBuilder<ReportsBloc, ReportsState>(
      buildWhen: (prev, next) {
        if (prev is ReportsLoaded && next is ReportsLoaded) {
          return prev.filters != next.filters;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        final filters =
            state is ReportsLoaded ? state.filters : const ReportsQueryParams();
        final activeStatus = filters.status;
        final activeType = filters.type;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statusFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = statusFilters[i];
                  final selected = activeStatus == f.value;
                  final color =
                      ReportCardTheme.reportStatusColor(scheme, f.value);
                  return _FilterChip(
                    label: f.label,
                    isSelected: selected,
                    accentColor: color,
                    onTap: () => context.read<ReportsBloc>().add(
                          FilterReportsEvent(
                            status: f.value,
                            type: activeType,
                            resetStatus: f.value == null,
                          ),
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: typeFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final f = typeFilters[i];
                  final selected = activeType == f.value;
                  return _FilterChip(
                    label: f.label,
                    isSelected: selected,
                    small: true,
                    onTap: () => context.read<ReportsBloc>().add(
                          FilterReportsEvent(
                            status: activeStatus,
                            type: f.value,
                            resetType: f.value == null,
                          ),
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(
                _showAdvanced ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(l10n.tOr('advancedFilters', 'Advanced filters')),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: l10n.t('search'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _reporterIdController,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('reporterId', 'Reporter ID'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _reportedUserIdController,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('reportedUserId', 'Reported User ID'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _postIdController,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('postId', 'Post ID'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _commentIdController,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('commentId', 'Comment ID'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _storyIdController,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('storyId', 'Story ID'),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filters.sortBy,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('sortBy', 'Sort By'),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.tOr('defaultSort', 'Default')),
                        ),
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text(l10n.tOr('createdAt', 'Created At')),
                        ),
                        DropdownMenuItem(
                          value: 'updatedAt',
                          child: Text(l10n.tOr('updatedAt', 'Updated At')),
                        ),
                        DropdownMenuItem(
                          value: 'status',
                          child: Text(l10n.t('status')),
                        ),
                        DropdownMenuItem(
                          value: 'reason',
                          child: Text(l10n.tOr('reason', 'Reason')),
                        ),
                      ],
                      onChanged: (value) => context.read<ReportsBloc>().add(
                            FilterReportsEvent(
                              status: activeStatus,
                              type: activeType,
                              sortBy: value,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filters.sortOrder,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('sortOrder', 'Sort Order'),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.tOr('defaultSort', 'Default')),
                        ),
                        DropdownMenuItem(
                          value: 'NEWEST',
                          child: Text(l10n.tOr('newest', 'Newest')),
                        ),
                        DropdownMenuItem(
                          value: 'OLDEST',
                          child: Text(l10n.tOr('oldest', 'Oldest')),
                        ),
                        DropdownMenuItem(
                          value: 'ASC',
                          child: Text(l10n.tOr('ascending', 'Ascending')),
                        ),
                        DropdownMenuItem(
                          value: 'DESC',
                          child: Text(l10n.tOr('descending', 'Descending')),
                        ),
                      ],
                      onChanged: (value) => context.read<ReportsBloc>().add(
                            FilterReportsEvent(
                              status: activeStatus,
                              type: activeType,
                              sortOrder: value,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => _applyAdvanced(context, filters),
                    child: Text(l10n.t('apply')),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      _reporterIdController.clear();
                      _reportedUserIdController.clear();
                      _postIdController.clear();
                      _commentIdController.clear();
                      _storyIdController.clear();
                      context.read<ReportsBloc>().add(
                            FilterReportsEvent(
                              status: activeStatus,
                              type: activeType,
                              clearAdvanced: true,
                            ),
                          );
                    },
                    child: Text(l10n.tOr('clearFilters', 'Clear filters')),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
    this.small = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final bool small;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;

    final bg = widget.isSelected
        ? accent.withValues(alpha: 0.14)
        : _hovered
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow;
    final fg = widget.isSelected ? accent : scheme.onSurfaceVariant;
    final border = widget.isSelected ? accent : scheme.outlineVariant;

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
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.t('recentReports'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('noReportsMatchFilter'),
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<ReportsBloc>().add(RefreshReportsEvent()),
              child: Text(l10n.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
