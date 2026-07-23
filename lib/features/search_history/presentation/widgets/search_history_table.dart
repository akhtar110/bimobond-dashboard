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

const double _kHeaderHeight = 36;
const double _kCellHPad = 6;

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
          striped: i.isOdd,
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
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                if (showProgress) const LinearProgressIndicator(minHeight: 2),
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
          fontSize: 10,
          letterSpacing: 0.2,
        );

    final showUser = showUserColumn &&
        density != SearchHistoryTableDensity.narrow;

    return Container(
      height: _kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: scheme.surfaceContainerLow,
      child: _RowLayout(
        density: density,
        showSelection: showSelection,
        showUser: showUser,
        selection: Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          onChanged: (_) => onSelectAll(),
        ),
        query: Text(
          l10n.tOr('searchHistoryQuery', 'Query'),
          style: style,
        ),
        category: Text(
          l10n.tOr('searchHistoryCategory', 'Category'),
          style: style,
        ),
        user: Text(l10n.t('users'), style: style),
        createdAt: Text(
          l10n.tOr('searchHistoryCreatedAt', 'Created at'),
          style: style,
        ),
        actions: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Shared column layout so header and rows always stay aligned.
class _RowLayout extends StatelessWidget {
  const _RowLayout({
    required this.density,
    required this.showSelection,
    required this.showUser,
    required this.selection,
    required this.query,
    required this.category,
    required this.user,
    required this.createdAt,
    required this.actions,
  });

  final SearchHistoryTableDensity density;
  final bool showSelection;
  final bool showUser;
  final Widget selection;
  final Widget query;
  final Widget category;
  final Widget user;
  final Widget createdAt;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final wide = density == SearchHistoryTableDensity.wide;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showSelection) SizedBox(width: 36, child: selection),
        Expanded(flex: wide ? 3 : 2, child: _cell(query)),
        Expanded(flex: 1, child: _cell(category)),
        if (showUser) Expanded(flex: wide ? 2 : 1, child: _cell(user)),
        Expanded(flex: 1, child: _cell(createdAt)),
        SizedBox(width: 40, child: Center(child: actions)),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _SearchHistoryTableRow extends StatefulWidget {
  const _SearchHistoryTableRow({
    required this.item,
    required this.density,
    required this.isSelected,
    required this.striped,
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
  final bool striped;
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
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );

    Color rowColor;
    if (widget.isSelected) {
      rowColor = scheme.primaryContainer.withValues(alpha: 0.18);
    } else if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: widget.isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _RowLayout(
              density: widget.density,
              showSelection: widget.showSelection,
              showUser: widget.showUserColumn &&
                  widget.density != SearchHistoryTableDensity.narrow,
              selection: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: widget.isSelected,
                onChanged: (_) => widget.onToggle(),
              ),
              query: Text(
                widget.item.query,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cellStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              category: SearchHistoryCategoryBadge(
                category: widget.item.category,
                compact: true,
              ),
              user: widget.item.user == null
                  ? Text(
                      '—',
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : _UserCell(
                      user: widget.item.user!,
                      onPressed: widget.onOpenUser,
                      cellStyle: cellStyle,
                    ),
              createdAt: Text(
                widget.dateFmt.format(widget.item.createdAt.toLocal()),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cellStyle?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              actions: AnimatedOpacity(
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
                    size: 18,
                    color: scheme.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-line user cell (name + @username), matching the locations table.
class _UserCell extends StatelessWidget {
  const _UserCell({
    required this.user,
    this.onPressed,
    this.cellStyle,
  });

  final SearchHistoryUserSummary user;
  final VoidCallback? onPressed;
  final TextStyle? cellStyle;

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
                radius: 12,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
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

    final rows = <Widget>[
      for (var i = 0; i < state.items.length; i++)
        _SearchHistoryCompactRow(
          item: state.items[i],
          isSelected: state.selectedIds.contains(state.items[i].id),
          isLast: i == state.items.length - 1,
          showUser: showUserColumn,
          showSelection: showSelection,
          dateFmt: dateFmt,
          onToggle: () =>
              bloc.add(ToggleSearchHistorySelection(state.items[i].id)),
          onDelete: () async {
            final confirmed = await showSearchHistoryDeleteDialog(context);
            if (confirmed == true && context.mounted) {
              bloc.add(DeleteSearchHistoryItem(state.items[i].id));
            }
          },
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight.isFinite;

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showProgress) const LinearProgressIndicator(minHeight: 2),
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
            ),
          ),
        );
      },
    );
  }
}

/// Mobile row styled like the locations compact list — flat rows with
/// bottom dividers inside one rounded container.
class _SearchHistoryCompactRow extends StatelessWidget {
  const _SearchHistoryCompactRow({
    required this.item,
    required this.isSelected,
    required this.isLast,
    required this.showUser,
    required this.showSelection,
    required this.dateFmt,
    required this.onToggle,
    required this.onDelete,
  });

  final SearchHistoryEntity item;
  final bool isSelected;
  final bool isLast;
  final bool showUser;
  final bool showSelection;
  final DateFormat dateFmt;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.18)
          : scheme.surface,
      child: InkWell(
        onTap: showSelection ? onToggle : null,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 4, 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showSelection)
                Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.query,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (showUser && item.user != null)
                          item.user!.displayName,
                        dateFmt.format(item.createdAt.toLocal()),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 5),
                    SearchHistoryCategoryBadge(
                      category: item.category,
                      compact: true,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('delete'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: scheme.error,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
