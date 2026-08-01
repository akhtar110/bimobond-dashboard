import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/log_entity.dart';
import '../bloc/logs_bloc.dart';
import '../bloc/logs_event.dart';
import '../bloc/logs_state.dart';
import '../utils/logs_labels.dart';
import '../utils/logs_responsive.dart';
import 'logs_detail_dialog.dart';

enum _LogsTableDensity { wide, medium, compact }

_LogsTableDensity _densityForWidth(double width) {
  if (width >= 1100) return _LogsTableDensity.wide;
  if (width >= 860) return _LogsTableDensity.medium;
  return _LogsTableDensity.compact;
}

class _LogsColumnSpec {
  const _LogsColumnSpec({
    required this.dateFlex,
    required this.userFlex,
    required this.roleFlex,
    required this.categoryFlex,
    required this.actionFlex,
    required this.targetFlex,
    required this.deviceFlex,
    required this.actionsWidth,
    required this.cellPad,
    required this.showRole,
    required this.showTarget,
    required this.showDevice,
  });

  final int dateFlex;
  final int userFlex;
  final int roleFlex;
  final int categoryFlex;
  final int actionFlex;
  final int targetFlex;
  final int deviceFlex;
  final double actionsWidth;
  final double cellPad;
  final bool showRole;
  final bool showTarget;
  final bool showDevice;
}

/// Fixed trailing width so EN/AR "Actions" headers are not clipped.
const double _kActionsColWidth = 112;

_LogsColumnSpec _columnSpec(_LogsTableDensity density) => switch (density) {
      _LogsTableDensity.wide => const _LogsColumnSpec(
          dateFlex: 3,
          userFlex: 3,
          roleFlex: 2,
          categoryFlex: 2,
          actionFlex: 3,
          targetFlex: 3,
          deviceFlex: 2,
          actionsWidth: _kActionsColWidth,
          cellPad: 10,
          showRole: true,
          showTarget: true,
          showDevice: true,
        ),
      _LogsTableDensity.medium => const _LogsColumnSpec(
          dateFlex: 3,
          userFlex: 3,
          roleFlex: 2,
          categoryFlex: 2,
          actionFlex: 3,
          targetFlex: 3,
          deviceFlex: 0,
          actionsWidth: _kActionsColWidth,
          cellPad: 8,
          showRole: true,
          showTarget: true,
          showDevice: false,
        ),
      _LogsTableDensity.compact => const _LogsColumnSpec(
          dateFlex: 3,
          userFlex: 3,
          roleFlex: 0,
          categoryFlex: 2,
          actionFlex: 3,
          targetFlex: 0,
          deviceFlex: 0,
          actionsWidth: _kActionsColWidth,
          cellPad: 6,
          showRole: false,
          showTarget: false,
          showDevice: false,
        ),
    };

class LogsTable extends StatelessWidget {
  const LogsTable({
    super.key,
    required this.state,
    required this.metrics,
  });

  final LogsLoaded state;
  final LogsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (state.logs.isEmpty) {
      final l10n = context.l10n;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tOr('logsEmptyTitle', 'No logs found'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.query.hasActiveFilters
                    ? l10n.tOr(
                        'logsEmptyFiltered',
                        'Try adjusting or resetting your filters.',
                      )
                    : l10n.tOr(
                        'logsEmptySubtitle',
                        'Security logs will appear here when available.',
                      ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (state.query.hasActiveFilters) ...[
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: () => context
                      .read<LogsBloc>()
                      .add(const LogsResetFiltersEvent()),
                  child: Text(l10n.tOr('logsResetFilters', 'Reset filters')),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Card list on phones / narrow panes; flex table above that.
        if (constraints.maxWidth < 680) {
          return _LogsCardList(state: state, metrics: metrics);
        }
        return _LogsDataTable(state: state, metrics: metrics);
      },
    );
  }
}

class _LogsDataTable extends StatelessWidget {
  const _LogsDataTable({
    required this.state,
    required this.metrics,
  });

  final LogsLoaded state;
  final LogsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final bloc = context.read<LogsBloc>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            if (state.isPaginating || state.isRefreshing)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final density = _densityForWidth(constraints.maxWidth);
                  final spec = _columnSpec(density);

