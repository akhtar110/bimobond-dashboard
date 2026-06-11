import '../../../../core/utils/api_page_parser.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/category_report_entities.dart';

abstract final class CategoryReportModels {
  static CategoryReportPeriod parsePeriod(Map<String, dynamic> json) {
    final period = json['period'];
    if (period is Map<String, dynamic>) {
      return CategoryReportPeriod(
        from: _date(period['from']) ?? DateTime.now(),
        to: _date(period['to']) ?? DateTime.now(),
      );
    }
    return CategoryReportPeriod(from: DateTime.now(), to: DateTime.now());
  }

  static CategoryReportOverviewEntity overviewFromJson(dynamic data) {
    final json = _unwrap(data);
    final totals = _section(json, 'totals');
    final periodEngagement = _section(json, 'periodEngagement');
    final topCategories = _section(json, 'topCategories');

    return CategoryReportOverviewEntity(
      period: parsePeriod(json),
      totalCategories: _int(totals['totalCategories']),
      mainCategories: _int(totals['mainCategories']),
      subcategories: _int(totals['subcategories']),
      activeCategories: _int(totals['activeCategories']),
      inactiveCategories: _int(totals['inactiveCategories']),
      totalPosts: _int(totals['totalPosts']),
      postsWithCategory: _int(totals['postsWithCategory']),
      postsWithoutCategory: _int(totals['postsWithoutCategory']),
      postsCreated: _int(periodEngagement['postsCreated']),
      categorizedPosts: _int(periodEngagement['categorizedPosts']),
      uncategorizedPosts: _int(periodEngagement['uncategorizedPosts']),
      topByPosts: _topCategories(topCategories['byPosts']),
      topByViews: _topCategories(topCategories['byViews']),
      topByPostsInPeriod: _topCategories(topCategories['byPostsInPeriod']),
    );
  }

  static CategoryReportListItemModel listItemFromJson(
    Map<String, dynamic> json,
  ) =>
      CategoryReportListItemModel.fromJson(json);

  static CategoryReportDetailEntity detailFromJson(dynamic data) {
    final json = _unwrap(data);
    final categoryJson = json['category'] as Map<String, dynamic>? ?? {};
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final postMetricsJson =
        json['postMetrics'] as Map<String, dynamic>? ?? {};
    final periodActivity =
        json['periodActivity'] as Map<String, dynamic>? ?? {};

    return CategoryReportDetailEntity(
      period: parsePeriod(json),
      category: listItemFromJson(categoryJson),
      counts: _counts(countsJson),
      postMetrics: _postMetrics(postMetricsJson),
      periodPostsCreated: _int(periodActivity['postsCreated']),
      periodViews: _int(periodActivity['views']),
      periodLikes: _int(periodActivity['likes']),
      periodComments: _int(periodActivity['comments']),
      subcategoryStats: _subcategoryStats(json['subcategoryStats']),
      recentPosts: _posts(json['recentPosts']),
      topPosts: _posts(json['topPosts']),
      topAuthors: _topAuthors(json['topAuthors']),
    );
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {};
  }

  static Map<String, dynamic> _section(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    return value is Map<String, dynamic> ? value : {};
  }

  static CategoryReportCounts _counts(Map<String, dynamic> json) {
    return CategoryReportCounts(
      posts: _int(json['posts'] ?? json['directPosts']),
      children: _int(json['children'] ?? json['subcategories']),
      directPosts: json['directPosts'] != null ? _int(json['directPosts']) : null,
      subcategories:
          json['subcategories'] != null ? _int(json['subcategories']) : null,
      postsInSubcategories: json['postsInSubcategories'] != null
          ? _int(json['postsInSubcategories'])
          : null,
    );
  }

  static CategoryReportPostMetrics _postMetrics(Map<String, dynamic> json) {
    return CategoryReportPostMetrics(
      postCount: _int(json['postCount']),
      views: _int(json['views']),
      likes: _int(json['likes']),
      comments: _int(json['comments']),
      saves: json['saves'] != null ? _int(json['saves']) : null,
      reposts: json['reposts'] != null ? _int(json['reposts']) : null,
    );
  }

