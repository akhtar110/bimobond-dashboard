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
    this.isStory,
    this.isAd,
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
  final bool? isStory;
  final bool? isAd;

  static const defaultSort = 'LATEST';

  /// Which post-type chip is active (All / Auction / Stories / Ads).
  PostTypeFilter get postTypeFilter {
    if (isStory == true) return PostTypeFilter.stories;
    if (isAd == true) return PostTypeFilter.ads;
    if (isAuctionable == true) return PostTypeFilter.auction;
    return PostTypeFilter.all;
  }

  PostFilters copyWith({
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? search,
    String? type,
    String? sort,
    bool? isAuctionable,
    bool? isStory,
    bool? isAd,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearType = false,
    bool clearSort = false,
    bool clearAuction = false,
    bool clearStory = false,
    bool clearAd = false,
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
      isStory: clearStory ? null : (isStory ?? this.isStory),
      isAd: clearAd ? null : (isAd ?? this.isAd),
    );
  }

  int get advancedActiveCount {
    var count = 0;
    if (search != null && search!.trim().isNotEmpty) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (sort != null && sort != defaultSort) count++;
    if (isAuctionable == true) count++;
    if (isStory == true) count++;
    if (isAd == true) count++;
    return count;
  }

  /// True when at least one advanced filter (search / type / sort / auction)
  /// is active.  Does NOT count the selected category chip.
  bool get hasAdvancedFilters => advancedActiveCount > 0;

  /// True when any filter is active — advanced filters OR a category chip.
  /// Use this to decide whether to show a "Clear all filters" affordance.
  bool get hasAnyFilters => hasAdvancedFilters || categoryId != null;

  @override
  bool operator ==(Object other) {
    return other is PostFilters &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categorySlug == categorySlug &&
        other.search == search &&
        other.type == type &&
        other.sort == sort &&
        other.isAuctionable == isAuctionable &&
        other.isStory == isStory &&
        other.isAd == isAd;
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
        isStory,
        isAd,
      );
}

/// Mutually exclusive post-type filter selection.
enum PostTypeFilter { all, auction, stories, ads }
