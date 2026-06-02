import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/usecases/ban_post_usecase.dart';
import '../../domain/usecases/delete_comment_admin.dart';
import '../../domain/usecases/delete_managed_post.dart';
import '../../domain/usecases/get_managed_post_by_id.dart';
import '../../domain/usecases/get_post_comments.dart';
import '../../domain/usecases/hide_post_usecase.dart';
import '../../domain/usecases/update_managed_post.dart';
import '../../domain/usecases/update_post_details_usecase.dart';
import '../../domain/usecases/update_post_status_usecase.dart';

sealed class PostManagementEvent {}

class LoadManagedPostEvent extends PostManagementEvent {
  LoadManagedPostEvent(this.post);
  final ManagedPostEntity post;
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
  UpdatePostStatusEvent(this.status);
  final String status;
}

class LoadPostCommentsEvent extends PostManagementEvent {}

class LoadMorePostCommentsEvent extends PostManagementEvent {}

class DeletePostCommentAdminEvent extends PostManagementEvent {
  DeletePostCommentAdminEvent(this.commentId);
  final String commentId;
}

sealed class PostManagementState {}

class PostManagementInitial extends PostManagementState {}

class PostManagementLoading extends PostManagementState {}

class PostManagementLoaded extends PostManagementState {
  PostManagementLoaded({
    required this.post,
    required this.draft,
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
  });

  final ManagedPostEntity post;
  final ManagedPostEntity draft;
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

  PostManagementLoaded copyWith({
    ManagedPostEntity? post,
    ManagedPostEntity? draft,
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
  }) {
    return PostManagementLoaded(
      post: post ?? this.post,
      draft: draft ?? this.draft,
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
    required this.updateManagedPost,
    required this.deleteManagedPost,
    required this.updatePostDetails,
    required this.hidePost,
    required this.banPost,
    required this.updatePostStatus,
    required this.getPostComments,
    required this.deleteCommentAdmin,
  }) : super(PostManagementInitial()) {
    on<LoadManagedPostEvent>(_onLoad);
    on<ChangeManagedPostFieldEvent>(_onChangeField);
    on<UpdateManagedPostEvent>(_onUpdate);
    on<DeleteManagedPostEvent>(_onDelete);
    on<UpdatePostDetailsEvent>(_onUpdateDetails);
    on<HidePostEvent>(_onHide);
    on<BanPostEvent>(_onBan);
    on<UpdatePostStatusEvent>(_onUpdateStatus);
    on<LoadPostCommentsEvent>(_onLoadComments);
    on<LoadMorePostCommentsEvent>(_onLoadMoreComments);
    on<DeletePostCommentAdminEvent>(_onDeleteComment);
  }

  static const int _commentsLimit = 20;

  final GetManagedPostById getManagedPostById;
  final UpdateManagedPost updateManagedPost;
  final DeleteManagedPost deleteManagedPost;
  final UpdatePostDetails updatePostDetails;
  final HidePost hidePost;
  final BanPost banPost;
  final UpdatePostStatus updatePostStatus;
  final GetPostComments getPostComments;
  final DeleteCommentAdmin deleteCommentAdmin;

  Future<void> _onLoad(
    LoadManagedPostEvent event,
    Emitter<PostManagementState> emit,
  ) async {
    emit(PostManagementLoading());

    try {
      final fresh = await getManagedPostById(event.post.id);
      emit(
        PostManagementLoaded(
          post: fresh,
          draft: fresh,
          isCommentsLoading: true,
        ),
      );
      add(LoadPostCommentsEvent());
    } catch (_) {
      emit(
        PostManagementLoaded(
          post: event.post,
          draft: event.post,
          isCommentsLoading: true,
        ),
      );
      add(LoadPostCommentsEvent());
    }
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
      final updated = await updateManagedPost(
        current.draft.id,
        ManagedPostUpdateData(
          description: current.draft.description,
          category: current.draft.category,
          privacyStatus: current.draft.privacyStatus,
          status: current.draft.status,
          allowComments: current.draft.allowComments,
          allowDuets: current.draft.allowDuets,
          allowStitch: current.draft.allowStitch,
        ),
      );

      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isSaving: false,
          successMessage: 'Post updated successfully',
        ),
      );
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
      final updated = await updatePostDetails(
        current.post.id,
        description: event.description,
        category: event.category,
      );
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
      final updated = await hidePost(current.post.id);
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
      final updated = await banPost(current.post.id);
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
      final updated = await updatePostStatus(current.post.id, event.status);
      emit(
        current.copyWith(
          post: updated,
          draft: updated,
          isActioning: false,
          successMessage: 'Status changed to ${event.status}',
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
      final page = await getPostComments(
        current.post.id,
        page: 1,
        limit: _commentsLimit,
      );
      emit(
        (state as PostManagementLoaded).copyWith(
          comments: page.comments,
          commentsPage: page.page,
          commentsHasMore: page.hasMore,
          isCommentsLoading: false,
        ),
      );
    } catch (e) {
      emit(
        (state as PostManagementLoaded).copyWith(
          isCommentsLoading: false,
          commentsError: _messageFrom(e),
        ),
      );
    }
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

  String _messageFrom(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
