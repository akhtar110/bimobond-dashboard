import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_user_by_id.dart';
import '../../data/models/comment_model.dart';
import '../../domain/entities/activity_context.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/managed_post_author_enrichment.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/usecases/ban_post_usecase.dart';
import '../../domain/usecases/delete_comment_admin.dart';
import '../../domain/usecases/delete_managed_post.dart';
import '../../domain/usecases/get_managed_post_by_id.dart';
import '../../domain/entities/post_engagement_user_item.dart';
import '../../domain/usecases/get_post_comments.dart';
import '../../domain/usecases/get_post_engagement_users.dart';
import '../../domain/usecases/hide_post_usecase.dart';
import '../../domain/usecases/update_managed_post.dart';
import '../../domain/usecases/update_post_details_usecase.dart';
import '../../domain/usecases/update_post_status_usecase.dart';
import '../../domain/usecases/add_post_note_usecase.dart';
import '../../domain/usecases/get_post_moderation_timeline_usecase.dart';
import '../../domain/entities/post_moderation_entities.dart';
import '../services/post_applied_catalog_resolver.dart';
import '../utils/post_detail_labels.dart';
import '../../../post_reports/domain/entities/post_report_entities.dart';
import '../../../post_reports/domain/usecases/get_post_report_detail.dart';
import '../../../filters_effects/domain/entities/filters_effects_entities.dart';
import '../../../filters_effects/domain/usecases/filters_effects_usecases.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_reports_usecase.dart';

sealed class PostManagementEvent {}

class LoadManagedPostEvent extends PostManagementEvent {
  LoadManagedPostEvent(
    this.post, {
    this.sourceUser,
    this.activityContext,
    this.skipComments = false,
  });

  final ManagedPostEntity post;
  final UserEntity? sourceUser;
  final ActivityContext? activityContext;
  final bool skipComments;
}

class ChangeManagedPostFieldEvent extends PostManagementEvent {
  ChangeManagedPostFieldEvent(this.draft);
  final ManagedPostEntity draft;
}

class UpdateManagedPostEvent extends PostManagementEvent {}

class DeleteManagedPostEvent extends PostManagementEvent {}

class UpdatePostDetailsEvent extends PostManagementEvent {
  UpdatePostDetailsEvent({this.description, this.category});
  final String? description;
  final String? category;
}

class HidePostEvent extends PostManagementEvent {}

class BanPostEvent extends PostManagementEvent {}

class UpdatePostStatusEvent extends PostManagementEvent {
  UpdatePostStatusEvent(
    this.status, {
    this.reason,
    this.note,
  });

  final String status;
  final String? reason;
  final String? note;
}

class SubmitPostInternalNoteEvent extends PostManagementEvent {
  SubmitPostInternalNoteEvent(this.note);
  final String note;
}

class LoadPostModerationTimelineEvent extends PostManagementEvent {
  LoadPostModerationTimelineEvent({this.refresh = false});
  final bool refresh;
}

class LoadMorePostModerationTimelineEvent extends PostManagementEvent {}

class LoadPostAdvancedAnalyticsEvent extends PostManagementEvent {}

class LoadPostFilterEffectEvent extends PostManagementEvent {}

class LoadPostModerationReportsEvent extends PostManagementEvent {
  LoadPostModerationReportsEvent({this.refresh = false});
  final bool refresh;
}

class ClearPostManagementMessagesEvent extends PostManagementEvent {}

class LoadPostCommentsEvent extends PostManagementEvent {}

class LoadMorePostCommentsEvent extends PostManagementEvent {}

class DeletePostCommentAdminEvent extends PostManagementEvent {
  DeletePostCommentAdminEvent(this.commentId);
  final String commentId;
}

class LoadPostEngagementUsersEvent extends PostManagementEvent {
  LoadPostEngagementUsersEvent(this.kind);
  final PostEngagementKind kind;
}

class LoadMorePostEngagementUsersEvent extends PostManagementEvent {
  LoadMorePostEngagementUsersEvent(this.kind);
  final PostEngagementKind kind;
}

class PostEngagementListState {
  const PostEngagementListState({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loaded = false,
  });

  final List<PostEngagementUserItem> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool loaded;

  PostEngagementListState copyWith({
    List<PostEngagementUserItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? loaded,
    bool clearError = false,
  }) {
    return PostEngagementListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      loaded: loaded ?? this.loaded,
    );
  }
}

sealed class PostManagementState {}

class PostManagementInitial extends PostManagementState {}

class PostManagementLoading extends PostManagementState {}

