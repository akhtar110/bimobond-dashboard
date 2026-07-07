import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/user_report_entities.dart';
import '../../../reports/presentation/widgets/report_safe_media.dart';
import '../../../reports/presentation/utils/reports_responsive.dart';
import '../../../reports/presentation/widgets/reports_pagination_bar.dart';
import '../bloc/user_reports_bloc.dart';

class UserReportsTab extends StatefulWidget {
  const UserReportsTab({
    super.key,
    this.denseLayout = false,
    required this.onUserTap,
  });

  final bool denseLayout;
  final ValueChanged<String> onUserTap;

  @override
  State<UserReportsTab> createState() => _UserReportsTabState();
}

class _UserReportsTabState extends State<UserReportsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _horizontalScrollController = ScrollController();
  final _listScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
  }

  void _onListScroll() {
    if (!mounted) return;
    if (!reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width)) return;
    if (!reportsShouldLoadMore(_listScrollController)) return;
    context.read<UserReportsBloc>().add(const LoadMore());
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onListScroll);
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<UserReportsBloc>();

    void clearAllFilters() {
      _searchController.clear();
      bloc.add(const SearchChanged(''));
      bloc.add(
        const FilterChanged(
          clearVerified: true,
          clearBanned: true,
          clearRole: true,
        ),
      );
      bloc.add(const SortChanged(UserReportSort.newest));
      bloc.add(const LoadList(refresh: true));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.denseLayout)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _UserReportsFiltersBar(
              compact: true,
              onClearAll: clearAllFilters,
            ),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
            child: _Toolbar(
              searchController: _searchController,
              onSearchChanged: (value) => context.read<UserReportsBloc>().add(
                    SearchChanged(value),
                  ),
              onClearAll: clearAllFilters,
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              widget.denseLayout ? 0 : 12,
              0,
              widget.denseLayout ? 0 : 12,
              widget.denseLayout ? 0 : 12,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(widget.denseLayout ? 0 : 12),
                color: scheme.surface,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(widget.denseLayout ? 0 : 12),
                child: BlocBuilder<UserReportsBloc, UserReportsState>(
                  builder: (context, state) {
                        if (state is UserReportsError) {
                          return _StatePanel(
                            icon: Icons.cloud_off_rounded,
                            title: context.l10n.t('errorOccurred'),
                            message: state.message,
                            onRetry: () => context.read<UserReportsBloc>().add(
                                  const LoadList(refresh: true),
                                ),
                          );
                        }

                        if (state is UserReportsInitial ||
                            (state is UserReportsLoading &&
                                state.previous == null)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final loaded = switch (state) {
                          UserReportsLoaded() => state,
                          UserReportsLoading(:final previous) => previous!,
                          _ => null,
                        };

                        if (loaded == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return _LoadedTable(
                          state: loaded,
                          horizontalScrollController:
                              _horizontalScrollController,
                          listScrollController: _listScrollController,
                          onUserTap: widget.onUserTap,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final search = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: context.l10n.t('searchUsers'),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        );

        final filters = _UserReportsFiltersBar(
          compact: false,
          onClearAll: onClearAll,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 12), filters],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: filters),
          ],
        );
      },
    );
  }
}

class _UserReportsFiltersBar extends StatelessWidget {
  const _UserReportsFiltersBar({
    required this.compact,
    required this.onClearAll,
  });

