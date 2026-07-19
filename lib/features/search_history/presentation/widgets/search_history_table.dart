import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/search_history.dart';
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import '../bloc/search_history_state.dart';
import '../utils/search_history_responsive.dart';
import 'search_history_category_badge.dart';
import 'search_history_delete_dialog.dart';
import 'search_history_empty_state.dart';

enum SearchHistoryTableDensity { wide, medium, narrow }

SearchHistoryTableDensity searchHistoryTableDensityForWidth(double width) {
  if (width >= 1100) return SearchHistoryTableDensity.wide;
  if (width >= 720) return SearchHistoryTableDensity.medium;
  return SearchHistoryTableDensity.narrow;
}

class SearchHistoryTable extends StatelessWidget {
  const SearchHistoryTable({
    super.key,
    this.showUserColumn = true,
    this.showSelection = true,
    this.showProgress = false,
    this.metrics,
  });

  final bool showUserColumn;
  final bool showSelection;
  final bool showProgress;
  final SearchHistoryLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchHistoryBloc, SearchHistoryState>(
      builder: (context, state) {
        if (state is SearchHistoryLoaded) {
          if (state.items.isEmpty) {
            return SearchHistoryEmptyState(
              hasFilters: state.query.hasActiveFilters,
              onClearFilters: state.query.hasActiveFilters
                  ? () => context
                      .read<SearchHistoryBloc>()
                      .add(const ClearFilters())
                  : null,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final m = metrics ??
                  SearchHistoryLayoutMetrics(
                    getSearchHistoryDeviceType(constraints.maxWidth),
                  );
              final density =
                  searchHistoryTableDensityForWidth(constraints.maxWidth);
              if (density == SearchHistoryTableDensity.narrow) {
                return _SearchHistoryCardList(
                  state: state,
                  showUserColumn: showUserColumn,
                  showSelection: showSelection,
                  showProgress: showProgress,
                  metrics: m,
                );
              }
              return _SearchHistoryDataTable(
                state: state,
                density: density,
                showUserColumn: showUserColumn,
                showSelection: showSelection,
                showProgress: showProgress,
                metrics: m,
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SearchHistoryDataTable extends StatelessWidget {
  const _SearchHistoryDataTable({
    required this.state,
    required this.density,
    required this.showUserColumn,
    required this.showSelection,
    required this.showProgress,
    required this.metrics,
  });

  final SearchHistoryLoaded state;
  final SearchHistoryTableDensity density;
  final bool showUserColumn;
  final bool showSelection;
  final bool showProgress;
  final SearchHistoryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final bloc = context.read<SearchHistoryBloc>();
    final allSelected = state.items.isNotEmpty &&
        state.items.every((e) => state.selectedIds.contains(e.id));
    final someSelected = state.selectedIds.isNotEmpty && !allSelected;

    final rows = <Widget>[
      for (var i = 0; i < state.items.length; i++)
        _SearchHistoryTableRow(
          item: state.items[i],
          density: density,
          isSelected: state.selectedIds.contains(state.items[i].id),
          showUserColumn: showUserColumn,
          showSelection: showSelection,
          dateFmt: dateFmt,
          isLast: i == state.items.length - 1,
          onToggle: () => bloc.add(
            ToggleSearchHistorySelection(state.items[i].id),
          ),
          onDelete: () => _confirmDelete(context, state.items[i].id),
          onOpenUser: state.items[i].user == null
              ? null
              : () => _openUser(context, state.items[i].user!),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableHeaderRow(
                  density: density,
                  showUserColumn: showUserColumn,
                  showSelection: showSelection,
                  allSelected: allSelected,
                  someSelected: someSelected,
                  onSelectAll: () {
                    if (allSelected) {
                      bloc.add(const ClearSearchHistorySelection());
                    } else {
                      bloc.add(const SelectAllSearchHistory());
                    }
                  },
                ),
                if (showProgress) const LinearProgressIndicator(),
                if (boundedHeight)
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: rows,
                    ),
                  )
                else
                  ...rows,
                AppPaginationBar(
                  currentPage: state.meta.page < 1 ? 1 : state.meta.page,
                  lastPage: state.meta.totalPages < 1
                      ? 1
                      : state.meta.totalPages,
                  total: state.meta.total,
                  pageSize:
                      state.meta.limit > 0 ? state.meta.limit : 20,
                  itemCount: state.items.length,
                  hideWhenSinglePage: false,
                  showTopBorder: true,
                  onPageChanged: (page) {
                    if (state.isUserScoped) {
                      bloc.add(LoadUserSearchHistory(
                        userId: state.scopedUserId!,
                        page: page,
                      ));
                    } else {
                      bloc.add(LoadSearchHistory(page: page));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showSearchHistoryDeleteDialog(context);
    if (confirmed == true && context.mounted) {
      context.read<SearchHistoryBloc>().add(DeleteSearchHistoryItem(id));
    }
  }

  void _openUser(BuildContext context, SearchHistoryUserSummary user) {
    Navigator.pushNamed(
      context,
      AppRoutes.userDetail,
      arguments: UserEntity(
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        email: user.email,
        avatarUrl: user.avatarUrl,
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
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.density,
    required this.showUserColumn,
    required this.showSelection,
    required this.allSelected,
    required this.someSelected,
    required this.onSelectAll,
  });

  final SearchHistoryTableDensity density;
  final bool showUserColumn;
  final bool showSelection;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    final showUser = showUserColumn &&
        density != SearchHistoryTableDensity.narrow;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Row(
        children: [
          if (showSelection)
            SizedBox(
              width: 36,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: allSelected ? true : (someSelected ? null : false),
                tristate: true,
                onChanged: (_) => onSelectAll(),
              ),
            ),
          Expanded(
            flex: density == SearchHistoryTableDensity.wide ? 3 : 2,
            child: Text(
              l10n.tOr('searchHistoryQuery', 'Query'),
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              l10n.tOr('searchHistoryCategory', 'Category'),
              style: style,
            ),
          ),
          if (showUser)
            Expanded(
              flex: density == SearchHistoryTableDensity.wide ? 2 : 1,
              child: Text(l10n.t('users'), style: style),
            ),
          Expanded(
            child: Text(
              l10n.tOr('searchHistoryCreatedAt', 'Created at'),
              style: style,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SearchHistoryTableRow extends StatefulWidget {
  const _SearchHistoryTableRow({
    required this.item,
    required this.density,
    required this.isSelected,
    required this.showUserColumn,
    required this.showSelection,
    required this.dateFmt,
    required this.isLast,
    required this.onToggle,
    required this.onDelete,
    this.onOpenUser,
  });

  final SearchHistoryEntity item;
  final SearchHistoryTableDensity density;
  final bool isSelected;
  final bool showUserColumn;
  final bool showSelection;
  final DateFormat dateFmt;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onOpenUser;

  @override
  State<_SearchHistoryTableRow> createState() => _SearchHistoryTableRowState();
}

class _SearchHistoryTableRowState extends State<_SearchHistoryTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.18)
              : _hovered
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                  : null,
          border: widget.isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (widget.showSelection)
                SizedBox(
                  width: 36,
                  child: Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    value: widget.isSelected,
                    onChanged: (_) => widget.onToggle(),
                  ),
                ),
              Expanded(
                flex: widget.density == SearchHistoryTableDensity.wide ? 3 : 2,
                child: Text(
                  widget.item.query,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SearchHistoryCategoryBadge(
                    category: widget.item.category,
                    compact: true,
                  ),
                ),
              ),
              if (widget.showUserColumn &&
                  widget.density != SearchHistoryTableDensity.narrow)
                Expanded(
                  flex: widget.density == SearchHistoryTableDensity.wide ? 2 : 1,
                  child: widget.item.user == null
                      ? Text(
                          '—',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _UserChip(
                            user: widget.item.user!,
                            onPressed: widget.onOpenUser,
                            compact: widget.density ==
                                SearchHistoryTableDensity.medium,
                          ),
                        ),
                ),
              Expanded(
                child: Text(
                  widget.dateFmt.format(widget.item.createdAt.toLocal()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered || widget.isSelected ? 1 : 0.55,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  tooltip: context.l10n.t('delete'),
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error,
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

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.user,
    this.onPressed,
    this.compact = false,
  });

  final SearchHistoryUserSummary user;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = user.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            children: [
              CircleAvatar(
                radius: compact ? 9 : 10,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
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

class _SearchHistoryCardList extends StatelessWidget {
  const _SearchHistoryCardList({
    required this.state,
    required this.showUserColumn,
    required this.showSelection,
    required this.showProgress,
    required this.metrics,
  });

  final SearchHistoryLoaded state;
  final bool showUserColumn;
  final bool showSelection;
  final bool showProgress;
  final SearchHistoryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();
    final bloc = context.read<SearchHistoryBloc>();

    final cards = <Widget>[
      for (final item in state.items)
        Card(
          margin: EdgeInsets.only(bottom: metrics.filterGap),
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSelection)
                  Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    value: state.selectedIds.contains(item.id),
                    onChanged: (_) =>
                        bloc.add(ToggleSearchHistorySelection(item.id)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.query,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SearchHistoryCategoryBadge(
                            category: item.category,
                            compact: true,
                          ),
                          if (showUserColumn && item.user != null)
                            Text(
                              item.user!.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFmt.format(item.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error,
                  ),
                  onPressed: () async {
                    final confirmed =
                        await showSearchHistoryDeleteDialog(context);
                    if (confirmed == true && context.mounted) {
                      bloc.add(DeleteSearchHistoryItem(item.id));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showProgress) const LinearProgressIndicator(),
            if (boundedHeight)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: cards,
                ),
              )
            else
              ...cards,
            AppPaginationBar(
              currentPage: state.meta.page < 1 ? 1 : state.meta.page,
              lastPage:
                  state.meta.totalPages < 1 ? 1 : state.meta.totalPages,
              total: state.meta.total,
              pageSize: state.meta.limit > 0 ? state.meta.limit : 20,
              itemCount: state.items.length,
              hideWhenSinglePage: false,
              showTopBorder: true,
              onPageChanged: (page) {
                if (state.isUserScoped) {
                  bloc.add(LoadUserSearchHistory(
                    userId: state.scopedUserId!,
                    page: page,
                  ));
                } else {
                  bloc.add(LoadSearchHistory(page: page));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
