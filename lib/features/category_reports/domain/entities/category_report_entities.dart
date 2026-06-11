import 'package:equatable/equatable.dart';

class CategoryReportPeriod extends Equatable {
  const CategoryReportPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class CategoryReportPeriodQuery extends Equatable {
  const CategoryReportPeriodQuery({
    this.from,
    this.to,
    this.days = 30,
  });

  final DateTime? from;
  final DateTime? to;
  final int days;

  Map<String, dynamic> toQueryParameters() {
    if (from != null) {
      return {
        'from': from!.toUtc().toIso8601String(),
        if (to != null) 'to': to!.toUtc().toIso8601String(),
      };
    }
    return {'days': days};
  }

  @override
  List<Object?> get props => [from, to, days];
}

enum CategoryReportsSort {
  order,
  newest,
  oldest,
  name,
  mostPosts,
  mostViews,
  mostLikes;

  String get apiValue => switch (this) {
        CategoryReportsSort.order => 'ORDER',
        CategoryReportsSort.newest => 'NEWEST',
        CategoryReportsSort.oldest => 'OLDEST',
        CategoryReportsSort.name => 'NAME',
        CategoryReportsSort.mostPosts => 'MOST_POSTS',
        CategoryReportsSort.mostViews => 'MOST_VIEWS',
        CategoryReportsSort.mostLikes => 'MOST_LIKES',
      };
}

class CategoryReportsListQuery extends Equatable {
  const CategoryReportsListQuery({
    this.search,
    this.isActive,
    this.isMain,
    this.parentId,
    this.sort = CategoryReportsSort.order,
  });

  final String? search;
  final bool? isActive;
  final bool? isMain;
  final String? parentId;
  final CategoryReportsSort sort;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (isActive != null) 'isActive': isActive,
      if (isMain != null) 'isMain': isMain,
      if (parentId != null && parentId!.isNotEmpty) 'parentId': parentId,
      'sort': sort.apiValue,
    };
  }

  @override
  List<Object?> get props => [search, isActive, isMain, parentId, sort];
}

class CategoryReportPostMetrics extends Equatable {
  const CategoryReportPostMetrics({
    required this.postCount,
    required this.views,
    required this.likes,
    required this.comments,
    this.saves,
    this.reposts,
  });

  final int postCount;
  final int views;
  final int likes;
  final int comments;
  final int? saves;
  final int? reposts;

  @override
  List<Object?> get props =>
      [postCount, views, likes, comments, saves, reposts];
}

class CategoryReportCounts extends Equatable {
  const CategoryReportCounts({
    required this.posts,
    required this.children,
    this.directPosts,
    this.subcategories,
    this.postsInSubcategories,
  });

  final int posts;
  final int children;
  final int? directPosts;
  final int? subcategories;
  final int? postsInSubcategories;

  @override
  List<Object?> get props =>
      [posts, children, directPosts, subcategories, postsInSubcategories];
}

class CategoryReportParentSummary extends Equatable {
  const CategoryReportParentSummary({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [id, name, slug];
}

class CategoryReportChildSummary extends Equatable {
  const CategoryReportChildSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.order,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final int order;
  final String? iconUrl;

  @override
  List<Object?> get props => [id, name, slug, isActive, order, iconUrl];
}

class CategoryReportListItemEntity extends Equatable {
  const CategoryReportListItemEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    required this.isActive,
    required this.order,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.parent,
    this.children = const [],
    required this.counts,
    required this.postMetrics,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final int order;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryReportParentSummary? parent;
  final List<CategoryReportChildSummary> children;
  final CategoryReportCounts counts;
  final CategoryReportPostMetrics postMetrics;

  bool get isMain => parentId == null;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        iconUrl,
        isActive,
        order,
        parentId,
        createdAt,
        updatedAt,
        parent,
        children,
        counts,
        postMetrics,
      ];
}

class CategoryReportFilterOption extends Equatable {
  const CategoryReportFilterOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class CategoryReportTopCategorySummary extends Equatable {
  const CategoryReportTopCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.postCount,
    required this.views,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final int postCount;
  final int views;

  @override
  List<Object?> get props => [id, name, slug, iconUrl, postCount, views];
}

class CategoryReportOverviewEntity extends Equatable {
  const CategoryReportOverviewEntity({
    required this.period,
    required this.totalCategories,
    required this.mainCategories,
    required this.subcategories,
    required this.activeCategories,
    required this.inactiveCategories,
    required this.totalPosts,
    required this.postsWithCategory,
    required this.postsWithoutCategory,
    required this.postsCreated,
    required this.categorizedPosts,
    required this.uncategorizedPosts,
    required this.topByPosts,
    required this.topByViews,
    required this.topByPostsInPeriod,
  });