class PostManagementLoaded extends PostManagementState {
  PostManagementLoaded({
    required this.post,
    required this.draft,
    this.sourceUser,
    this.activityContext,
    this.isSaving = false,
    this.isDeleting = false,
    this.isActioning = false,
    this.successMessage,
    this.errorMessage,
    this.comments = const [],
    this.commentsPage = 0,
    this.commentsHasMore = false,
    this.isCommentsLoading = false,
    this.isCommentsLoadingMore = false,
    this.commentsError,
    this.deletingCommentId,
    this.likes = const PostEngagementListState(),
    this.views = const PostEngagementListState(),
    this.mentions = const PostEngagementListState(),
    this.reposts = const PostEngagementListState(),
    this.isSubmittingNote = false,
    this.isTimelineLoading = false,
    this.isTimelineLoadingMore = false,
    this.timelineError,
    this.timelineEntries = const [],
    this.timelinePage = 0,
    this.timelineHasMore = false,
    this.isAnalyticsLoading = false,
    this.analyticsError,
    this.analyticsDetail,
    this.isFilterEffectLoading = false,
    this.filterEffectError,
    this.postFilter,
    this.postEffect,
    this.isModerationReportsLoading = false,
    this.moderationReportsError,
    this.moderationReports = const [],
    this.moderationReportsTotal = 0,
  });

  final ManagedPostEntity post;
  final ManagedPostEntity draft;
  final UserEntity? sourceUser;
  final ActivityContext? activityContext;
  final bool isSaving;
  final bool isDeleting;
  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;

  final List<CommentEntity> comments;
  final int commentsPage;
  final bool commentsHasMore;
  final bool isCommentsLoading;
  final bool isCommentsLoadingMore;
  final String? commentsError;
  final String? deletingCommentId;
  final PostEngagementListState likes;
  final PostEngagementListState views;
  final PostEngagementListState mentions;
  final PostEngagementListState reposts;

  final bool isSubmittingNote;
  final bool isTimelineLoading;
  final bool isTimelineLoadingMore;
  final String? timelineError;
  final List<PostModerationTimelineEntry> timelineEntries;
  final int timelinePage;
  final bool timelineHasMore;
  final bool isAnalyticsLoading;
  final String? analyticsError;
  final PostReportDetailEntity? analyticsDetail;

  final bool isFilterEffectLoading;
  final String? filterEffectError;
  final CameraFilterEntity? postFilter;
  final CameraEffectEntity? postEffect;

  final bool isModerationReportsLoading;
  final String? moderationReportsError;
  final List<ReportEntity> moderationReports;
  final int moderationReportsTotal;

  PostEngagementListState engagementFor(PostEngagementKind kind) {
    return switch (kind) {
      PostEngagementKind.likes => likes,
      PostEngagementKind.views => views,
      PostEngagementKind.mentions => mentions,
      PostEngagementKind.reposts => reposts,
    };
  }

