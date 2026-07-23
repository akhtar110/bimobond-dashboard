part of 'seller_verification_bloc.dart';

sealed class SellerVerificationState extends Equatable {
  const SellerVerificationState();

  @override
  List<Object?> get props => [];
}

class SellerVerificationInitial extends SellerVerificationState {
  const SellerVerificationInitial();
}

class SellerVerificationLoading extends SellerVerificationState {
  const SellerVerificationLoading();
}

class SellerVerificationLoaded extends SellerVerificationState {
  const SellerVerificationLoaded({
    required this.applications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.statusFilter,
    this.searchQuery = '',
    this.isFetching = false,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<SellerVerificationApplicationEntity> applications;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? statusFilter;
  final String searchQuery;
  final bool isFetching;
  final bool isLoadingMore;
  final bool isMutating;
  final String? feedbackMessage;
  final bool feedbackIsError;

  bool get hasReachedMax => currentPage >= lastPage;

  int get pendingCount =>
      applications.where((a) => a.status == 'PENDING').length;
  int get approvedCount =>
      applications.where((a) => a.status == 'APPROVED').length;
  int get rejectedCount =>
      applications.where((a) => a.status == 'REJECTED').length;

  SellerVerificationLoaded copyWith({
    List<SellerVerificationApplicationEntity>? applications,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool? isFetching,
    bool? isLoadingMore,
    bool? isMutating,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return SellerVerificationLoaded(
      applications: applications ?? this.applications,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isFetching: isFetching ?? this.isFetching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: clearFeedback
          ? false
          : (feedbackIsError ?? this.feedbackIsError),
    );
  }

  @override
  List<Object?> get props => [
        applications,
        currentPage,
        lastPage,
        total,
        statusFilter,
        searchQuery,
        isFetching,
        isLoadingMore,
        isMutating,
        feedbackMessage,
        feedbackIsError,
      ];
}

class SellerVerificationError extends SellerVerificationState {
  const SellerVerificationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
