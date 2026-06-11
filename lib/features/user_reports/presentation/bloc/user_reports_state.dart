part of 'user_reports_bloc.dart';

sealed class UserReportsState extends Equatable {
  const UserReportsState();

  @override
  List<Object?> get props => [];
}

class UserReportsInitial extends UserReportsState {
  const UserReportsInitial();
}

class UserReportsLoading extends UserReportsState {
  const UserReportsLoading({this.previous});
  final UserReportsLoaded? previous;

  @override
  List<Object?> get props => [previous];
}

class UserReportsLoaded extends UserReportsState {
  const UserReportsLoaded({
    required this.query,
    this.overview,
    this.overviewLoading = false,
    this.overviewError,
    this.overviewDays = 30,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.listLoading = false,
    this.listLoadingMore = false,
    this.listError,
    this.detail,
    this.detailUserId,
    this.detailLoading = false,
    this.detailError,
    this.detailDays = 30,
  });

  final UserReportListQuery query;
  final UserReportsOverviewEntity? overview;
  final bool overviewLoading;
  final String? overviewError;
  final int overviewDays;
  final List<UserReportListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool listLoading;
  final bool listLoadingMore;
  final String? listError;
  final UserReportDetailEntity? detail;
  final String? detailUserId;
  final bool detailLoading;
  final String? detailError;
  final int detailDays;

  bool get hasReachedMax => currentPage >= lastPage;

  UserReportsLoaded copyWith({
    UserReportListQuery? query,
    UserReportsOverviewEntity? overview,
    bool? overviewLoading,
    String? overviewError,
    bool clearOverviewError = false,
    int? overviewDays,
    List<UserReportListItemEntity>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? listLoading,
    bool? listLoadingMore,
    String? listError,
    bool clearListError = false,
    UserReportDetailEntity? detail,
    String? detailUserId,
    bool? detailLoading,
    String? detailError,
    bool clearDetailError = false,
    int? detailDays,
    bool clearDetail = false,
  }) {
    return UserReportsLoaded(
      query: query ?? this.query,
      overview: overview ?? this.overview,
      overviewLoading: overviewLoading ?? this.overviewLoading,
      overviewError:
          clearOverviewError ? null : (overviewError ?? this.overviewError),
      overviewDays: overviewDays ?? this.overviewDays,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      listLoading: listLoading ?? this.listLoading,
      listLoadingMore: listLoadingMore ?? this.listLoadingMore,
      listError: clearListError ? null : (listError ?? this.listError),
      detail: clearDetail ? null : (detail ?? this.detail),
      detailUserId: detailUserId ?? this.detailUserId,
      detailLoading: detailLoading ?? this.detailLoading,
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      detailDays: detailDays ?? this.detailDays,
    );
  }

  @override
  List<Object?> get props => [
        query,
        overview,
        overviewLoading,
        overviewError,
        overviewDays,
        items,
        currentPage,
        lastPage,
        total,
        listLoading,
        listLoadingMore,
        listError,
        detail,
        detailUserId,
        detailLoading,
        detailError,
        detailDays,
      ];
}

class UserReportsError extends UserReportsState {
  const UserReportsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
