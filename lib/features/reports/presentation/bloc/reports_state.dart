part of 'reports_bloc.dart';

sealed class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

// ── Navigation side-effect ──────────────────────────────────────────────────
// Emitted as a one-shot field on ReportsLoaded so the BlocListener
// can drive Navigator.pushNamed without putting routing logic in the BLoC.

sealed class ReportsNavigation {}

/// Navigate to the reported user's profile.
class NavigateToUser extends ReportsNavigation {
  NavigateToUser({
    required this.userId,
    this.username,
    this.fullName,
    this.avatarUrl,
  });
  final String userId;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
}

/// Navigate to PostManagementDetailScreen for the reported post.
/// Optionally carries a commentId when the report targets a comment.
class NavigateToPost extends ReportsNavigation {
  NavigateToPost({
    required this.postId,
    this.commentId,
    this.authorUserId,
    this.authorUsername,
    this.authorFullName,
    this.authorAvatarUrl,
  });

  final String postId;
  final String? commentId;
  final String? authorUserId;
  final String? authorUsername;
  final String? authorFullName;
  final String? authorAvatarUrl;
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportsLoaded extends ReportsState {
  ReportsLoaded({
    required this.reports,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.statusFilter,
    this.typeFilter,
    this.isLoadingMore = false,
    this.updatingId,
    this.errorMessage,
    this.pendingNavigation,
  });

  final List<ReportEntity> reports;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? statusFilter;
  final String? typeFilter;
  final bool isLoadingMore;

  /// The ID of the report whose status is currently being changed.
  final String? updatingId;

  /// One-shot error from an optimistic update failure.
  final String? errorMessage;

  /// One-shot navigation target — consumed and cleared by the BlocListener.
  final ReportsNavigation? pendingNavigation;

  bool get hasReachedMax => currentPage >= lastPage;

  ReportsLoaded copyWith({
    List<ReportEntity>? reports,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    String? typeFilter,
    bool? isLoadingMore,
    String? updatingId,
    bool clearUpdatingId = false,
    String? errorMessage,
    ReportsNavigation? pendingNavigation,
    bool clearNavigation = false,
  }) =>
      ReportsLoaded(
        reports: reports ?? this.reports,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        total: total ?? this.total,
        statusFilter: statusFilter ?? this.statusFilter,
        typeFilter: typeFilter ?? this.typeFilter,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        updatingId: clearUpdatingId ? null : (updatingId ?? this.updatingId),
        errorMessage: errorMessage,
        pendingNavigation:
            clearNavigation ? null : (pendingNavigation ?? this.pendingNavigation),
      );
}

class ReportsError extends ReportsState {
  ReportsError(this.message);
  final String message;
}
