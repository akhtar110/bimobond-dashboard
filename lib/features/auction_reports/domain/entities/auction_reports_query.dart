import 'package:equatable/equatable.dart';

enum AuctionReportsSortOrder {
  newest('NEWEST'),
  oldest('OLDEST'),
  highestTotal('HIGHEST_TOTAL'),
  lowestTotal('LOWEST_TOTAL'),
  targetPrice('TARGET_PRICE'),
  mostBids('MOST_BIDS'),
  mostGifts('MOST_GIFTS'),
  recentlyEnded('RECENTLY_ENDED');

  const AuctionReportsSortOrder(this.apiValue);
  final String apiValue;
}

class AuctionReportsListQuery extends Equatable {
  const AuctionReportsListQuery({
    this.search,
    this.status,
    this.hostId,
    this.winnerId,
    this.postId,
    this.liveId,
    this.hasWinner,
    this.sort = AuctionReportsSortOrder.newest,
  });

  final String? search;
  final String? status;
  final String? hostId;
  final String? winnerId;
  final String? postId;
  final String? liveId;
  final bool? hasWinner;
  final AuctionReportsSortOrder sort;

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

    if (hostId != null && hostId!.isNotEmpty) params['hostId'] = hostId;
    if (winnerId != null && winnerId!.isNotEmpty) params['winnerId'] = winnerId;
    if (postId != null && postId!.isNotEmpty) params['postId'] = postId;
    if (liveId != null && liveId!.isNotEmpty) params['liveId'] = liveId;
    if (hasWinner != null) params['hasWinner'] = hasWinner.toString();

    return params;
  }

  AuctionReportsListQuery copyWith({
    String? search,
    String? status,
    String? hostId,
    String? winnerId,
    String? postId,
    String? liveId,
    bool? hasWinner,
    AuctionReportsSortOrder? sort,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearHostId = false,
    bool clearWinnerId = false,
    bool clearPostId = false,
    bool clearLiveId = false,
    bool clearHasWinner = false,
  }) {
    return AuctionReportsListQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      hostId: clearHostId ? null : (hostId ?? this.hostId),
      winnerId: clearWinnerId ? null : (winnerId ?? this.winnerId),
      postId: clearPostId ? null : (postId ?? this.postId),
      liveId: clearLiveId ? null : (liveId ?? this.liveId),
      hasWinner: clearHasWinner ? null : (hasWinner ?? this.hasWinner),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        search,
        status,
        hostId,
        winnerId,
        postId,
        liveId,
        hasWinner,
        sort,
      ];
}
