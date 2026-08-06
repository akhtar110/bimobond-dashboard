import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../security_logs/data/datasources/user_audit_log_socket_service.dart';
import '../../../security_logs/data/datasources/user_violations_remote_datasource.dart';
import '../../../security_logs/presentation/bloc/user_violations_bloc.dart';
import '../../../security_logs/presentation/utils/log_target_navigation.dart';
import '../../../security_logs/presentation/utils/logs_labels.dart';
import '../../../security_logs/presentation/widgets/admin_and_violation_detail_dialogs.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../bloc/user_detail_state.dart';
import 'permission_denied_state.dart';

class UserDetailViolationsTab extends StatelessWidget {
  const UserDetailViolationsTab({
    super.key,
    required this.user,
    required this.isDark,
  });

  final UserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PermissionGate(
      permission: RbacPermissionKeys.activityAdminRead,
      allowLegacyAdmin: true,
      fallback: PermissionDeniedState(
        message: l10n.tOr(
          'userViolationsPermissionDenied',
          'You do not have permission to view user violations history.',
        ),
      ),
      child: BlocProvider<UserViolationsBloc>(
        create: (_) => UserViolationsBloc(
          userId: user.id,
          remoteDataSource: UserViolationsRemoteDataSourceImpl(di.sl()),
        )..add(const LoadUserViolationsEvent(page: 1)),
        child: BlocListener<UserDetailBloc, UserDetailState>(
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
            context.read<UserViolationsBloc>().add(const RefreshUserViolationsEvent());
          },
          child: _UserDetailViolationsView(isDark: isDark),
        ),
      ),
    );
  }
}

class _UserDetailViolationsView extends StatelessWidget {
  const _UserDetailViolationsView({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return BlocBuilder<UserViolationsBloc, UserViolationsState>(
      builder: (context, state) {
        if (state is UserViolationsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UserViolationsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<UserViolationsBloc>()
                        .add(const LoadUserViolationsEvent(page: 1)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.tOr('retry', 'Retry')),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is UserViolationsLoaded) {
          if (state.violations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 44,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.tOr('noViolationsFound', 'No community guideline violations found on record.'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final status = state.socketStatus;
          final isConnected = status == RealtimeSocketStatus.connected;
          final isReconnecting = status == RealtimeSocketStatus.reconnecting || status == RealtimeSocketStatus.connecting;

          final statusColor = isConnected
              ? Colors.green
              : isReconnecting
                  ? Colors.amber
                  : scheme.error;

          final statusText = isConnected
              ? l10n.tOr('liveStatus', 'LIVE')
              : isReconnecting
                  ? l10n.tOr('reconnectingStatus', 'RECONNECTING...')
                  : l10n.tOr('disconnectedStatus', 'DISCONNECTED');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${l10n.tOr('violationsHistoryTitle', 'Violations History')} (${state.meta.total})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 6, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (!isConnected && !isReconnecting)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () {
                                  context
                                      .read<UserViolationsBloc>()
                                      .add(const ReconnectViolationSocketEvent());
                                },
                                icon: const Icon(Icons.sync_problem_rounded, size: 14),
                                label: Text(l10n.tOr('reconnect', 'Reconnect'), style: const TextStyle(fontSize: 11)),
                              ),
                            IconButton(
                              tooltip: l10n.t('refresh'),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () {
                                context
                                    .read<UserViolationsBloc>()
                                    .add(const RefreshUserViolationsEvent());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tOr(
                        'violationsHistoryDescription',
                        'Record of community guidelines and terms of service breaches recorded against this account.',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.violations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.violations[index];
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    final actionLabel = logsDisplayTitle(l10n, item, isArabic: isArabic);
                    final categoryLabel = logsCategoryLabel(l10n, item.category);
                    final navTargets = LogTargetNavigation.resolveAll(item);

                    return Material(
                      color: isDark
                          ? scheme.surfaceContainerHigh
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => showViolationDetailDialog(context, item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: Colors.red,
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
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            categoryLabel,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
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
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description ?? item.displayTarget ?? '—',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
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
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 13,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.tOr('violationTag', 'VIOLATION'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
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
              if (state.meta.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: AppPaginationBar(
                    currentPage: state.meta.page,
                    lastPage: state.meta.totalPages,
                    total: state.meta.total,
                    pageSize: state.meta.limit,
                    itemCount: state.violations.length,
                    onPageChanged: (page) {
                      context
                          .read<UserViolationsBloc>()
                          .add(LoadUserViolationsEvent(page: page));
                    },
                  ),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
