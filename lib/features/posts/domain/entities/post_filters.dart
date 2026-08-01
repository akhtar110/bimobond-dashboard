/// Query filters for `GET /posts/feed`.
class PostFilters {
  const PostFilters({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.search,
    this.userId,
    this.userName,
    this.createdFrom,
    this.createdTo,
    this.createdTimeFromMinutes,
    this.createdTimeToMinutes,
    this.type,
    this.sort = 'LATEST',
    this.locationCity,
    this.locationLatitude,
    this.locationLongitude,
    this.locationRadiusKm = defaultLocationRadiusKm,
    this.isAuctionable,
    this.isStory,
    this.isAd,
    this.status,
    this.privacyStatus,
  });
  final String? categoryId;
  final String? categoryName;

  /// Slug sent to the API as the `category` query parameter (e.g. `"music"`).
  final String? categorySlug;

  /// Full-text search (post descriptions and related feed search).
  final String? search;

  /// Author filter — sent to the API as `userId`.
  final String? userId;

  /// Display label for [userId] (username).
  final String? userName;

  /// Inclusive range start on post `createdAt` — sent as `createdFrom`.
  final DateTime? createdFrom;

  /// Inclusive range end on post `createdAt` — sent as `createdTo`.
  final DateTime? createdTo;

  /// Inclusive start time-of-day filter (minutes since midnight, 0–1439).
  final int? createdTimeFromMinutes;

  /// Inclusive end time-of-day filter (minutes since midnight, 0–1439).
  final int? createdTimeToMinutes;

  /// `VIDEO`, `IMAGE`, or `CAROUSEL`.
  final String? type;

  /// `LATEST`, `POPULAR`, `AUTHOR_ASC`, `AUTHOR_DESC`, or `CREATED_ASC`.
  final String? sort;

  /// Display label for the active location filter chip.
  final String? locationCity;
  final double? locationLatitude;
  final double? locationLongitude;

  /// Nearby radius in km when sorting by proximity. Default: 50.
  final double? locationRadiusKm;
  final bool? isAuctionable;
  final bool? isStory;
  final bool? isAd;

  /// Admin post status (e.g. `PUBLISHED`, `DRAFT`).
  final String? status;

  /// `PUBLIC`, `PRIVATE`, or `FRIENDS`.
  final String? privacyStatus;

  static const defaultSort = 'LATEST';
  static const privacyOptions = ['PUBLIC', 'PRIVATE', 'FRIENDS'];
  static const sortLatest = 'LATEST';
  static const sortPopular = 'POPULAR';
  static const sortAuthorAsc = 'AUTHOR_ASC';
  static const sortAuthorDesc = 'AUTHOR_DESC';
  static const sortCreatedAsc = 'CREATED_ASC';

  static const defaultLocationRadiusKm = 50.0;

  static bool isAuthorSort(String? sort) =>
      sort == sortAuthorAsc || sort == sortAuthorDesc;

  /// Sorts applied client-side; the API receives [defaultSort] instead.
  static bool isClientSideSort(String? sort) =>
      isAuthorSort(sort) || sort == sortCreatedAsc;

  /// Value sent to `GET /posts/admin/all` as the `sort` query parameter.
  static String apiSortValue(String? sort) {
    if (isAuthorSort(sort) || sort == sortCreatedAsc) return defaultSort;
    return sort ?? defaultSort;
  }

  bool get hasLocationAnchor =>
      locationLatitude != null && locationLongitude != null;

  bool get hasLocationFilter => hasLocationAnchor;

  /// @deprecated Use [hasLocationFilter].
  bool get hasLocationProximityFilter => hasLocationFilter;

  bool get hasDateRange => createdFrom != null || createdTo != null;

  bool get hasTimeRange =>
      createdTimeFromMinutes != null || createdTimeToMinutes != null;

  bool get hasDateTimeFilters => hasDateRange || hasTimeRange;

  /// Which post-type chip is active (All / Auction / Ads).
  PostTypeFilter get postTypeFilter {
    if (isAd == true) return PostTypeFilter.ads;
    if (isAuctionable == true) return PostTypeFilter.auction;
    return PostTypeFilter.all;
  }

