import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../users_location_sort.dart';
import '../utils/responsive.dart';
import 'users_card_row.dart';
import 'users_load_more_indicators.dart';
import 'users_pagination_bar.dart';
import 'users_shimmer.dart';
import 'users_table_config.dart';
import 'users_table_header.dart';
import 'users_table_row.dart';

class UsersTablePanel extends StatelessWidget {
  const UsersTablePanel({
    super.key,
    required this.horizontalScrollController,
    required this.listScrollController,
    required this.metrics,
    required this.onUserTap,
  });

  final ScrollController horizontalScrollController;
  final ScrollController listScrollController;
  final UsersLayoutMetrics metrics;
  final void Function(UserEntity user) onUserTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BlocBuilder<UsersBloc, UsersState>(
          buildWhen: (previous, current) {
            if (current is ResetUserPasswordLoading ||
                current is ResetUserPasswordSuccess ||
                current is ResetUserPasswordFailure) {
              return false;
            }
            return true;
          },
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (state) {
                UsersLoading() => const SizedBox(
                  key: ValueKey('loading'),
                  height: double.infinity,
                  child: UsersTableSkeleton(),
                ),
                UsersError(:final message) => _StatePanel(
                  key: const ValueKey('error'),
                  icon: Icons.cloud_off_rounded,
                  title: l10n.t('errorOccurred'),
                  message: message,
                  actionLabel: l10n.t('retry'),
                  onAction: () => context.read<UsersBloc>().add(
                    LoadUsersEvent(refresh: true),
                  ),
                  isDestructive: false,
                ),
                UsersEmpty() => _StatePanel(
                  key: const ValueKey('empty'),
                  icon: Icons.people_outline_rounded,
                  title: l10n.t('noData'),
                  message: l10n.t('tryAdjustFilters'),
                  actionLabel: l10n.t('retry'),
                  onAction: () => context.read<UsersBloc>().add(
                    LoadUsersEvent(refresh: true),
                  ),
                  isDestructive: false,
                ),
                UsersLoaded() ||
                ResetUserPasswordLoading() ||
                ResetUserPasswordSuccess() ||
                ResetUserPasswordFailure() => _LoadedUsersContent(
                  key: const ValueKey('loaded'),
                  metrics: metrics,
                  listScrollController: listScrollController,
                  onUserTap: onUserTap,
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadedUsersContent extends StatelessWidget {
  const _LoadedUsersContent({
    super.key,
    required this.metrics,
    required this.listScrollController,
    required this.onUserTap,
  });

  final UsersLayoutMetrics metrics;
  final ScrollController listScrollController;
  final void Function(UserEntity user) onUserTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocSelector<UsersBloc, UsersState, int>(
      selector: (state) => state is UsersLoaded ? state.total : 0,
      builder: (context, total) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocSelector<UsersBloc, UsersState, bool>(
              selector: (state) =>
                  state is UsersLoaded && state.isRefreshing,
              builder: (context, isRefreshing) {
                if (!isRefreshing) return const SizedBox.shrink();
                return const LinearProgressIndicator(minHeight: 2);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Text(
                '$total ${l10n.t('users')}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: metrics.useCompactTable
                  ? _MobileCardList(
                      metrics: metrics,
                      listScrollController: listScrollController,
                      onUserTap: onUserTap,
                    )
                  : _DesktopTabletTable(
                      metrics: metrics,
                      listScrollController: listScrollController,
                      onUserTap: onUserTap,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileCardList extends StatelessWidget {
  const _MobileCardList({
    required this.metrics,
    required this.listScrollController,
    required this.onUserTap,
  });

  final UsersLayoutMetrics metrics;
  final ScrollController listScrollController;
  final void Function(UserEntity user) onUserTap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UsersBloc, UsersState, _UsersListData>(
      selector: (state) {
        if (state is! UsersLoaded) {
          return const _UsersListData.empty();
        }
        return _UsersListData(
          users: state.users,
          selectedUserIds: state.selectedUserIds,
          selectionEnabled: !state.isBulkActionLoading,
          isLoadingMore: state.isLoadingMore,
          hasReachedMax: state.hasReachedMax,
        );
      },
      builder: (context, data) {
        final itemCount =
            data.users.length +
            (data.isLoadingMore ? 1 : 0) +
            (data.hasReachedMax && data.users.isNotEmpty ? 1 : 0);

        return ListView.builder(
          controller: listScrollController,
          physics: metrics.listScrollPhysics,
          padding: EdgeInsets.fromLTRB(
            metrics.cardPadding - 4,
            0,
            metrics.cardPadding - 4,
            metrics.cardPadding,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < data.users.length) {
              final user = data.users[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: UsersCardRow(
                  key: ValueKey(user.id),
                  user: user,
                  isSelected: data.selectedUserIds.contains(user.id),
                  selectionEnabled: data.selectionEnabled,
                  onUserTap: () => onUserTap(user),
                ),
              );
            }

            if (data.isLoadingMore) {
              return const UsersLoadMoreIndicator();
            }

            return const UsersEndOfListLabel();
          },
        );
      },
    );
  }
}

class _DesktopTabletTable extends StatelessWidget {
  const _DesktopTabletTable({
    required this.metrics,
    required this.listScrollController,
    required this.onUserTap,
  });

  final UsersLayoutMetrics metrics;
  final ScrollController listScrollController;
  final void Function(UserEntity user) onUserTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final config = UsersTableConfig.fromConstraints(
                constraints.maxWidth,
                deviceType: metrics.deviceType,
              );

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocSelector<UsersBloc, UsersState, UsersLocationSortOrder>(
                      selector: (state) => state is UsersLoaded
                          ? state.locationSort
                          : UsersLocationSortOrder.none,
                      builder: (context, locationSort) {
                        return UsersTableHeader(
                          config: config,
                          locationSort: locationSort,
                          onLocationSortTap: () => context
                              .read<UsersBloc>()
                              .add(SortUsersLocationEvent()),
                        );
                      },
                    ),
                    Expanded(
                      child: _TableBody(
                        config: config,
                        listScrollController: listScrollController,
                        scrollPhysics: metrics.listScrollPhysics,
                        useInfiniteScroll: metrics.useInfiniteScroll,
                        onUserTap: onUserTap,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        BlocSelector<UsersBloc, UsersState, _PaginationData>(
          selector: (state) {
            if (state is! UsersLoaded) {
              return const _PaginationData.empty();
            }
            return _PaginationData(
              currentPage: state.currentPage,
              lastPage: state.lastPage,
              total: state.total,
              itemCount: state.users.length,
            );
          },
          builder: (context, data) {
            if (!data.visible) return const SizedBox.shrink();
            return UsersPaginationBar(
              currentPage: data.currentPage,
              lastPage: data.lastPage,
              total: data.total,
              itemCount: data.itemCount,
            );
          },
        ),
      ],
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.config,
    required this.listScrollController,
    required this.scrollPhysics,
    required this.useInfiniteScroll,
    required this.onUserTap,
  });

  final UsersTableConfig config;
  final ScrollController listScrollController;
  final ScrollPhysics scrollPhysics;
  final bool useInfiniteScroll;
  final void Function(UserEntity user) onUserTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<UsersBloc, UsersState, _UsersListData>(
      selector: (state) {
        if (state is! UsersLoaded) {
          return const _UsersListData.empty();
        }
        return _UsersListData(
          users: state.users,
          selectedUserIds: state.selectedUserIds,
          selectionEnabled: !state.isBulkActionLoading,
          isLoadingMore: state.isLoadingMore,
          hasReachedMax: state.hasReachedMax,
        );
      },
      builder: (context, data) {
        final trailingCount = useInfiniteScroll
            ? (data.isLoadingMore ? 1 : 0) +
                  (data.hasReachedMax && data.users.isNotEmpty ? 1 : 0)
            : 0;

        return ListView.separated(
          controller: listScrollController,
          physics: scrollPhysics,
          padding: EdgeInsets.zero,
          itemCount: data.users.length + trailingCount,
          separatorBuilder: (context, index) {
            if (index >= data.users.length - 1) {
              return const SizedBox.shrink();
            }
            return Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            );
          },
          itemBuilder: (context, index) {
            if (index < data.users.length) {
              final user = data.users[index];
              return UsersTableRow(
                key: ValueKey(user.id),
                user: user,
                config: config,
                striped: index.isOdd,
                isSelected: data.selectedUserIds.contains(user.id),
                selectionEnabled: data.selectionEnabled,
                onToggleSelection: (id) =>
                    context.read<UsersBloc>().add(ToggleUserSelectionEvent(id)),
                onUserTap: () => onUserTap(user),
              );
            }

            if (data.isLoadingMore) {
              return const UsersLoadMoreIndicator();
            }

            return const UsersEndOfListLabel();
          },
        );
      },
    );
  }
}

class _UsersListData {
  const _UsersListData({
    required this.users,
    required this.selectedUserIds,
    required this.selectionEnabled,
    required this.isLoadingMore,
    required this.hasReachedMax,
  });

  const _UsersListData.empty()
    : users = const [],
      selectedUserIds = const {},
      selectionEnabled = true,
      isLoadingMore = false,
      hasReachedMax = true;

  final List<UserEntity> users;
  final Set<String> selectedUserIds;
  final bool selectionEnabled;
  final bool isLoadingMore;
  final bool hasReachedMax;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _UsersListData) return false;
    if (other.users.length != users.length) return false;
    for (int i = 0; i < users.length; i++) {
      if (!identical(users[i], other.users[i])) return false;
    }
    return other.selectedUserIds == selectedUserIds &&
        other.selectionEnabled == selectionEnabled &&
        other.isLoadingMore == isLoadingMore &&
        other.hasReachedMax == hasReachedMax;
  }

  @override
  int get hashCode => Object.hash(
    users,
    selectedUserIds,
    selectionEnabled,
    isLoadingMore,
    hasReachedMax,
  );
}

class _PaginationData {
  const _PaginationData({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.itemCount,
  }) : visible = true;

  const _PaginationData.empty()
    : currentPage = 1,
      lastPage = 1,
      total = 0,
      itemCount = 0,
      visible = false;

  final int currentPage;
  final int lastPage;
  final int total;
  final int itemCount;
  final bool visible;
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.isDestructive,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.65),
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