  final CategoryReportPeriod period;
  final int totalCategories;
  final int mainCategories;
  final int subcategories;
  final int activeCategories;
  final int inactiveCategories;
  final int totalPosts;
  final int postsWithCategory;
  final int postsWithoutCategory;
  final int postsCreated;
  final int categorizedPosts;
  final int uncategorizedPosts;
  final List<CategoryReportTopCategorySummary> topByPosts;
  final List<CategoryReportTopCategorySummary> topByViews;
  final List<CategoryReportTopCategorySummary> topByPostsInPeriod;

  @override
  List<Object?> get props => [
        period,
        totalCategories,
        mainCategories,
        subcategories,
        activeCategories,
        inactiveCategories,
        totalPosts,
        postsWithCategory,
        postsWithoutCategory,
        postsCreated,
        categorizedPosts,
        uncategorizedPosts,
        topByPosts,
        topByViews,
        topByPostsInPeriod,
      ];
}

class CategoryReportSubcategoryStat extends Equatable {
  const CategoryReportSubcategoryStat({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.isActive,
    required this.order,
    required this.postCount,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final int order;
  final int postCount;

  @override
  List<Object?> get props =>
      [id, name, slug, iconUrl, isActive, order, postCount];
}

class CategoryReportPostSummary extends Equatable {
  const CategoryReportPostSummary({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.views,
    this.likes,
    this.createdAt,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final int? views;
  final int? likes;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, description, thumbnailUrl, views, likes, createdAt];
}

class CategoryReportAuthorSummary extends Equatable {
  const CategoryReportAuthorSummary({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : username;

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isVerified, isBanned];
}

class CategoryReportTopAuthor extends Equatable {
  const CategoryReportTopAuthor({
    required this.user,
    required this.postCount,
    required this.views,
    required this.likes,
  });

  final CategoryReportAuthorSummary user;
  final int postCount;
  final int views;
  final int likes;

  @override
  List<Object?> get props => [user, postCount, views, likes];
}

class CategoryReportDetailEntity extends Equatable {
  const CategoryReportDetailEntity({
    required this.period,
    required this.category,
    required this.counts,
    required this.postMetrics,
    required this.periodPostsCreated,
    required this.periodViews,
    required this.periodLikes,
    required this.periodComments,
    required this.subcategoryStats,
    required this.recentPosts,
    required this.topPosts,
    required this.topAuthors,
  });

  final CategoryReportPeriod period;
  final CategoryReportListItemEntity category;
  final CategoryReportCounts counts;
  final CategoryReportPostMetrics postMetrics;
  final int periodPostsCreated;
  final int periodViews;
  final int periodLikes;
  final int periodComments;
  final List<CategoryReportSubcategoryStat> subcategoryStats;
  final List<CategoryReportPostSummary> recentPosts;
  final List<CategoryReportPostSummary> topPosts;
  final List<CategoryReportTopAuthor> topAuthors;

  @override
  List<Object?> get props => [
        period,
        category,
        counts,
        postMetrics,
        periodPostsCreated,
        periodViews,
        periodLikes,
        periodComments,
        subcategoryStats,
        recentPosts,
        topPosts,
        topAuthors,
      ];
}
