import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
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
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120 &&
            state.hasMore &&
            !state.isLoadingMore) {
          context
              .read<SearchManagementBloc>()
              .add(const SearchManagementLoadNextPageEvent());
        }
        return false;
      },
      child: switch (state.uiTab) {
        SearchManagementTab.overview => _OverviewPanel(state: state),
        SearchManagementTab.searches => _HistoryTable(
            entries: state.history.data,
            metrics: metrics,
          ),
        SearchManagementTab.users => _UsersTable(
            users: state.searchResult.users?.data ?? const [],
            metrics: metrics,
          ),
        SearchManagementTab.sounds => _SoundsTable(
            sounds: state.searchResult.sounds?.data ?? const [],
            metrics: metrics,
          ),
        SearchManagementTab.hashtags => _HashtagsTable(
            hashtags: state.searchResult.hashtags?.data ?? const [],
            metrics: metrics,
          ),
        SearchManagementTab.trends => _TrendsTable(
            trends: state.trends,
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
      child: Text('$label · $value',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({
    required this.header,
    required this.rows,
    required this.emptyTitle,
  });

  final Widget header;
  final List<Widget> rows;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyTitle,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: header,
          ),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: scheme.outlineVariant),
              itemBuilder: (_, i) => rows[i],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.entries, required this.metrics});
  final List<SearchHistoryEntryEntity> entries;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return _TableShell(
      emptyTitle: l10n.tOr('searchMgmtEmptySearches', 'No search history found'),
      header: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.tOr('searchMgmtQuery', 'Query'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtCategory', 'Category'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtUser', 'User'), style: style)),
          Expanded(flex: 2, child: Text(l10n.tOr('searchMgmtCreated', 'Created'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
      rows: [
        for (final e in entries)
          InkWell(
            onTap: () =>
                showSearchManagementDetailsDialog(context, payload: e),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(e.query,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(child: Text(e.category)),
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
                  IconButton(
                    tooltip: l10n.tOr('viewDetails', 'View details'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () => showSearchManagementDetailsDialog(
                      context,
                      payload: e,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.metrics});
  final List<SearchUserHit> users;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return _TableShell(
      emptyTitle: l10n.tOr('searchMgmtEmptyUsers', 'No users found'),
      header: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 3, child: Text(l10n.tOr('searchMgmtUser', 'User'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtFollowers', 'Followers'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtPosts', 'Posts'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
      rows: [
        for (final u in users)
          InkWell(
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
                        Text(u.displayName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('@${u.username}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(child: Text('${u.followerCount}')),
                  Expanded(child: Text('${u.postCount}')),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SoundsTable extends StatelessWidget {
  const _SoundsTable({required this.sounds, required this.metrics});
  final List<SearchSoundHit> sounds;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return _TableShell(
      emptyTitle: l10n.tOr('searchMgmtEmptySounds', 'No sounds found'),
      header: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.tOr('searchMgmtSound', 'Sound'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtAuthor', 'Author'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtUses', 'Uses'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
      rows: [
        for (final s in sounds)
          InkWell(
            onTap: () =>
                showSearchManagementDetailsDialog(context, payload: s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(s.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(child: Text(s.author ?? '—')),
                  Expanded(child: Text('${s.useCount}')),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HashtagsTable extends StatelessWidget {
  const _HashtagsTable({required this.hashtags, required this.metrics});
  final List<SearchHashtagHit> hashtags;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return _TableShell(
      emptyTitle: l10n.tOr('searchMgmtEmptyHashtags', 'No hashtags found'),
      header: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.tOr('searchMgmtHashtag', 'Hashtag'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtViews', 'Views'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtPosts', 'Posts'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
      rows: [
        for (final h in hashtags)
          InkWell(
            onTap: () =>
                showSearchManagementDetailsDialog(context, payload: h),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('#${h.name}')),
                  Expanded(child: Text('${h.viewCount}')),
                  Expanded(child: Text('${h.postCount}')),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendsTable extends StatelessWidget {
  const _TrendsTable({required this.trends, required this.metrics});
  final List<SearchTrendEntity> trends;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return _TableShell(
      emptyTitle: l10n.tOr('searchMgmtEmptyTrends', 'No trends found'),
      header: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.tOr('searchMgmtQuery', 'Query'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtCategory', 'Category'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtCount', 'Count'), style: style)),
          Expanded(child: Text(l10n.tOr('searchMgmtScore', 'Score'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
      rows: [
        for (final t in trends)
          InkWell(
            onTap: () =>
                showSearchManagementDetailsDialog(context, payload: t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(t.query,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(child: Text(t.category ?? '—')),
                  Expanded(child: Text('${t.count}')),
                  Expanded(
                    child: Text(t.score?.toStringAsFixed(1) ?? '—'),
                  ),
                  IconButton(
                    tooltip: l10n.tOr('viewDetails', 'View details'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () => showSearchManagementDetailsDialog(
                      context,
                      payload: t,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
