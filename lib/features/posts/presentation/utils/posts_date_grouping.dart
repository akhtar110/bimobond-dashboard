import '../../../../core/localization/localization.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import 'post_date_format.dart';

/// Visual date bucket for grouping posts in the feed.
enum PostsDateGroupKind {
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  older,
}

/// A contiguous slice of the sorted posts list that shares one date bucket.
class PostsDateGroup {
  const PostsDateGroup({
    required this.kind,
    required this.posts,
  });

  final PostsDateGroupKind kind;
  final List<ManagedPostEntity> posts;

  int get count => posts.length;
}

/// Stable ordering for rendering group headers.
const List<PostsDateGroupKind> kPostsDateGroupOrder = [
  PostsDateGroupKind.today,
  PostsDateGroupKind.yesterday,
  PostsDateGroupKind.last7Days,
  PostsDateGroupKind.thisMonth,
  PostsDateGroupKind.lastMonth,
  PostsDateGroupKind.older,
];

/// Calendar bounds used to classify a post day into one of six buckets.
class _PostsDateBounds {
  const _PostsDateBounds({
    required this.today,
    required this.yesterday,
    required this.last7Start,
    required this.last7End,
    required this.thisMonthStart,
    required this.lastMonthStart,
  });

  final DateTime today;
  final DateTime yesterday;
  final DateTime last7Start;
  final DateTime last7End;
  final DateTime thisMonthStart;
  final DateTime lastMonthStart;

  factory _PostsDateBounds.fromNow(DateTime now) {
    final today = dateOnly(now.toLocal());
    final yesterday = today.subtract(const Duration(days: 1));

    // Seven calendar days immediately before yesterday.
    final last7End = yesterday.subtract(const Duration(days: 1));
    final last7Start = yesterday.subtract(const Duration(days: 7));

    final thisMonthStart = DateTime(today.year, today.month, 1);

    final lastMonthYear = today.month == 1 ? today.year - 1 : today.year;
    final lastMonth = today.month == 1 ? 12 : today.month - 1;
    final lastMonthStart = DateTime(lastMonthYear, lastMonth, 1);

    return _PostsDateBounds(
      today: today,
      yesterday: yesterday,
      last7Start: last7Start,
      last7End: last7End,
      thisMonthStart: thisMonthStart,
      lastMonthStart: lastMonthStart,
    );
  }
}

PostsDateGroupKind resolvePostsDateGroupKind(
  DateTime createdAt, {
  DateTime? now,
}) {
  final bounds = _PostsDateBounds.fromNow(now ?? DateTime.now());
  final day = dateOnly(createdAt.toLocal());

  // 1. Today
  if (day == bounds.today) return PostsDateGroupKind.today;

  // 2. Yesterday
  if (day == bounds.yesterday) return PostsDateGroupKind.yesterday;

  // 3. Last 7 days (excluding today and yesterday)
  if (!day.isBefore(bounds.last7Start) && !day.isAfter(bounds.last7End)) {
    return PostsDateGroupKind.last7Days;
  }

  // 4. Earlier in the current calendar month
  if (!day.isBefore(bounds.thisMonthStart)) {
    return PostsDateGroupKind.thisMonth;
  }

  // 5. Previous calendar month
  if (!day.isBefore(bounds.lastMonthStart)) {
    return PostsDateGroupKind.lastMonth;
  }

  // 6. Anything older than the previous calendar month
  return PostsDateGroupKind.older;
}

/// Buckets [posts] into all six date groups (in priority order), omitting empty groups.
List<PostsDateGroup> groupPostsByDate(
  List<ManagedPostEntity> posts, {
  DateTime? now,
}) {
  if (posts.isEmpty) return const [];

  final buckets = <PostsDateGroupKind, List<ManagedPostEntity>>{
    for (final kind in kPostsDateGroupOrder) kind: <ManagedPostEntity>[],
  };

  for (final post in posts) {
    final kind = resolvePostsDateGroupKind(post.createdAt, now: now);
    buckets[kind]!.add(post);
  }

  return [
    for (final kind in kPostsDateGroupOrder)
      if (buckets[kind]!.isNotEmpty)
        PostsDateGroup(kind: kind, posts: buckets[kind]!),
  ];
}

String postsDateGroupLabel(AppLocalizations l10n, PostsDateGroupKind kind) {
  final isAr = l10n.locale.languageCode == 'ar';
  return switch (kind) {
    PostsDateGroupKind.today =>
      l10n.tOr('dateToday', isAr ? 'اليوم' : 'Today'),
    PostsDateGroupKind.yesterday =>
      l10n.tOr('postFilterYesterday', isAr ? 'أمس' : 'Yesterday'),
    PostsDateGroupKind.last7Days =>
      l10n.tOr('last7Days', isAr ? 'آخر 7 أيام' : 'Last 7 Days'),
    PostsDateGroupKind.thisMonth =>
      l10n.tOr('postsGroupThisMonth',
          l10n.tOr('postFilterThisMonth', isAr ? 'هذا الشهر' : 'This Month')),
    PostsDateGroupKind.lastMonth =>
      l10n.tOr('postsGroupLastMonth', isAr ? 'الشهر الماضي' : 'Last Month'),
    PostsDateGroupKind.older =>
      l10n.tOr('postsGroupOlder', isAr ? 'الأقدم' : 'Older'),
  };
}