  final bool compact;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserReportsBloc>();
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<UserReportsBloc, UserReportsState>(
      buildWhen: (prev, next) {
        final prevQuery =
            prev is UserReportsLoaded ? prev.query : const UserReportListQuery();
        final nextQuery =
            next is UserReportsLoaded ? next.query : const UserReportListQuery();
        return prevQuery != nextQuery;
      },
      builder: (context, state) {
        final query =
            state is UserReportsLoaded ? state.query : const UserReportListQuery();
        final isAllSelected = query.search.trim().isEmpty &&
            query.isVerified == null &&
            query.isBanned == null &&
            query.role == null &&
            query.sort == UserReportSort.newest;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(
                context.l10n.t('all'),
                style: TextStyle(
                  color: isAllSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
              selected: isAllSelected,
              backgroundColor: scheme.surface,
              selectedColor: scheme.primaryContainer,
              side: BorderSide(color: scheme.outlineVariant),
              checkmarkColor: scheme.primary,
              onSelected: (_) => onClearAll(),
            ),
            FilterChip(
              label: Text(
                context.l10n.t('verified'),
                style: TextStyle(
                  color:
                      query.isVerified == true ? scheme.primary : scheme.onSurface,
                ),
              ),
              selected: query.isVerified == true,
              backgroundColor: scheme.surface,
              selectedColor: scheme.primaryContainer,
              side: BorderSide(color: scheme.outlineVariant),
              checkmarkColor: scheme.primary,
              onSelected: (selected) => bloc.add(
                FilterChanged(
                  isVerified: selected ? true : null,
                  clearVerified: !selected,
                ),
              ),
            ),
            FilterChip(
              label: Text(
                context.l10n.t('banned'),
                style: TextStyle(
                  color: query.isBanned == true ? scheme.primary : scheme.onSurface,
                ),
              ),
              selected: query.isBanned == true,
              backgroundColor: scheme.surface,
              selectedColor: scheme.primaryContainer,
              side: BorderSide(color: scheme.outlineVariant),
              checkmarkColor: scheme.primary,
              onSelected: (selected) => bloc.add(
                FilterChanged(
                  isBanned: selected ? true : null,
                  clearBanned: !selected,
                ),
              ),
            ),
            _RoleFilterChip(
              selectedRole: query.role,
              onChanged: (role) => bloc.add(
                FilterChanged(
                  role: role,
                  clearRole: role == null,
                ),
              ),
            ),
            _SortDropdown(
              value: query.sort,
              onChanged: (sort) => bloc.add(SortChanged(sort)),
              compact: compact,
            ),
            TextButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text(context.l10n.t('clear')),
              style: TextButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.selectedRole,
    required this.onChanged,
  });

  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = switch (selectedRole) {
      'ADMIN' => l10n.t('roleAdmin'),
      'MODERATOR' => l10n.t('roleModerator'),
      'USER' => l10n.t('roleUser'),
      _ => 'Role',
    };

    return PopupMenuButton<String?>(
      tooltip: 'Role filter',
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text(l10n.t('all'))),
        PopupMenuItem(value: 'USER', child: Text(l10n.t('roleUser'))),
        PopupMenuItem(value: 'MODERATOR', child: Text(l10n.t('roleModerator'))),
        PopupMenuItem(value: 'ADMIN', child: Text(l10n.t('roleAdmin'))),
      ],
      child: Chip(
        avatar: Icon(
          Icons.badge_outlined,
          size: 18,
          color: selectedRole != null ? scheme.primary : scheme.onSurfaceVariant,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: selectedRole != null ? scheme.primary : scheme.onSurface,
          ),
        ),
        backgroundColor: selectedRole != null
            ? scheme.primaryContainer
            : scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final UserReportSort value;
  final ValueChanged<UserReportSort> onChanged;
  final bool compact;