  PostFilters copyWith({
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? search,
    String? userId,
    String? userName,
    Object? createdFrom = _unset,
    Object? createdTo = _unset,
    Object? createdTimeFromMinutes = _unset,
    Object? createdTimeToMinutes = _unset,
    String? type,
    String? sort,
    Object? locationCity = _unset,
    Object? locationLatitude = _unset,
    Object? locationLongitude = _unset,
    Object? locationRadiusKm = _unset,
    bool? isAuctionable,
    bool? isStory,
    bool? isAd,
    String? status,
    String? privacyStatus,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearSearch = false,
    bool clearUser = false,
    bool clearDateRange = false,
    bool clearTimeRange = false,
    bool clearType = false,
    bool clearSort = false,
    bool clearAuction = false,
    bool clearStory = false,
    bool clearAd = false,
    bool clearStatus = false,
    bool clearPrivacyStatus = false,
  }) {
    return PostFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      search: clearSearch ? null : (search ?? this.search),
      userId: clearUser ? null : (userId ?? this.userId),
      userName: clearUser ? null : (userName ?? this.userName),
      createdFrom: clearDateRange
          ? null
          : identical(createdFrom, _unset)
          ? this.createdFrom
          : createdFrom as DateTime?,
      createdTo: clearDateRange
          ? null
          : identical(createdTo, _unset)
          ? this.createdTo
          : createdTo as DateTime?,
      createdTimeFromMinutes: clearTimeRange
          ? null
          : identical(createdTimeFromMinutes, _unset)
          ? this.createdTimeFromMinutes
          : createdTimeFromMinutes as int?,
      createdTimeToMinutes: clearTimeRange
          ? null
          : identical(createdTimeToMinutes, _unset)
          ? this.createdTimeToMinutes
          : createdTimeToMinutes as int?,
      type: clearType ? null : (type ?? this.type),
      sort: clearSort ? defaultSort : (sort ?? this.sort),
      locationCity: clearLocation
          ? null
          : identical(locationCity, _unset)
          ? this.locationCity
          : locationCity as String?,
      locationLatitude: clearLocation
          ? null
          : identical(locationLatitude, _unset)
          ? this.locationLatitude
          : locationLatitude as double?,
      locationLongitude: clearLocation
          ? null
          : identical(locationLongitude, _unset)
          ? this.locationLongitude
          : locationLongitude as double?,
      locationRadiusKm: clearLocation
          ? defaultLocationRadiusKm
          : identical(locationRadiusKm, _unset)
          ? this.locationRadiusKm
          : locationRadiusKm as double?,
      isAuctionable: clearAuction
          ? null
          : (isAuctionable ?? this.isAuctionable),
      isStory: clearStory ? null : (isStory ?? this.isStory),
      isAd: clearAd ? null : (isAd ?? this.isAd),
      status: clearStatus ? null : (status ?? this.status),
      privacyStatus: clearPrivacyStatus
          ? null
          : (privacyStatus ?? this.privacyStatus),
    );
  }

  int get advancedActiveCount {
    var count = 0;
    if (search != null && search!.trim().isNotEmpty) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (sort != null && sort != defaultSort) count++;
    if (hasLocationFilter) count++;
    if (isAuctionable == true) count++;
    if (isAd == true) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (privacyStatus != null && privacyStatus!.isNotEmpty) count++;
    return count;
  }

  /// True when at least one advanced filter (search / type / sort / auction)
  /// is active.  Does NOT count the selected category chip.
  bool get hasAdvancedFilters => advancedActiveCount > 0;

  /// True when any filter is active — advanced filters OR a category chip
  /// OR a user filter.
  /// Use this to decide whether to show a "Clear all filters" affordance.
  bool get hasAnyFilters =>
      hasAdvancedFilters ||
      categoryId != null ||
      userId != null ||
      hasDateTimeFilters ||
      hasLocationFilter;

  @override
  bool operator ==(Object other) {
    return other is PostFilters &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categorySlug == categorySlug &&
        other.search == search &&
        other.userId == userId &&
        other.userName == userName &&
        _dateEq(other.createdFrom, createdFrom) &&
        _dateEq(other.createdTo, createdTo) &&
        other.createdTimeFromMinutes == createdTimeFromMinutes &&
        other.createdTimeToMinutes == createdTimeToMinutes &&
        other.type == type &&
        other.sort == sort &&
        other.locationCity == locationCity &&
        other.locationLatitude == locationLatitude &&
        other.locationLongitude == locationLongitude &&
        other.locationRadiusKm == locationRadiusKm &&
        other.isAuctionable == isAuctionable &&
        other.isStory == isStory &&
        other.isAd == isAd &&
        other.status == status &&
        other.privacyStatus == privacyStatus;
  }

  @override
  int get hashCode => Object.hash(
    Object.hash(
      categoryId,
      categoryName,
      categorySlug,
      search,
      userId,
      userName,
      createdFrom == null
          ? null
          : DateTime(createdFrom!.year, createdFrom!.month, createdFrom!.day),
      createdTo == null
          ? null
          : DateTime(createdTo!.year, createdTo!.month, createdTo!.day),
      createdTimeFromMinutes,
      createdTimeToMinutes,
    ),
    Object.hash(
      type,
      sort,
      locationCity,
      locationLatitude,
      locationLongitude,
      locationRadiusKm,
      isAuctionable,
      isStory,
      isAd,
      status,
      privacyStatus,
    ),
  );
}

bool _dateEq(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Mutually exclusive post-type filter selection.
enum PostTypeFilter { all, auction, ads }

const _unset = Object();