  PostManagementLoaded copyWith({
    ManagedPostEntity? post,
    ManagedPostEntity? draft,
    UserEntity? sourceUser,
    ActivityContext? activityContext,
    bool? isSaving,
    bool? isDeleting,
    bool? isActioning,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    List<CommentEntity>? comments,
    int? commentsPage,
    bool? commentsHasMore,
    bool? isCommentsLoading,
    bool? isCommentsLoadingMore,
    String? commentsError,
    bool clearCommentsError = false,
    String? deletingCommentId,
    bool clearDeletingCommentId = false,
    PostEngagementListState? likes,
    PostEngagementListState? views,
    PostEngagementListState? mentions,
    PostEngagementListState? reposts,
    bool? isSubmittingNote,
    bool? isTimelineLoading,
    bool? isTimelineLoadingMore,
    String? timelineError,
    bool clearTimelineError = false,
    List<PostModerationTimelineEntry>? timelineEntries,
    int? timelinePage,
    bool? timelineHasMore,
    bool? isAnalyticsLoading,
    String? analyticsError,
    bool clearAnalyticsError = false,
    PostReportDetailEntity? analyticsDetail,
    bool clearAnalyticsDetail = false,
    bool? isFilterEffectLoading,
    String? filterEffectError,
    bool clearFilterEffectError = false,
    CameraFilterEntity? postFilter,
    bool clearPostFilter = false,
    CameraEffectEntity? postEffect,
    bool clearPostEffect = false,
    bool? isModerationReportsLoading,
    String? moderationReportsError,
    bool clearModerationReportsError = false,
    List<ReportEntity>? moderationReports,
    int? moderationReportsTotal,
  }) {
    return PostManagementLoaded(
      post: post ?? this.post,
      draft: draft ?? this.draft,
      sourceUser: sourceUser ?? this.sourceUser,
      activityContext: activityContext ?? this.activityContext,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isActioning: isActioning ?? this.isActioning,
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      comments: comments ?? this.comments,
      commentsPage: commentsPage ?? this.commentsPage,
      commentsHasMore: commentsHasMore ?? this.commentsHasMore,
      isCommentsLoading: isCommentsLoading ?? this.isCommentsLoading,
      isCommentsLoadingMore:
          isCommentsLoadingMore ?? this.isCommentsLoadingMore,
      commentsError:
          clearCommentsError ? null : (commentsError ?? this.commentsError),
      deletingCommentId: clearDeletingCommentId
          ? null
          : (deletingCommentId ?? this.deletingCommentId),
      likes: likes ?? this.likes,
      views: views ?? this.views,
      mentions: mentions ?? this.mentions,
      reposts: reposts ?? this.reposts,
      isSubmittingNote: isSubmittingNote ?? this.isSubmittingNote,
      isTimelineLoading: isTimelineLoading ?? this.isTimelineLoading,
      isTimelineLoadingMore:
          isTimelineLoadingMore ?? this.isTimelineLoadingMore,
      timelineError:
          clearTimelineError ? null : (timelineError ?? this.timelineError),
      timelineEntries: timelineEntries ?? this.timelineEntries,
      timelinePage: timelinePage ?? this.timelinePage,
      timelineHasMore: timelineHasMore ?? this.timelineHasMore,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      analyticsError:
          clearAnalyticsError ? null : (analyticsError ?? this.analyticsError),
      analyticsDetail: clearAnalyticsDetail
          ? null
          : (analyticsDetail ?? this.analyticsDetail),
      isFilterEffectLoading:
          isFilterEffectLoading ?? this.isFilterEffectLoading,
      filterEffectError: clearFilterEffectError
          ? null
          : (filterEffectError ?? this.filterEffectError),
      postFilter: clearPostFilter ? null : (postFilter ?? this.postFilter),
      postEffect: clearPostEffect ? null : (postEffect ?? this.postEffect),
      isModerationReportsLoading:
          isModerationReportsLoading ?? this.isModerationReportsLoading,
      moderationReportsError: clearModerationReportsError
          ? null
          : (moderationReportsError ?? this.moderationReportsError),
      moderationReports: moderationReports ?? this.moderationReports,
      moderationReportsTotal:
          moderationReportsTotal ?? this.moderationReportsTotal,
    );
  }
}

class PostManagementDeleted extends PostManagementState {}

class PostManagementError extends PostManagementState {
  PostManagementError(this.message);
  final String message;
}

class PostManagementBloc extends Bloc<PostManagementEvent, PostManagementState> {
  PostManagementBloc({
    required this.getManagedPostById,
    required this.getUserById,
    required this.updateManagedPost,
    required this.deleteManagedPost,
    required this.updatePostDetails,
    required this.hidePost,
    required this.banPost,
    required this.updatePostStatus,
    required this.addPostNote,
    required this.getPostModerationTimeline,
    required this.getPostReportDetail,
    required this.getCameraFilter,
    required this.getCameraEffect,
    required this.getCameraFilters,
    required this.getCameraEffects,
    required this.getReports,
    required this.getPostComments,
    required this.deleteCommentAdmin,
    required this.getPostEngagementUsers,
  }) : super(PostManagementInitial()) {
    on<LoadManagedPostEvent>(_onLoad);
    on<ChangeManagedPostFieldEvent>(_onChangeField);
    on<UpdateManagedPostEvent>(_onUpdate);
    on<DeleteManagedPostEvent>(_onDelete);
    on<UpdatePostDetailsEvent>(_onUpdateDetails);
    on<HidePostEvent>(_onHide);
    on<BanPostEvent>(_onBan);
    on<UpdatePostStatusEvent>(_onUpdateStatus);
    on<SubmitPostInternalNoteEvent>(_onSubmitNote);
    on<LoadPostModerationTimelineEvent>(_onLoadTimeline);
    on<LoadMorePostModerationTimelineEvent>(_onLoadMoreTimeline);
    on<LoadPostAdvancedAnalyticsEvent>(_onLoadAnalytics);
    on<LoadPostFilterEffectEvent>(_onLoadFilterEffect);
    on<LoadPostModerationReportsEvent>(_onLoadModerationReports);
    on<ClearPostManagementMessagesEvent>(_onClearMessages);
    on<LoadPostCommentsEvent>(_onLoadComments);
    on<LoadMorePostCommentsEvent>(_onLoadMoreComments);
    on<DeletePostCommentAdminEvent>(_onDeleteComment);
    on<LoadPostEngagementUsersEvent>(_onLoadEngagementUsers);
    on<LoadMorePostEngagementUsersEvent>(_onLoadMoreEngagementUsers);
  }

  static const int _commentsLimit = 20;
  static const int _engagementLimit = 20;
  static const int _timelineLimit = 20;