  String _label(UserReportSort sort) => switch (sort) {
        UserReportSort.newest => 'New Users',
        UserReportSort.oldest => 'Old Users',
        UserReportSort.mostFollowers => 'Most Followers',
        UserReportSort.mostPosts => 'Most Posts',
        UserReportSort.mostLikes => 'Most Likes',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = value != UserReportSort.newest;

    return PopupMenuButton<UserReportSort>(
      tooltip: 'Sort users',
      onSelected: onChanged,
      itemBuilder: (context) => UserReportSort.values
          .map(
            (sort) => PopupMenuItem(
              value: sort,
              child: Text(
                _label(sort),
                style: TextStyle(
                  fontWeight:
                      value == sort ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: Chip(
        avatar: Icon(
          Icons.swap_vert_rounded,
          size: 18,
          color: isActive ? scheme.primary : scheme.onSurfaceVariant,
        ),
        label: Text(
          _label(value),
          style: TextStyle(
            color: isActive ? scheme.primary : scheme.onSurface,
          ),
        ),
        backgroundColor:
            isActive ? scheme.primaryContainer : scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }
}

class _LoadedTable extends StatelessWidget {
  const _LoadedTable({
    required this.state,
    required this.horizontalScrollController,
    required this.listScrollController,
    required this.onUserTap,
  });

  final UserReportsLoaded state;
  final ScrollController horizontalScrollController;
  final ScrollController listScrollController;
  final ValueChanged<String> onUserTap;

  @override
  Widget build(BuildContext context) {
    if (state.listLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return _StatePanel(
        icon: Icons.people_outline_rounded,
        title: context.l10n.t('noData'),
        message: context.l10n.t('tryAdjustFilters'),
        onRetry: () => context.read<UserReportsBloc>().add(
              const LoadList(refresh: true),
            ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = reportsMetricsOf(context);
    final minWidth = metrics.tableMinWidth > 0 ? metrics.tableMinWidth : null;

    return Column(
      children: [
        if (state.listLoadingMore)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = minWidth != null &&
                      constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;
              final needsScroll =
                  minWidth != null && constraints.maxWidth < tableWidth;

              return Scrollbar(
                controller: horizontalScrollController,
                thumbVisibility: needsScroll,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        if (!metrics.isMobile)
                          _TableHeader(scheme: scheme),
                        Expanded(
                          child: ListView.builder(
                            controller: listScrollController,
                            itemCount: state.items.length +
                                (metrics.useInfiniteScroll &&
                                        state.listLoadingMore
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.items.length) {
                                return const ReportsLoadMoreFooter(
                                  isLoading: true,
                                );
                              }
                              final user = state.items[index];
                              return _UserReportRow(
                                user: user,
                                compact: metrics.isMobile,
                                onTap: () => onUserTap(user.id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (metrics.useDesktopPagination)
          ReportsPaginationBar(
            page: state.currentPage,
            totalPages: state.lastPage,
            total: state.total,
            itemLabel: 'users',
            showTopBorder: true,
            onPage: (page) =>
                context.read<UserReportsBloc>().add(GoToPage(page)),
          )
        else if (state.hasReachedMax && state.items.isNotEmpty)
          ReportsLoadMoreFooter(
            hasReachedMax: true,
            total: state.total,
          ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 26, child: Text('User', style: style)),
          Expanded(flex: 12, child: Text('Followers', style: style)),
          Expanded(flex: 10, child: Text('Posts', style: style)),
          Expanded(flex: 10, child: Text('Likes', style: style)),
          Expanded(flex: 12, child: Text('Wallet', style: style)),
          Expanded(flex: 10, child: Text('Devices', style: style)),
          Expanded(flex: 12, child: Text('Status', style: style)),
        ],
      ),
    );
  }
}

class _UserReportRow extends StatelessWidget {
  const _UserReportRow({
    required this.user,
    required this.onTap,
    this.compact = false,
  });

  final UserReportListItemEntity user;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wallet = CoinFormat.coins(user.walletBalanceCoins);

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ReportSafeAvatar(
                  url: user.avatarUrl,
                  fallbackLabel: user.username,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '@${user.username} · ${user.followerCount} followers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: scheme.primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 26,
                child: Row(
                  children: [
                    ReportSafeAvatar(
                      url: user.avatarUrl,
                      fallbackLabel: user.username,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 12,
                child: Text('${user.followerCount}', style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 10,
                child: Text('${user.postCount}', style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 10,
                child: Text('${user.totalLikes}', style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 12,
                child: Text(wallet, style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 10,
                child: Text('${user.deviceCount}', style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 12,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.isVerified)
                          _Badge(
                            label: 'Verified',
                            color: scheme.primary,
                          ),
                        if (user.isVerified && user.isBanned)
                          const SizedBox(width: 6),
                        if (user.isBanned)
                          _Badge(label: 'Banned', color: scheme.error),
                        if ((user.isVerified || user.isBanned) &&
                            user.roles.isNotEmpty)
                          const SizedBox(width: 6),
                        if (user.roles.isNotEmpty)
                          _Badge(label: user.roles.first, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
