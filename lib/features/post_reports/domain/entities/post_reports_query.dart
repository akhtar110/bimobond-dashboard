import 'package:equatable/equatable.dart';

enum PostReportsSortOrder {
  newest('NEWEST'),
  oldest('OLDEST'),
  mostViews('MOST_VIEWS'),
  mostLikes('MOST_LIKES'),
  mostComments('MOST_COMMENTS'),
  mostReposts('MOST_REPOSTS'),
  mostSaves('MOST_SAVES');

  const PostReportsSortOrder(this.apiValue);
  final String apiValue;
}

class PostReportsListQuery extends Equatable {
  const PostReportsListQuery({
    this.search,
    this.status,
    this.type,
    this.userId,
    this.categoryId,
    this.hashtag,
    this.isAd,
    this.isStory,
    this.isAuctionable,
    this.sort = PostReportsSortOrder.newest,
  });

  final String? search;
  final String? status;
  final String? type;
  final String? userId;
  final String? categoryId;
  final String? hashtag;
  final bool? isAd;
  final bool? isStory;
  final bool? isAuctionable;
  final PostReportsSortOrder sort;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int limit,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort.apiValue,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }

    final statusValue = status?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      params['status'] = statusValue;
    }

    final typeValue = type?.trim();
    if (typeValue != null && typeValue.isNotEmpty) {
      params['type'] = typeValue;
    }

    if (userId != null && userId!.isNotEmpty) params['userId'] = userId;
    if (categoryId != null && categoryId!.isNotEmpty) {
      params['categoryId'] = categoryId;
    }

    final hashtagValue = hashtag?.trim();
    if (hashtagValue != null && hashtagValue.isNotEmpty) {
      params['hashtag'] = hashtagValue.toLowerCase();
    }

    if (isAd != null) params['isAd'] = isAd.toString();
    if (isStory != null) params['isStory'] = isStory.toString();
    if (isAuctionable != null) {
      params['isAuctionable'] = isAuctionable.toString();
    }

    return params;
  }

  PostReportsListQuery copyWith({
    String? search,
    String? status,
    String? type,
    String? userId,
    String? categoryId,
    String? hashtag,
    bool? isAd,
    bool? isStory,
    bool? isAuctionable,
    PostReportsSortOrder? sort,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearType = false,
    bool clearUserId = false,
    bool clearCategoryId = false,
    bool clearHashtag = false,
    bool clearIsAd = false,
    bool clearIsStory = false,
    bool clearIsAuctionable = false,
  }) {
    return PostReportsListQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      userId: clearUserId ? null : (userId ?? this.userId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      hashtag: clearHashtag ? null : (hashtag ?? this.hashtag),
      isAd: clearIsAd ? null : (isAd ?? this.isAd),
      isStory: clearIsStory ? null : (isStory ?? this.isStory),
      isAuctionable:
          clearIsAuctionable ? null : (isAuctionable ?? this.isAuctionable),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        search,
        status,
        type,
        userId,
        categoryId,
        hashtag,
        isAd,
        isStory,
        isAuctionable,
        sort,
      ];
}