                  return Column(
                    children: [
                      _Header(l10n: l10n, spec: spec),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.logs.length,
                          itemBuilder: (context, index) {
                            final log = state.logs[index];
                            return _Row(
                              log: log,
                              spec: spec,
                              striped: index.isOdd,
                              dateLabel:
                                  dateFmt.format(log.createdAt.toLocal()),
                                    onOpenUser: log.actorId == null ||
                                            log.actorId!.trim().isEmpty
                                        ? null
                                        : () => _openUser(context, log),
                              onDetails: () =>
                                  showLogsDetailDialog(context, log),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AppPaginationBar(
              currentPage: state.meta.page < 1 ? 1 : state.meta.page,
              lastPage: state.meta.totalPages < 1 ? 1 : state.meta.totalPages,
              total: state.meta.total,
              pageSize: state.meta.limit > 0 ? state.meta.limit : 50,
              itemCount: state.logs.length,
              hideWhenSinglePage: false,
              showTopBorder: true,
              onPageChanged: (page) =>
                  bloc.add(LogsPageChangedEvent(page)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n, required this.spec});

  final AppLocalizations l10n;
  final _LogsColumnSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
        );

    Widget cell(String text, {required int flex}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spec.cellPad, vertical: 12),
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return ColoredBox(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Row(
        children: [
          cell(l10n.tOr('logsColDate', 'Date / Time'), flex: spec.dateFlex),
          cell(l10n.tOr('logsColUser', 'User'), flex: spec.userFlex),
          if (spec.showRole)
            cell(
              l10n.tOr('logsColActorRole', 'Actor role'),
              flex: spec.roleFlex,
            ),
          cell(l10n.tOr('logsColCategory', 'Category'), flex: spec.categoryFlex),
          cell(l10n.tOr('logsColAction', 'Action'), flex: spec.actionFlex),
          if (spec.showTarget)
            cell(l10n.tOr('logsColTarget', 'Target'), flex: spec.targetFlex),
          if (spec.showDevice)
            cell(l10n.tOr('logsColDevice', 'Device'), flex: spec.deviceFlex),
          SizedBox(
            width: spec.actionsWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spec.cellPad,
                vertical: 12,
              ),
              child: Text(
                l10n.tOr('actions', 'Actions'),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.log,
    required this.spec,
    required this.striped,
    required this.dateLabel,
    required this.onOpenUser,
    required this.onDetails,
  });

  final LogEntity log;
  final _LogsColumnSpec spec;
  final bool striped;
  final String dateLabel;
  final VoidCallback? onOpenUser;
  final VoidCallback onDetails;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final spec = widget.spec;
    final bg = _hovered
        ? scheme.primary.withValues(alpha: 0.06)
        : (widget.striped
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.18)
            : scheme.surface);

    Widget cell(
      String text, {
      required int flex,
      bool mono = false,
      FontWeight weight = FontWeight.w600,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spec.cellPad, vertical: 12),
          child: Tooltip(
            message: text == '—' ? '' : text,
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              text,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: weight,
                    fontFamily: mono ? 'monospace' : null,
                  ),
            ),
          ),
        ),
      );
    }

    final userLabel = logsDash(widget.log.displayUser);
    final secondaryUser = widget.log.secondaryUserLabel;
    final userTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    Widget userCell() {
      final primary = widget.onOpenUser == null
          ? Text(
              userLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: userTextStyle,
            )
          : TextButton(
              onPressed: widget.onOpenUser,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: AlignmentDirectional.centerStart,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                userLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );

      if (secondaryUser == null) return primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          primary,
          Text(
            secondaryUser,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ColoredBox(
        color: bg,
        child: Row(
          children: [
            cell(widget.dateLabel, flex: spec.dateFlex),
            Expanded(
              flex: spec.userFlex,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spec.cellPad,
                  vertical: 8,
                ),
                child: userCell(),
              ),
            ),
            if (spec.showRole)
              cell(
                logsActorRoleLabel(l10n, widget.log.actorRole),
                flex: spec.roleFlex,
              ),
            cell(
              logsCategoryLabel(l10n, widget.log.category),
              flex: spec.categoryFlex,
            ),
            cell(logsActionLabel(l10n, widget.log), flex: spec.actionFlex),
            if (spec.showTarget)
              cell(
                logsDash(widget.log.displayTarget),
                flex: spec.targetFlex,
              ),
            if (spec.showDevice)
              cell(logsDash(widget.log.deviceId ?? widget.log.userAgent),
                  flex: spec.deviceFlex),
            SizedBox(
              width: spec.actionsWidth,
              child: Center(
                child: IconButton(
                  tooltip: l10n.tOr('logsViewDetails', 'View details'),
                  onPressed: widget.onDetails,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsCardList extends StatelessWidget {
  const _LogsCardList({
    required this.state,
    required this.metrics,
  });

  final LogsLoaded state;
  final LogsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final bloc = context.read<LogsBloc>();

    return Column(
      children: [
        if (state.isPaginating || state.isRefreshing)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.separated(
            itemCount: state.logs.length,
            separatorBuilder: (_, _) =>
                SizedBox(height: metrics.toolbarFilterGap),
            itemBuilder: (context, index) {
              final log = state.logs[index];
              return Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => showLogsDetailDialog(context, log),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.format(log.createdAt.toLocal()),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          logsDash(log.displayUser),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            logsActorRoleLabel(l10n, log.actorRole),
                            logsCategoryLabel(l10n, log.category),
                            logsActionLabel(l10n, log),
                          ].join(' · '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if ((log.displayTarget ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            log.displayTarget!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        AppPaginationBar(
          currentPage: state.meta.page < 1 ? 1 : state.meta.page,
          lastPage: state.meta.totalPages < 1 ? 1 : state.meta.totalPages,
          total: state.meta.total,
          pageSize: state.meta.limit > 0 ? state.meta.limit : 50,
          itemCount: state.logs.length,
          hideWhenSinglePage: false,
          showTopBorder: true,
          onPageChanged: (page) => bloc.add(LogsPageChangedEvent(page)),
        ),
      ],
    );
  }
}

void _openUser(BuildContext context, LogEntity log) {
  final id = log.actorId?.trim() ?? '';
  if (id.isEmpty) return;
  final fullName = log.userFullName?.trim();
  final username = log.userName?.trim();
  Navigator.pushNamed(
    context,
    AppRoutes.userDetail,
    arguments: UserEntity(
      id: id,
      username: (username != null && username.isNotEmpty)
          ? username
          : ((fullName != null && fullName.isNotEmpty) ? fullName : id),
      fullName: fullName,
      email: log.userEmail,
      avatarUrl: log.avatarUrl,
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
      roles: const [UserRole.user],
    ),
  );
}
