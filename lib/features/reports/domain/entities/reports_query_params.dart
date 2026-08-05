import 'package:equatable/equatable.dart';

class ReportsQueryParams extends Equatable {
  const ReportsQueryParams({
    this.page = 1,
    this.limit = 15,
    this.status,
    this.type,
    this.reporterId,
    this.reportedUserId,
    this.postId,
    this.commentId,
    this.storyId,
    this.search,
    this.startDate,
    this.endDate,
    this.sortBy,
    this.sortOrder,
  });

  final int page;
  final int limit;
  final String? status;
  final String? type;
  final String? reporterId;
  final String? reportedUserId;
  final String? postId;
  final String? commentId;
  final String? storyId;
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder;

  ReportsQueryParams copyWith({
    int? page,
    int? limit,
    String? status,
    String? type,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
    bool clearStatus = false,
    bool clearType = false,
    bool clearReporterId = false,
    bool clearReportedUserId = false,
    bool clearPostId = false,
    bool clearCommentId = false,
    bool clearStoryId = false,
    bool clearSearch = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSortBy = false,
    bool clearSortOrder = false,
  }) {
    return ReportsQueryParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      reporterId: clearReporterId ? null : (reporterId ?? this.reporterId),
      reportedUserId:
          clearReportedUserId ? null : (reportedUserId ?? this.reportedUserId),
      postId: clearPostId ? null : (postId ?? this.postId),
      commentId: clearCommentId ? null : (commentId ?? this.commentId),
      storyId: clearStoryId ? null : (storyId ?? this.storyId),
      search: clearSearch ? null : (search ?? this.search),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortOrder: clearSortOrder ? null : (sortOrder ?? this.sortOrder),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (type != null && type!.isNotEmpty) 'type': type,
      if (reporterId != null && reporterId!.isNotEmpty)
        'reporterId': reporterId,
      if (reportedUserId != null && reportedUserId!.isNotEmpty)
        'userId': reportedUserId,
      if (reportedUserId != null && reportedUserId!.isNotEmpty)
        'reportedUserId': reportedUserId,
      if (postId != null && postId!.isNotEmpty) 'postId': postId,
      if (commentId != null && commentId!.isNotEmpty) 'commentId': commentId,
      if (storyId != null && storyId!.isNotEmpty) 'storyId': storyId,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (startDate != null)
        'from': startDate!.toUtc().toIso8601String(),
      if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
      if (endDate != null) 'to': endDate!.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
      if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder!.isNotEmpty) 'sortOrder': sortOrder,
      if (sortOrder != null && sortOrder!.isNotEmpty) 'sort': sortOrder,
    };
  }

  @override
  List<Object?> get props => [
        page,
        limit,
        status,
        type,
        reporterId,
        reportedUserId,
        postId,
        commentId,
        storyId,
        search,
        startDate,
        endDate,
        sortBy,
        sortOrder,
      ];
}
