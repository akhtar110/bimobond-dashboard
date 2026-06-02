/// Query filters for `GET /posts/feed`.
class PostFilters {
  const PostFilters({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.search,
    this.type,
    this.sort = 'LATEST',
    this.isAuctionable,
  });

  final String? categoryId;
  final String? categoryName;
  /// Slug sent to the API as the `category` query parameter (e.g. `"music"`).
  final String? categorySlug;
  /// Full-text search (post descriptions and related feed search).
  final String? search;
  /// `VIDEO`, `IMAGE`, or `CAROUSEL`.
  final String? type;
  /// `LATEST` or `POPULAR`.
  final String? sort;
  final bool? isAuctionable;

  static const defaultSort = 'LATEST';

  PostFilters copyWith({
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? search,
    String? type,
    String? sort,
    bool? isAuctionable,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearType = false,
    bool clearSort = false,
    bool clearAuction = false,
  }) {
    return PostFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName:
          clearCategory ? null : (categoryName ?? this.categoryName),
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
      search: clearSearch ? null : (search ?? this.search),
      type: clearType ? null : (type ?? this.type),
      sort: clearSort ? defaultSort : (sort ?? this.sort),
      isAuctionable:
          clearAuction ? null : (isAuctionable ?? this.isAuctionable),
    );
  }

  int get advancedActiveCount {
    var count = 0;
    if (search != null && search!.trim().isNotEmpty) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (sort != null && sort != defaultSort) count++;
    if (isAuctionable == true) count++;
    return count;
  }

  bool get hasAdvancedFilters => advancedActiveCount > 0;

  @override
  bool operator ==(Object other) {
    return other is PostFilters &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categorySlug == categorySlug &&
        other.search == search &&
        other.type == type &&
        other.sort == sort &&
        other.isAuctionable == isAuctionable;
  }

  @override
  int get hashCode => Object.hash(
        categoryId,
        categoryName,
        categorySlug,
        search,
        type,
        sort,
        isAuctionable,
      );
}
