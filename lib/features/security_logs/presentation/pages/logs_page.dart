import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../../gifts/presentation/widgets/gifts_filter_button.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../rbac/presentation/widgets/access_denied_view.dart';
import '../../domain/entities/log_entity.dart';
import '../bloc/logs_bloc.dart';
import '../bloc/logs_event.dart';
import '../bloc/logs_state.dart';
import '../utils/logs_labels.dart';
import '../utils/logs_responsive.dart';
import '../widgets/logs_export_button.dart';
import '../widgets/logs_filter_popup.dart';
import '../widgets/logs_table.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessDeniedPermissionGate(
      permission: RbacPermissionKeys.activityAdminRead,
      child: PersistentBlocProvider<LogsBloc>(
        debugLabel: 'SecurityLogsPage',
        create: () => di.sl<LogsBloc>()..add(const LoadLogsEvent()),
        child: const _LogsPageView(),
      ),
    );
  }
}

class _LogsPageView extends StatelessWidget {
  const _LogsPageView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics =
            LogsLayoutMetrics(getLogsDeviceType(constraints.maxWidth));

        return BlocConsumer<LogsBloc, LogsState>(
          listenWhen: (prev, curr) {
            if (curr is! LogsLoaded) return false;
            final prevLoaded = prev is LogsLoaded ? prev : null;
            final hasNewError = curr.errorMessage != null &&
                prevLoaded?.errorMessage != curr.errorMessage;
            final hasNewExportMessage = curr.exportMessage != null &&
                prevLoaded?.exportMessage != curr.exportMessage;
            return hasNewError || hasNewExportMessage;
          },
          listener: (context, state) {
            if (state is! LogsLoaded) return;
            final scheme = Theme.of(context).colorScheme;

            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: scheme.error,
                  ),
                );
              context.read<LogsBloc>().add(const ClearLogsMessageEvent());
            } else if (state.exportMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.exportMessage!),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        state.exportIsError ? scheme.error : scheme.primary,
                  ),
                );
              context.read<LogsBloc>().add(const ClearLogsExportMessageEvent());
            }
          },
          builder: (context, state) {
            final loaded = state is LogsLoaded ? state : null;
            final isInitialLoad = state is LogsInitial || state is LogsLoading;
            final isRefreshing = loaded?.isRefreshing == true;
            final compactHeader = metrics.isMobile;

            final titleStyle = (compactHeader
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(fontWeight: FontWeight.w800);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding,
                metrics.pageHorizontalPadding,
                metrics.pageBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.tOr('securityLogsTitle', 'Logs'),
                          style: titleStyle,
                        ),
                      ),
                      LogsExportButton(
                        height: 42,
                        isExporting: loaded?.isExporting == true,
                        enabled: loaded != null && !isInitialLoad,
                      ),
                      const SizedBox(width: 8),
                      _LogsFilterButton(
                        query: loaded?.query,
                        enabled: loaded != null,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.tOr('refresh', 'Refresh'),
                        onPressed: isInitialLoad
                            ? null
                            : () => context
                                .read<LogsBloc>()
                                .add(const RefreshLogsEvent()),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (loaded?.query.hasActiveFilters == true) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    _LogsActiveFilterChips(query: loaded!.query),
                  ],
                  if (isInitialLoad || isRefreshing) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(height: metrics.sectionGap),
                  Expanded(
                    child: switch (state) {
                      LogsError(:final message) => Center(
                          child: ErrorView(
                            message: message,
                            retryLabel: l10n.t('retry'),
                            onRetry: () => context
                                .read<LogsBloc>()
                                .add(const LoadLogsEvent()),
                          ),
                        ),
                      LogsInitial() || LogsLoading() =>
                        const Center(child: LoadingView()),
                      LogsLoaded() => LogsTable(
                          state: loaded!,
                          metrics: metrics,
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LogsFilterButton extends StatelessWidget {
  const _LogsFilterButton({
    required this.query,
    required this.enabled,
  });

  final LogsQuery? query;
  final bool enabled;

  int get _activeCount {
    final q = query;
    if (q == null) return 0;
    var count = 0;
    if (q.userId != null && q.userId!.trim().isNotEmpty) count++;
    if (q.actorRole != null && q.actorRole!.trim().isNotEmpty) count++;
    if (q.category != null && q.category!.trim().isNotEmpty) count++;
    if (q.action != null && q.action!.trim().isNotEmpty) count++;
    if (q.from != null || q.to != null) count++;
    if (q.limit != 50) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = query ?? const LogsQuery();

    return Builder(
      builder: (buttonContext) {
        return Opacity(
          opacity: enabled ? 1 : 0.55,
          child: IgnorePointer(
            ignoring: !enabled,
            child: GiftsFilterButton(
              activeCount: _activeCount,
              height: 42,
              onPressed: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                final size = box?.size ?? Size.zero;
                showLogsFilterPopup(
                  context: buttonContext,
                  query: currentQuery,
                  anchorRect: Rect.fromLTWH(
                    origin.dx,
                    origin.dy,
                    size.width,
                    size.height,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LogsActiveFilterChips extends StatelessWidget {
  const _LogsActiveFilterChips({required this.query});

  final LogsQuery query;

  /// Ban + Unban share one API filter: `?action=USER_BAN`.
  bool get _isBanUnbanFilter {
    final action = query.action?.trim().toUpperCase();
    return action == 'USER_BAN' ||
        action == 'USER_UNBAN' ||
        action == 'BAN_USER' ||
        action == 'UNBAN_USER' ||
        action == 'BAN' ||
        action == 'UNBAN';
  }

  void _clearAction(BuildContext context) {
    context.read<LogsBloc>().add(const LogsActionChangedEvent(null));
  }

  void _reapplyWithoutDates(BuildContext context) {
    final action = _isBanUnbanFilter ? 'USER_BAN' : query.action;
    context.read<LogsBloc>().add(
          LogsApplyFiltersEvent(
            user: query.user,
            userId: query.userId,
            actorRole: query.actorRole,
            // Ban/Unban must not send category — only `action=USER_BAN`.
            category: _isBanUnbanFilter ? null : query.category,
            action: action,
            limit: query.limit,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (query.user != null)
          InputChip(
            label: Text(query.user!.username),
            onDeleted: () => context
                .read<LogsBloc>()
                .add(const LogsUserChangedEvent(null)),
          ),
        if (query.actorRole != null && query.actorRole!.trim().isNotEmpty)
          InputChip(
            label: Text(logsActorRoleLabel(l10n, query.actorRole)),
            onDeleted: () => context
                .read<LogsBloc>()
                .add(const LogsActorRoleChangedEvent(null)),
          ),
        if (!_isBanUnbanFilter &&
            query.category != null &&
            query.category!.trim().isNotEmpty)
          InputChip(
            label: Text(logsCategoryLabel(l10n, query.category)),
            onDeleted: () => context
                .read<LogsBloc>()
                .add(const LogsCategoryChangedEvent(null)),
          ),
        if (query.action != null && query.action!.trim().isNotEmpty)
          InputChip(
            label: Text(
              _isBanUnbanFilter
                  ? l10n.tOr('logsActionBanUnban', 'Ban / Unban')
                  : logsActionCodeLabel(l10n, query.action),
            ),
            onDeleted: () => _clearAction(context),
          ),
        if (query.from != null || query.to != null)
          InputChip(
            label: Text(
              [
                if (query.from != null)
                  dateFmt.format(query.from!.toLocal()),
                if (query.to != null) dateFmt.format(query.to!.toLocal()),
              ].join(' – '),
            ),
            onDeleted: () => _reapplyWithoutDates(context),
          ),
      ],
    );
  }
}