  final GetManagedPostById getManagedPostById;
  final GetUserById getUserById;
  final UpdateManagedPost updateManagedPost;
  final DeleteManagedPost deleteManagedPost;
  final UpdatePostDetails updatePostDetails;
  final HidePost hidePost;
  final BanPost banPost;
  final UpdatePostStatus updatePostStatus;
  final AddPostNote addPostNote;
  final GetPostModerationTimeline getPostModerationTimeline;
  final GetPostReportDetail getPostReportDetail;
  final GetCameraFilterUseCase getCameraFilter;
  final GetCameraEffectUseCase getCameraEffect;
  final GetCameraFiltersUseCase getCameraFilters;
  final GetCameraEffectsUseCase getCameraEffects;
  final GetReports getReports;
  final GetPostComments getPostComments;
  final DeleteCommentAdmin deleteCommentAdmin;
  final GetPostEngagementUsers getPostEngagementUsers;

  Future<void> _onLoad(
    LoadManagedPostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    var stub = prepareManagedPostForDetailNavigation(
      event.post,
      sourceUser: event.sourceUser,
    );
    stub = await _hydrateAuthorProfileIfNeeded(stub, event.sourceUser);

    emit(
      _loadedFromPost(
        stub,
        sourceUser: event.sourceUser,
        activityContext: event.activityContext,
        skipComments: event.skipComments,
      ),
    );
    if (!event.skipComments) {
      add(LoadPostCommentsEvent());
    }
    add(LoadPostFilterEffectEvent());
    add(LoadPostModerationReportsEvent());

    try {
      final fresh = await getManagedPostById(event.post.id);
      var hydrated = hydrateManagedPostMedia(
        enrichManagedPostAuthor(
          enrichManagedPostContent(fresh, fallback: stub),
          fallback: stub,
          author: _authorHint(stub, event.sourceUser),
        ),
      );
      hydrated = await _hydrateAuthorProfileIfNeeded(
        hydrated,
        event.sourceUser,
      );
      final current = state;
      if (current is PostManagementLoaded) {
        emit(
          current.copyWith(
            post: hydrated,
            draft: hydrated,
          ),
        );
        add(LoadPostFilterEffectEvent());
        add(LoadPostModerationReportsEvent(refresh: true));
      } else {
        emit(
          _loadedFromPost(
            hydrated,
            sourceUser: event.sourceUser,
            activityContext: event.activityContext,
            skipComments: event.skipComments,
          ),
        );
        if (!event.skipComments) {
          add(LoadPostCommentsEvent());
        }
        add(LoadPostFilterEffectEvent());
        add(LoadPostModerationReportsEvent());
      }
    } catch (_) {
      // Keep the navigation stub already shown above.
    }
  }

  PostManagementLoaded _loadedFromPost(
    ManagedPostEntity post, {
    UserEntity? sourceUser,
    ActivityContext? activityContext,
    bool skipComments = false,
  }) {
    return PostManagementLoaded(
      post: post,
      draft: post,
      sourceUser: sourceUser,
      activityContext: activityContext,
      isCommentsLoading: !skipComments,
      likes: PostEngagementListState(items: post.recentLikes),
      views: PostEngagementListState(items: post.recentViews),
      mentions: PostEngagementListState(items: post.recentMentions),
      reposts: PostEngagementListState(
        items: post.recentReposts
            .map(_repostItemFromMap)
            .where((item) => item.userId.isNotEmpty || item.username != null)
            .toList(),
      ),
    );
  }

  static PostEngagementUserItem _repostItemFromMap(Map<String, dynamic> raw) {
    final user = raw['user'] is Map
        ? Map<String, dynamic>.from(raw['user'] as Map)
        : (raw['repostedBy'] is Map
            ? Map<String, dynamic>.from(raw['repostedBy'] as Map)
            : (raw['reposter'] is Map
                ? Map<String, dynamic>.from(raw['reposter'] as Map)
                : raw));
    final quote = raw['quote']?.toString() ?? raw['caption']?.toString();
    return PostEngagementUserItem(
      id: raw['id']?.toString() ??
          raw['repostId']?.toString() ??
          user['id']?.toString() ??
          '',
      userId: raw['userId']?.toString() ?? user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? user['name']?.toString(),
      fullName: user['fullName']?.toString(),
      avatarUrl: (user['avatarUrl'] ??
              user['avatar'] ??
              user['profileImage'])
          ?.toString(),
      isVerified: user['isVerified'] as bool? ?? false,
      isBanned: user['isBanned'] as bool? ?? false,
      createdAt: DateTime.tryParse(
            (raw['createdAt'] ?? raw['repostedAt'] ?? user['repostedAt'])
                    ?.toString() ??
                '',
          ) ??
          DateTime.now(),
      subtitle: quote != null && quote.trim().isNotEmpty ? quote.trim() : null,
    );
  }