  static CategoryReportParentSummary? _parent(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return CategoryReportParentSummary(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      slug: raw['slug']?.toString() ?? '',
    );
  }

  static List<CategoryReportChildSummary> _children(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      return CategoryReportChildSummary(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        isActive: json['isActive'] as bool? ?? true,
        order: _int(json['order']),
        iconUrl: resolveMediaUrl(json['iconUrl']?.toString()),
      );
    }).toList();
  }

  static List<CategoryReportTopCategorySummary> _topCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      return CategoryReportTopCategorySummary(
        id: json['id']?.toString() ?? json['categoryId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        iconUrl: resolveMediaUrl(json['iconUrl']?.toString()),
        postCount: _int(json['postCount'] ?? json['count']),
        views: _int(json['views']),
      );
    }).toList();
  }

  static List<CategoryReportSubcategoryStat> _subcategoryStats(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      return CategoryReportSubcategoryStat(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        iconUrl: resolveMediaUrl(json['iconUrl']?.toString()),
        isActive: json['isActive'] as bool? ?? true,
        order: _int(json['order']),
        postCount: _int(json['postCount']),
      );
    }).toList();
  }

  static List<CategoryReportPostSummary> _posts(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      return CategoryReportPostSummary(
        id: json['id']?.toString() ?? '',
        description: json['description']?.toString(),
        thumbnailUrl: resolveMediaUrl(json['thumbnailUrl']?.toString()),
        views: json['views'] != null ? _int(json['views']) : null,
        likes: json['likes'] != null ? _int(json['likes']) : null,
        createdAt: _date(json['createdAt']),
      );
    }).toList();
  }

  static List<CategoryReportTopAuthor> _topAuthors(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      final userJson = json['user'] as Map<String, dynamic>? ?? {};
      return CategoryReportTopAuthor(
        user: CategoryReportAuthorSummary(
          id: userJson['id']?.toString() ?? '',
          username: userJson['username']?.toString() ?? '',
          fullName: userJson['fullName']?.toString(),
          email: userJson['email']?.toString(),
          avatarUrl: resolveMediaUrl(userJson['avatarUrl']?.toString()),
          isVerified: userJson['isVerified'] as bool? ?? false,
          isBanned: userJson['isBanned'] as bool? ?? false,
        ),
        postCount: _int(json['postCount']),
        views: _int(json['views']),
        likes: _int(json['likes']),
      );
    }).toList();
  }

  static int _int(dynamic v) => ApiPageParser.intVal(v);

  static DateTime? _date(dynamic v) {
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

class CategoryReportListItemModel extends CategoryReportListItemEntity {
  const CategoryReportListItemModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    super.iconUrl,
    required super.isActive,
    required super.order,
    super.parentId,
    required super.createdAt,
    required super.updatedAt,
    super.parent,
    super.children,
    required super.counts,
    required super.postMetrics,
  });

  factory CategoryReportListItemModel.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final metricsJson = json['postMetrics'] as Map<String, dynamic>? ?? {};

    return CategoryReportListItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: resolveMediaUrl(json['iconUrl']?.toString()),
      isActive: json['isActive'] as bool? ?? true,
      order: ApiPageParser.intVal(json['order']),
      parentId: json['parentId']?.toString(),
      createdAt:
          CategoryReportModels._date(json['createdAt']) ?? DateTime.now(),
      updatedAt:
          CategoryReportModels._date(json['updatedAt']) ?? DateTime.now(),
      parent: CategoryReportModels._parent(json['parent']),
      children: CategoryReportModels._children(json['children']),
      counts: CategoryReportModels._counts(countsJson),
      postMetrics: CategoryReportModels._postMetrics(metricsJson),
    );
  }
}
