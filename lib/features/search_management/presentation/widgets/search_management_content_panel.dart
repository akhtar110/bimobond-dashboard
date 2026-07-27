import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../domain/entities/search_management_entities.dart';
import '../bloc/search_management_bloc.dart';
import '../bloc/search_management_event.dart';
import '../bloc/search_management_state.dart';
import '../utils/search_management_responsive.dart';
import 'search_management_details_dialog.dart';

class SearchManagementContentPanel extends StatelessWidget {
  const SearchManagementContentPanel({
    super.key,
    required this.state,
    required this.metrics,
  });

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final useDesktopPagination = metrics.useDesktopPagination;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (useDesktopPagination) return false;
        if (n.metrics.pixels < n.metrics.maxScrollExtent - 160) return false;
        if (!state.hasMore || state.isLoadingMore) return false;
        context
            .read<SearchManagementBloc>()
            .add(const SearchManagementLoadNextPageEvent());
        return false;
      },
      child: switch (state.uiTab) {
        SearchManagementTab.overview => _OverviewPanel(state: state),
        SearchManagementTab.searches => _HistoryTab(
            state: state,
            metrics: metrics,
          ),
        SearchManagementTab.users => _UsersTab(
            state: state,
            metrics: metrics,
          ),
        SearchManagementTab.sounds => _SoundsTab(
            state: state,
            metrics: metrics,
          ),
        SearchManagementTab.hashtags => _HashtagsTab(
            state: state,
            metrics: metrics,
          ),
        SearchManagementTab.trends => _TrendsTab(
            state: state,
            metrics: metrics,
          ),
      },
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.state});
  final SearchManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final posts = state.searchResult.posts?.data ?? const [];
    final users = state.searchResult.users?.data ?? const [];
    final sounds = state.searchResult.sounds?.data ?? const [];
    final hashtags = state.searchResult.hashtags?.data ?? const [];
    final trends = state.trends.take(8).toList();

    return ListView(
      children: [
        Text(
          l10n.tOr('searchMgmtBestResults', 'Top results (BEST)'),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statChip(scheme, 'Posts', '${posts.length}'),
            _statChip(scheme, 'Users', '${users.length}'),
            _statChip(scheme, 'Sounds', '${sounds.length}'),
            _statChip(scheme, 'Hashtags', '${hashtags.length}'),
          ],
        ),
        const SizedBox(height: 16),
        if (trends.isNotEmpty) ...[
          Text(
            l10n.tOr('searchMgmtTrendingNow', 'Trending now'),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in trends)
                ActionChip(
                  label: Text(t.query),
                  avatar: const Icon(Icons.trending_up_rounded, size: 16),
                  onPressed: () {
                    context
                        .read<SearchManagementBloc>()
                        .add(SearchManagementQueryChangedEvent(t.query));
                    showSearchManagementDetailsDialog(context, payload: t);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (users.isNotEmpty) ...[
          Text(
            l10n.tOr('searchMgmtTopUsers', 'Top users'),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final u in users.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage:
                    u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                child: u.avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 18)
                    : null,
              ),
              title: Text(u.displayName),
              subtitle: Text('@${u.username} · ${u.followerCount} followers'),
              onTap: () =>
                  showSearchManagementDetailsDialog(context, payload: u),
            ),
        ],
        if (posts.isEmpty &&
            users.isEmpty &&
            sounds.isEmpty &&
            hashtags.isEmpty &&
            trends.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                l10n.tOr(
                  'searchMgmtEmptyOverview',
                  'Enter a query and apply filters to explore search results.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statChip(ColorScheme scheme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _TabListShell extends StatelessWidget {
  const _TabListShell({
    required this.state,
    required this.metrics,
    required this.emptyTitle,
    required this.emptyIcon,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.compactBuilder,
  });

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;
  final String emptyTitle;
  final IconData emptyIcon;
  final Widget header;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? compactBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useDesktopPagination = metrics.useDesktopPagination;
    final pagination = state.listPagination;
    final compact = metrics.useCompactTable;
    final showPagination = useDesktopPagination && pagination != null;

    if (itemCount == 0) {
      return _EmptyState(title: emptyTitle, icon: emptyIcon);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: [
                if (!compact)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color:
                              scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    child: header,
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: (!useDesktopPagination && state.isLoadingMore)
                          ? 8
                          : 0,
                    ),
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    itemBuilder: (context, index) {
                      if (compact && compactBuilder != null) {
                        return compactBuilder!(context, index);
                      }
                      return itemBuilder(context, index);
                    },
                  ),
                ),
                if (!useDesktopPagination && state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showPagination) ...[
          const SizedBox(height: 8),
          AppPaginationBar(
            currentPage: pagination.page,
            lastPage: pagination.lastPage,
            total: pagination.total,
            pageSize: pagination.pageSize,
            itemCount: pagination.itemCount,
            hideWhenSinglePage: false,
            borderRadius: BorderRadius.circular(12),
            onPageChanged: (page) => context
                .read<SearchManagementBloc>()
                .add(SearchManagementPageChangedEvent(page)),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _headerStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.2,
      );
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state, required this.metrics});

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = state.history.data;
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final style = _headerStyle(context);

    return _TabListShell(
      state: state,
      metrics: metrics,
      emptyTitle:
          l10n.tOr('searchMgmtEmptySearches', 'No search history found'),
      emptyIcon: Icons.history_rounded,
      header: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(l10n.tOr('searchMgmtQuery', 'Query'), style: style),
          ),
          Expanded(
            child:
                Text(l10n.tOr('searchMgmtCategory', 'Category'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtUser', 'User'), style: style),
          ),
          Expanded(
            flex: 2,
            child:
                Text(l10n.tOr('searchMgmtCreated', 'Created'), style: style),
          ),
          const SizedBox(width: 36),
        ],
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    e.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    e.username ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(dateFmt.format(e.createdAt.toLocal())),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      compactBuilder: (context, i) {
        final e = entries[i];
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.query,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          e.category,
                          if (e.username != null) '@${e.username}',
                          dateFmt.format(e.createdAt.toLocal()),
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.state, required this.metrics});

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final users = state.searchResult.users?.data ?? const [];
    final style = _headerStyle(context);

    return _TabListShell(
      state: state,
      metrics: metrics,
      emptyTitle: l10n.tOr('searchMgmtEmptyUsers', 'No users found'),
      emptyIcon: Icons.people_outline_rounded,
      header: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            flex: 3,
            child: Text(l10n.tOr('searchMgmtUser', 'User'), style: style),
          ),
          Expanded(
            child:
                Text(l10n.tOr('searchMgmtFollowers', 'Followers'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtPosts', 'Posts'), style: style),
          ),
          const SizedBox(width: 28),
        ],
      ),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: u),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: u.avatarUrl != null
                      ? CachedNetworkImageProvider(u.avatarUrl!)
                      : null,
                  child: u.avatarUrl == null
                      ? const Icon(Icons.person_outline, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '@${u.username}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(child: Text('${u.followerCount}')),
                Expanded(child: Text('${u.postCount}')),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      compactBuilder: (context, i) {
        final u = users[i];
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: u),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: u.avatarUrl != null
                      ? CachedNetworkImageProvider(u.avatarUrl!)
                      : null,
                  child: u.avatarUrl == null
                      ? const Icon(Icons.person_outline, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${u.username} · ${u.followerCount} followers · ${u.postCount} posts',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SoundsTab extends StatelessWidget {
  const _SoundsTab({required this.state, required this.metrics});

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sounds = state.searchResult.sounds?.data ?? const [];
    final style = _headerStyle(context);

    return _TabListShell(
      state: state,
      metrics: metrics,
      emptyTitle: l10n.tOr('searchMgmtEmptySounds', 'No sounds found'),
      emptyIcon: Icons.library_music_outlined,
      header: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(l10n.tOr('searchMgmtSound', 'Sound'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtAuthor', 'Author'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtUses', 'Uses'), style: style),
          ),
          const SizedBox(width: 28),
        ],
      ),
      itemCount: sounds.length,
      itemBuilder: (context, i) {
        final s = sounds[i];
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text(s.author ?? '—')),
                Expanded(child: Text('${s.useCount}')),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      compactBuilder: (context, i) {
        final s = sounds[i];
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: scheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.author ?? '—'} · ${s.useCount} uses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HashtagsTab extends StatelessWidget {
  const _HashtagsTab({required this.state, required this.metrics});

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hashtags = state.searchResult.hashtags?.data ?? const [];
    final style = _headerStyle(context);

    return _TabListShell(
      state: state,
      metrics: metrics,
      emptyTitle: l10n.tOr('searchMgmtEmptyHashtags', 'No hashtags found'),
      emptyIcon: Icons.tag_rounded,
      header: Row(
        children: [
          Expanded(
            flex: 3,
            child:
                Text(l10n.tOr('searchMgmtHashtag', 'Hashtag'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtViews', 'Views'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtPosts', 'Posts'), style: style),
          ),
          const SizedBox(width: 28),
        ],
      ),
      itemCount: hashtags.length,
      itemBuilder: (context, i) {
        final h = hashtags[i];
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: h),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '#${h.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text('${h.viewCount}')),
                Expanded(child: Text('${h.postCount}')),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      compactBuilder: (context, i) {
        final h = hashtags[i];
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: h),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${h.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${h.viewCount} views · ${h.postCount} posts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab({required this.state, required this.metrics});

  final SearchManagementLoaded state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trends = state.trends;
    final style = _headerStyle(context);

    return _TabListShell(
      state: state,
      metrics: metrics,
      emptyTitle: l10n.tOr('searchMgmtEmptyTrends', 'No trends found'),
      emptyIcon: Icons.trending_up_rounded,
      header: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(l10n.tOr('searchMgmtQuery', 'Query'), style: style),
          ),
          Expanded(
            child:
                Text(l10n.tOr('searchMgmtCategory', 'Category'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtCount', 'Count'), style: style),
          ),
          Expanded(
            child: Text(l10n.tOr('searchMgmtScore', 'Score'), style: style),
          ),
          const SizedBox(width: 28),
        ],
      ),
      itemCount: trends.length,
      itemBuilder: (context, i) {
        final t = trends[i];
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    t.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text(t.category ?? '—')),
                Expanded(child: Text('${t.count}')),
                Expanded(child: Text(t.score?.toStringAsFixed(1) ?? '—')),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      compactBuilder: (context, i) {
        final t = trends[i];
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () =>
              showSearchManagementDetailsDialog(context, payload: t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (t.category != null) t.category!,
                          '${t.count}',
                          if (t.score != null) t.score!.toStringAsFixed(1),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