  bool _authorStatsMissing(ManagedPostEntity post) {
    return post.userFollowersCount == 0 &&
        post.userFollowingCount == 0 &&
        post.userPostsCount == 0;
  }

  bool _authorLocationMissing(ManagedPostEntity post) {
    return post.location == null || !post.location!.hasDisplayData;
  }

  Future<ManagedPostEntity> _hydrateAuthorProfileIfNeeded(
    ManagedPostEntity post,
    UserEntity? sourceUser,
  ) async {
    if (post.userId.isEmpty) return post;

    final hinted = _authorHint(post, sourceUser);
    final enrichedHint = hinted != null
        ? enrichManagedPostAuthor(post, author: hinted)
        : post;

    final statsOk = !_authorStatsMissing(enrichedHint);
    final locationOk = !_authorLocationMissing(enrichedHint);

    if (statsOk && locationOk) return enrichedHint;

    try {
      final detail = await getUserById(post.userId);
      return enrichManagedPostAuthor(
        post,
        author: detail.user,
        fallback: post,
      );
    } catch (_) {
      return enrichedHint;
    }
  }

  /// Uses route [sourceUser] only when the post belongs to them, otherwise
  /// builds from author fields already hydrated on the navigation stub.
  UserEntity? _authorHint(ManagedPostEntity post, UserEntity? sourceUser) {
    if (sourceUser != null &&
        post.userId.isNotEmpty &&
        post.userId == sourceUser.id) {
      return sourceUser;
    }
    if (post.userId.isEmpty) return null;
    return UserEntity(
      id: post.userId,
      username: post.userName ?? post.userId,
      fullName: post.userFullName,
      email: post.userEmail,
      avatarUrl: post.userProfileImage,
      isVerified: post.userIsVerified,
      isPrivate: false,
      allowComments: true,
      allowDirectMsgs: true,
      language: 'en',
      theme: 'light',
      followerCount: post.userFollowersCount,
      followingCount: post.userFollowingCount,
      postCount: post.userPostsCount,
      totalLikes: 0,
      isBanned: post.userIsBanned,
      roles: const [UserRole.user],
      createdAt: post.userJoinedAt,
      lastLocation: sourceUser?.lastLocation,
      city: sourceUser?.city,
      region: sourceUser?.region,
      country: sourceUser?.country,
    );
  }

