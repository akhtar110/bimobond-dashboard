import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_report_entities.dart';
import '../../../reports/presentation/widgets/report_safe_media.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.denseLayout)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _UserReportsFiltersBar(compact: true),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
            child: _Toolbar(
              searchController: _searchController,
              onSearchChanged: (value) => context.read<UserReportsBloc>().add(
                    SearchChanged(value),
                  ),
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
                color: isDark ? const Color(0xFF12151C) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE6E8EC),
                ),
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
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        );

        final filters = const _UserReportsFiltersBar(compact: false);

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
  const _UserReportsFiltersBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserReportsBloc>();

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

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(context.l10n.t('verified')),
              selected: query.isVerified == true,
              onSelected: (selected) => bloc.add(
                FilterChanged(
                  isVerified: selected ? true : null,
                  clearVerified: !selected,
                ),
              ),
            ),
            FilterChip(
              label: Text(context.l10n.t('banned')),
              selected: query.isBanned == true,
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
        avatar: const Icon(Icons.badge_outlined, size: 18),
        label: Text(label),
        backgroundColor: selectedRole != null
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
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
        UserReportSort.newest => 'Newest',
        UserReportSort.oldest => 'Oldest',
        UserReportSort.mostFollowers => 'Most followers',
        UserReportSort.mostPosts => 'Most posts',
        UserReportSort.mostLikes => 'Most likes',
      };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<UserReportSort>(
        value: value,
        isDense: compact,
        borderRadius: BorderRadius.circular(12),
        items: UserReportSort.values
            .map(
              (sort) => DropdownMenuItem(
                value: sort,
                child: Text(
                  _label(sort),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (sort) {
          if (sort != null) onChanged(sort);
        },
      ),
    );
  }
}

class _LoadedTable extends StatelessWidget {
  const _LoadedTable({
    required this.state,
    required this.horizontalScrollController,
    required this.onUserTap,
  });

  final UserReportsLoaded state;
  final ScrollController horizontalScrollController;
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
    const minWidth = 980.0;

    return Column(
      children: [
        if (state.listLoadingMore)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;
              final needsScroll = constraints.maxWidth < tableWidth;

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
                        _TableHeader(isDark: theme.brightness == Brightness.dark),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final user = state.items[index];
                              return _UserReportRow(
                                user: user,
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
        _PaginationBar(
          currentPage: state.currentPage,
          lastPage: state.lastPage,
          total: state.total,
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF1),
          ),
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
  });

  final UserReportListItemEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final wallet = NumberFormat.simpleCurrency().format(user.walletBalanceUsd);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: primary.withValues(alpha: isDark ? 0.06 : 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF1F5F9),
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
                              color: muted,
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
                          _Badge(label: 'Verified', color: Colors.blue),
                        if (user.isVerified && user.isBanned)
                          const SizedBox(width: 6),
                        if (user.isBanned)
                          _Badge(label: 'Banned', color: Colors.red),
                        if ((user.isVerified || user.isBanned) &&
                            user.roles.isNotEmpty)
                          const SizedBox(width: 6),
                        if (user.roles.isNotEmpty)
                          _Badge(label: user.roles.first, color: primary),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<UserReportsBloc>();
    final primary = theme.colorScheme.primary;

    final pages = <int>{
      for (var i = currentPage - 2; i <= currentPage + 2; i++)
        if (i >= 1 && i <= lastPage) i,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF1),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final pageControls = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageIconButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: currentPage > 1,
                  onTap: () => bloc.add(GoToPage(currentPage - 1)),
                ),
                const SizedBox(width: 6),
                for (final page in pages)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _PageNumberButton(
                      page: page,
                      isActive: page == currentPage,
                      primary: primary,
                      isDark: isDark,
                      onTap: () => bloc.add(GoToPage(page)),
                    ),
                  ),
                const SizedBox(width: 2),
                _PageIconButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: currentPage < lastPage,
                  onTap: () => bloc.add(GoToPage(currentPage + 1)),
                ),
              ],
            ),
          );

          final summary = Text(
            '$total users · Page $currentPage of $lastPage',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: pageControls,
                ),
              ],
            );
          }

          return Row(
            children: [
              Flexible(child: summary),
              const SizedBox(width: 12),
              pageControls,
            ],
          );
        },
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? primary : (isDark ? Colors.white10 : Colors.white),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          '$page',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : null,
              ),
        ),
      ),
    );
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
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
    final primary = theme.colorScheme.primary;

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
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
