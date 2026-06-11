/// Mirrors backend `AdminAuctionsSortOrder` enum.
enum AdminAuctionsSortOrder {
  newest('NEWEST'),
  oldest('OLDEST'),
  highestTotal('HIGHEST_TOTAL'),
  lowestTotal('LOWEST_TOTAL'),
  targetPrice('TARGET_PRICE'),
  recentlyEnded('RECENTLY_ENDED');

  const AdminAuctionsSortOrder(this.apiValue);
  final String apiValue;
}

/// Mirrors backend `AdminAuctionsQueryDto` for GET /auctions/admin/all.
class AdminAuctionsQuery {
  const AdminAuctionsQuery({
    this.search,
    this.status,
    this.hostId,
    this.winnerId,
    this.postId,
    this.liveId,
    this.hasWinner,
    this.hasPost,
    this.hasLive,
    this.sort = AdminAuctionsSortOrder.newest,
  });

  final String? search;
  final String? status;
  final String? hostId;
  final String? winnerId;
  final String? postId;
  final String? liveId;
  final bool? hasWinner;
  final bool? hasPost;
  final bool? hasLive;
  final AdminAuctionsSortOrder sort;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int limit,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort.apiValue,
    };

    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['search'] = trimmed;
    }

    final statusValue = status?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      params['status'] = statusValue;
    }

    if (hostId != null) params['hostId'] = hostId;
    if (winnerId != null) params['winnerId'] = winnerId;
    if (postId != null) params['postId'] = postId;
    if (liveId != null) params['liveId'] = liveId;

    if (hasWinner != null) params['hasWinner'] = hasWinner.toString();
    if (hasPost != null) params['hasPost'] = hasPost.toString();
    if (hasLive != null) params['hasLive'] = hasLive.toString();

    return params;
  }
}