  void _onChangeField(
    ChangeManagedPostFieldEvent event,
    Emitter<PostManagementState> emit,
  ) {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(draft: event.draft, clearMessages: true));
  }

  Future<void> _onUpdate(
    UpdateManagedPostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isSaving: true, clearMessages: true));

    try {
      final updateData = buildManagedPostUpdateDiff(current.post, current.draft);
      if (!managedPostUpdateDataHasChanges(updateData)) {
        emit(current.copyWith(isSaving: false));
        return;
      }

      final raw = await updateManagedPost(
        current.draft.id,
        updateData,
      );
      final updated = mergeManagedPostForListDisplay(current.post, raw);

      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isSaving: false,
          successMessage: 'Post updated successfully',
        ),
      );
      add(LoadPostModerationTimelineEvent(refresh: true));
    } catch (e) {
      emit(
        current.copyWith(
          isSaving: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onDelete(
    DeleteManagedPostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isDeleting: true));

    try {
      await deleteManagedPost(current.draft.id);
      emit(PostManagementDeleted());
    } catch (e) {
      emit(
        current.copyWith(
          isDeleting: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onUpdateDetails(
    UpdatePostDetailsEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final raw = await updatePostDetails(
        current.post.id,
        description: event.description,
        category: event.category,
      );
      final updated = mergeManagedPostForListDisplay(current.post, raw);
      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isActioning: false,
          successMessage: 'Post details updated',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onHide(
    HidePostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final raw = await hidePost(current.post.id);
      final updated = mergeManagedPostForListDisplay(current.post, raw);
      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isActioning: false,
          successMessage: 'Post hidden successfully',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onBan(
    BanPostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final raw = await banPost(current.post.id);
      final updated = mergeManagedPostForListDisplay(current.post, raw);
      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isActioning: false,
          successMessage: 'Post banned successfully',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onUpdateStatus(
    UpdatePostStatusEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(current.copyWith(isActioning: true, clearMessages: true));
    try {
      final raw = await updatePostStatus(
        current.post.id,
        event.status,
        reason: event.reason,
        note: event.note,
      );
      final updated = mergeManagedPostForListDisplay(current.post, raw);
      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isActioning: false,
          successMessage: 'statusUpdated',
        ),
      );
      add(LoadPostModerationTimelineEvent(refresh: true));
      if (current.analyticsDetail != null) {
        add(LoadPostAdvancedAnalyticsEvent());
      }
    } catch (e) {
      emit(
        current.copyWith(
          isActioning: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onSubmitNote(
    SubmitPostInternalNoteEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;
    final note = event.note.trim();
    if (note.isEmpty) return;

    emit(current.copyWith(isSubmittingNote: true, clearMessages: true));
    try {
      await addPostNote(current.post.id, note);
      emit(
        current.copyWith(
          isSubmittingNote: false,
          successMessage: 'noteAdded',
        ),
      );
      add(LoadPostModerationTimelineEvent(refresh: true));
    } catch (e) {
      emit(
        current.copyWith(
          isSubmittingNote: false,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onLoadTimeline(
    LoadPostModerationTimelineEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(
      current.copyWith(
        isTimelineLoading: true,
        clearTimelineError: true,
        timelineEntries: event.refresh ? [] : current.timelineEntries,
        timelinePage: event.refresh ? 0 : current.timelinePage,
        timelineHasMore: event.refresh ? false : current.timelineHasMore,
      ),
    );

    try {
      final page = await getPostModerationTimeline(
        current.post.id,
        page: 1,
        limit: _timelineLimit,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          isTimelineLoading: false,
          timelineEntries: page.items,
          timelinePage: page.page,
          timelineHasMore: page.hasMore,
        ),
      );
      if (page.items.isEmpty &&
          (state as PostManagementLoaded).analyticsDetail == null) {
        add(LoadPostAdvancedAnalyticsEvent());
      }
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isTimelineLoading: false,
          timelineError: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onLoadMoreTimeline(
    LoadMorePostModerationTimelineEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded ||
        !current.timelineHasMore ||
        current.isTimelineLoadingMore) {
      return;
    }

    emit(current.copyWith(isTimelineLoadingMore: true));
    try {
      final nextPage = current.timelinePage + 1;
      final page = await getPostModerationTimeline(
        current.post.id,
        page: nextPage,
        limit: _timelineLimit,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          isTimelineLoadingMore: false,
          timelineEntries: [...current.timelineEntries, ...page.items],
          timelinePage: page.page,
          timelineHasMore: page.hasMore,
        ),
      );
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isTimelineLoadingMore: false,
          timelineError: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onLoadAnalytics(
    LoadPostAdvancedAnalyticsEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;
    if (current.isAnalyticsLoading) return;

    emit(current.copyWith(isAnalyticsLoading: true, clearAnalyticsError: true));
    try {
      final detail = await getPostReportDetail(
        postId: current.post.id,
        query: const ReportPeriodQuery(days: 30),
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          isAnalyticsLoading: false,
          analyticsDetail: detail,
        ),
      );
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isAnalyticsLoading: false,
          analyticsError: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onLoadFilterEffect(
    LoadPostFilterEffectEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    final appliedFilter = current.post.appliedFilter;
    final appliedEffect = current.post.appliedEffect;
    final hasFilter = appliedFilter?.hasData ?? false;
    final hasEffect = appliedEffect?.hasData ?? false;
    if (!hasFilter && !hasEffect) {
      emit(
        current.copyWith(
          isFilterEffectLoading: false,
          clearFilterEffectError: true,
          clearPostFilter: true,
          clearPostEffect: true,
        ),
      );
      return;
    }

    if (current.isFilterEffectLoading) return;

    emit(
      current.copyWith(
        isFilterEffectLoading: true,
        clearFilterEffectError: true,
      ),
    );

    CameraFilterEntity? filter;
    CameraEffectEntity? effect;

    if (hasFilter) {
      filter = await PostAppliedCatalogResolver.resolveFilter(
        ref: appliedFilter!,
        getById: getCameraFilter,
        listFilters: getCameraFilters,
      );
    }
    if (hasEffect) {
      effect = await PostAppliedCatalogResolver.resolveEffect(
        ref: appliedEffect!,
        getById: getCameraEffect,
        listEffects: getCameraEffects,
      );
    }

    emit(
      (state as PostManagementLoaded).copyWith(
        isFilterEffectLoading: false,
        postFilter: filter,
        postEffect: effect,
        clearFilterEffectError: true,
      ),
    );
  }

  Future<void> _onLoadModerationReports(
    LoadPostModerationReportsEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;
    if (current.isModerationReportsLoading && !event.refresh) return;

    emit(
      current.copyWith(
        isModerationReportsLoading: true,
        clearModerationReportsError: true,
      ),
    );

    try {
      final result = await getReports(
        postId: current.post.id,
        page: 1,
        limit: 20,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          isModerationReportsLoading: false,
          moderationReports: result.reports,
          moderationReportsTotal: result.total,
        ),
      );
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isModerationReportsLoading: false,
          moderationReportsError: _messageFrom(e),
        ),
      );
    }
  }

  void _onClearMessages(
    ClearPostManagementMessagesEvent event,
    Emitter<PostManagementState> emit,
  ) {
    final current = state;
    if (current is! PostManagementLoaded) return;
    emit(current.copyWith(clearMessages: true));
  }

  Future<void> _onLoadComments(
    LoadPostCommentsEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    emit(
      current.copyWith(
        isCommentsLoading: true,
        comments: [],
        commentsPage: 0,
        commentsHasMore: false,
        clearCommentsError: true,
        clearMessages: true,
      ),
    );

    try {
      final highlightId = current.activityContext?.highlightCommentId;
      final loaded = await _loadCommentsForPost(
        postId: current.post.id,
        highlightId: highlightId,
      );
      var comments = loaded.comments;
      comments = _ensureHighlightComment(
        comments,
        current.activityContext,
        current.post.id,
      );

      emit(
        (state as PostManagementLoaded).copyWith(
          comments: comments,
          commentsPage: loaded.page,
          commentsHasMore: loaded.hasMore,
          isCommentsLoading: false,
        ),
      );
    } catch (e) {
      final seeded = _ensureHighlightComment(
        const [],
        current.activityContext,
        current.post.id,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          comments: seeded,
          isCommentsLoading: false,
          commentsError: seeded.isEmpty ? _messageFrom(e) : null,
        ),
      );
    }
  }

  Future<PostCommentsPageEntity> _loadCommentsForPost({
    required String postId,
    String? highlightId,
  }) async {
    var pageNum = 1;
    var hasMore = true;
    final allComments = <CommentEntity>[];

    while (hasMore && pageNum <= 10) {
      final page = await getPostComments(
        postId,
        page: pageNum,
        limit: _commentsLimit,
      );
      allComments.addAll(page.comments);
      hasMore = page.hasMore;
      if (highlightId == null ||
          highlightId.isEmpty ||
          allComments.any((c) => c.id == highlightId)) {
        return PostCommentsPageEntity(
          comments: allComments,
          page: page.page,
          hasMore: hasMore,
        );
      }
      pageNum++;
    }

    return PostCommentsPageEntity(
      comments: allComments,
      page: pageNum,
      hasMore: hasMore,
    );
  }

  List<CommentEntity> _ensureHighlightComment(
    List<CommentEntity> comments,
    ActivityContext? context,
    String postId,
  ) {
    final highlightId = context?.highlightCommentId;
    if (highlightId == null || highlightId.isEmpty) return comments;
    if (comments.any((c) => c.id == highlightId)) return comments;

    final text = context?.commentText?.trim();
    if (text == null || text.isEmpty) return comments;

    final seed = CommentModel(
      id: highlightId,
      content: text,
      postId: postId,
      userId: context?.commentUserId ?? '',
      likeCount: 0,
      replyCount: 0,
      createdAt: context?.activityDate ?? DateTime.now(),
      username: context?.commentUsername,
    );
    return [seed, ...comments];
  }

  Future<void> _onLoadMoreComments(
    LoadMorePostCommentsEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;
    if (!current.commentsHasMore ||
        current.isCommentsLoadingMore ||
        current.isCommentsLoading) {
      return;
    }

    emit(current.copyWith(isCommentsLoadingMore: true, clearCommentsError: true));

    try {
      final nextPage = current.commentsPage + 1;
      final page = await getPostComments(
        current.post.id,
        page: nextPage,
        limit: _commentsLimit,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          comments: [...current.comments, ...page.comments],
          commentsPage: page.page,
          commentsHasMore: page.hasMore,
          isCommentsLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isCommentsLoadingMore: false,
          commentsError: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onDeleteComment(
    DeletePostCommentAdminEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;
    if (current.deletingCommentId != null) return;

    final previousComments = current.comments;
    final previousPost = current.post;
    final previousDraft = current.draft;

    final updatedComments =
        previousComments.where((c) => c.id != event.commentId).toList();
    final newCount =
        (previousPost.commentCount - 1).clamp(0, 1 << 30);
    final updatedPost = previousPost.copyWith(commentCount: newCount);
    final updatedDraft = previousDraft.copyWith(commentCount: newCount);

    emit(
      current.copyWith(
        comments: updatedComments,
        post: updatedPost,
        draft: updatedDraft,
        deletingCommentId: event.commentId,
        clearMessages: true,
        clearCommentsError: true,
      ),
    );

    try {
      await deleteCommentAdmin(event.commentId);
      emit(
        (state as PostManagementLoaded).copyWith(
          clearDeletingCommentId: true,
          successMessage: 'commentDeleted',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          comments: previousComments,
          post: previousPost,
          draft: previousDraft,
          clearDeletingCommentId: true,
          errorMessage: _messageFrom(e),
        ),
      );
    }
  }

  Future<void> _onLoadEngagementUsers(
    LoadPostEngagementUsersEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    final existing = current.engagementFor(event.kind);
    if (existing.isLoading) return;
    if (existing.loaded && existing.items.isNotEmpty) return;

    final resetLoaded = existing.loaded && existing.items.isEmpty;
    final loadingState = existing.copyWith(
      isLoading: true,
      clearError: true,
      loaded: resetLoaded ? false : existing.loaded,
    );

    emit(current.copyWith(
      likes: event.kind == PostEngagementKind.likes ? loadingState : null,
      views: event.kind == PostEngagementKind.views ? loadingState : null,
      mentions: event.kind == PostEngagementKind.mentions ? loadingState : null,
      reposts: event.kind == PostEngagementKind.reposts ? loadingState : null,
    ));

    try {
      final page = await getPostEngagementUsers(
        current.post.id,
        kind: event.kind,
        page: 1,
        limit: _engagementLimit,
        postAuthorId: current.post.userId,
      );
      final loaded = (state as PostManagementLoaded);
      final prior = loaded.engagementFor(event.kind);
      final mergedItems =
          page.items.isNotEmpty ? page.items : prior.items;
      final next = prior.copyWith(
        items: mergedItems,
        page: page.page,
        hasMore: page.hasMore,
        isLoading: false,
        loaded: true,
      );
      emit(loaded.copyWith(
        likes: event.kind == PostEngagementKind.likes ? next : null,
        views: event.kind == PostEngagementKind.views ? next : null,
        mentions: event.kind == PostEngagementKind.mentions ? next : null,
        reposts: event.kind == PostEngagementKind.reposts ? next : null,
      ));
    } catch (e) {
      final loaded = (state as PostManagementLoaded);
      final prior = loaded.engagementFor(event.kind);
      final failed = prior.copyWith(
        isLoading: false,
        loaded: true,
        error: _messageFrom(e),
      );
      emit(loaded.copyWith(
        likes: event.kind == PostEngagementKind.likes ? failed : null,
        views: event.kind == PostEngagementKind.views ? failed : null,
        mentions: event.kind == PostEngagementKind.mentions ? failed : null,
        reposts: event.kind == PostEngagementKind.reposts ? failed : null,
      ));
    }
  }

  Future<void> _onLoadMoreEngagementUsers(
    LoadMorePostEngagementUsersEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    final current = state;
    if (current is! PostManagementLoaded) return;

    final existing = current.engagementFor(event.kind);
    if (!existing.hasMore ||
        existing.isLoadingMore ||
        existing.isLoading ||
        !existing.loaded) {
      return;
    }

    emit(current.copyWith(
      likes: event.kind == PostEngagementKind.likes
          ? existing.copyWith(isLoadingMore: true, clearError: true)
          : null,
      views: event.kind == PostEngagementKind.views
          ? existing.copyWith(isLoadingMore: true, clearError: true)
          : null,
      mentions: event.kind == PostEngagementKind.mentions
          ? existing.copyWith(isLoadingMore: true, clearError: true)
          : null,
      reposts: event.kind == PostEngagementKind.reposts
          ? existing.copyWith(isLoadingMore: true, clearError: true)
          : null,
    ));

    try {
      final page = await getPostEngagementUsers(
        current.post.id,
        kind: event.kind,
        page: existing.page + 1,
        limit: _engagementLimit,
        postAuthorId: current.post.userId,
      );
      final loaded = (state as PostManagementLoaded);
      final prior = loaded.engagementFor(event.kind);
      final next = prior.copyWith(
        items: [...prior.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
      emit(loaded.copyWith(
        likes: event.kind == PostEngagementKind.likes ? next : null,
        views: event.kind == PostEngagementKind.views ? next : null,
        mentions: event.kind == PostEngagementKind.mentions ? next : null,
        reposts: event.kind == PostEngagementKind.reposts ? next : null,
      ));
    } catch (e) {
      final loaded = (state as PostManagementLoaded);
      final prior = loaded.engagementFor(event.kind);
      final failed =
          prior.copyWith(isLoadingMore: false, error: _messageFrom(e));
      emit(loaded.copyWith(
        likes: event.kind == PostEngagementKind.likes ? failed : null,
        views: event.kind == PostEngagementKind.views ? failed : null,
        mentions: event.kind == PostEngagementKind.mentions ? failed : null,
        reposts: event.kind == PostEngagementKind.reposts ? failed : null,
      ));
    }
  }

  String _messageFrom(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
