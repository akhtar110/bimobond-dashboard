import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import '../../domain/services/create_post_error_mapper.dart';
import '../../domain/services/create_post_form_reducer.dart';
import '../../domain/services/create_post_media_upload_service.dart';
import '../../domain/services/create_post_thumbnail_service.dart';
import '../../domain/usecases/submit_create_post_usecase.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc({
    required CreatePostMediaUploadService uploadService,
    required CreatePostThumbnailService thumbnailService,
    required SubmitCreatePost submitCreatePost,
  })  : _uploadService = uploadService,
        _thumbnailService = thumbnailService,
        _submitCreatePost = submitCreatePost,
        super(const CreatePostState()) {
    on<CreatePostStarted>(_onStarted);
    on<CreatePostStepChanged>(_onStepChanged);
    on<PickMedia>(_onPickMedia);
    on<RemoveMedia>(_onRemoveMedia);
    on<ReorderMedia>(_onReorderMedia);
    on<UploadMedia>(_onUploadMedia);
    on<UpdateField>(_onUpdateField);
    on<CreatePostSubmitted>(_onCreatePost);
    on<SaveDraft>(_onSaveDraft);
  }

  final CreatePostMediaUploadService _uploadService;
  final CreatePostThumbnailService _thumbnailService;
  final SubmitCreatePost _submitCreatePost;

  void _onStarted(CreatePostStarted event, Emitter<CreatePostState> emit) {
    emit(
      state.copyWith(
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  void _onStepChanged(
    CreatePostStepChanged event,
    Emitter<CreatePostState> emit,
  ) {
    final step = event.step.clamp(0, CreatePostState.stepCount - 1);
    if (step > 0 && !state.form.hasLocalMedia) {
      emit(state.copyWith(errorMessage: 'media_required'));
      return;
    }
    emit(state.copyWith(step: step, clearError: true));
  }

  Future<void> _onPickMedia(PickMedia event, Emitter<CreatePostState> emit) async {
    if (event.files.isEmpty) return;

    final merged = [...state.form.localMedia, ...event.files];
    final limited = merged.length > 10 ? merged.sublist(0, 10) : merged;
    emit(
      state.copyWith(
        form: state.form.copyWith(localMedia: limited),
        status: CreatePostStatus.editing,
        uploadProgress: 0,
        clearError: true,
        isGeneratingThumbnail: false,
      ),
    );

    await _refreshThumbnail(emit);
  }

  Future<void> _onRemoveMedia(RemoveMedia event, Emitter<CreatePostState> emit) async {
    final next = state.form.localMedia
        .where((f) => f.id != event.id)
        .toList(growable: false);
    emit(
      state.copyWith(
        form: state.form.copyWith(
          localMedia: next,
          clearThumbnailBytes: true,
          clearThumbnailUrl: true,
        ),
        status: CreatePostStatus.editing,
        clearError: true,
        isGeneratingThumbnail: false,
      ),
    );

    await _refreshThumbnail(emit);
  }

  Future<void> _refreshThumbnail(Emitter<CreatePostState> emit) async {
    if (!state.form.hasVideoMedia) return;

    emit(state.copyWith(isGeneratingThumbnail: true, clearError: true));

    try {
      final updated = await _thumbnailService.generateIfNeeded(state.form);
      emit(
        state.copyWith(
          form: updated,
          isGeneratingThumbnail: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isGeneratingThumbnail: false));
    }
  }

  Future<void> _onReorderMedia(
    ReorderMedia event,
    Emitter<CreatePostState> emit,
  ) async {
    final items = List<LocalMediaFile>.from(state.form.localMedia);
    if (event.oldIndex < 0 ||
        event.oldIndex >= items.length ||
        event.newIndex < 0 ||
        event.newIndex >= items.length) {
      return;
    }
    final item = items.removeAt(event.oldIndex);
    items.insert(event.newIndex, item);
    emit(
      state.copyWith(
        form: state.form.copyWith(
          localMedia: items,
          clearThumbnailBytes: true,
          clearThumbnailUrl: true,
        ),
        status: CreatePostStatus.editing,
      ),
    );

    await _refreshThumbnail(emit);
  }

  void _onUpdateField(UpdateField event, Emitter<CreatePostState> emit) {
    emit(
      state.copyWith(
        form: CreatePostFormReducer.apply(
          state.form,
          event.field,
          event.value,
        ),
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  Future<void> _onUploadMedia(
    UploadMedia event,
    Emitter<CreatePostState> emit,
  ) async {
    if (!state.form.hasLocalMedia) return;

    emit(
      state.copyWith(
        status: CreatePostStatus.uploadingMedia,
        uploadProgress: 0,
        clearError: true,
      ),
    );

    try {
      final updated = await _uploadService.uploadPending(
        state.form,
        onFileProgress: (done, total) {
          emit(
            state.copyWith(
              status: CreatePostStatus.uploadingMedia,
              uploadProgress: done / total,
            ),
          );
        },
      );
      emit(
        state.copyWith(
          status: CreatePostStatus.mediaUploaded,
          form: updated,
          uploadProgress: 1,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CreatePostStatus.editing,
          uploadProgress: 0,
          errorMessage: CreatePostErrorMapper.map(e),
        ),
      );
    }
  }

  Future<void> _onCreatePost(
    CreatePostSubmitted event,
    Emitter<CreatePostState> emit,
  ) {
    return _submit(emit, publish: true);
  }

  Future<void> _onSaveDraft(
    SaveDraft event,
    Emitter<CreatePostState> emit,
  ) {
    return _submit(emit, publish: false);
  }

  Future<void> _submit(
    Emitter<CreatePostState> emit, {
    required bool publish,
  }) async {
    if (!state.form.hasLocalMedia) {
      emit(state.copyWith(errorMessage: 'media_required'));
      return;
    }

    if (publish) {
      if (!state.form.hasDescription) {
        emit(state.copyWith(errorMessage: 'description_required'));
        return;
      }
      if (state.form.isAuctionable &&
          !(state.form.auction?.isComplete ?? false)) {
        emit(state.copyWith(errorMessage: 'auction_incomplete'));
        return;
      }
    }

    emit(
      state.copyWith(
        status: CreatePostStatus.uploadingMedia,
        uploadProgress: 0,
        form: publish ? state.form : state.form.copyWith(status: 'DRAFT'),
        clearError: true,
      ),
    );

    try {
      final payload = await _submitCreatePost(
        form: state.form,
        publish: publish,
        onUploadProgress: (p) {
          emit(
            state.copyWith(
              status: CreatePostStatus.uploadingMedia,
              uploadProgress: p,
            ),
          );
        },
        onCreatingPost: () {
          emit(
            state.copyWith(
              status: CreatePostStatus.creatingPost,
              uploadProgress: 1,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: CreatePostStatus.success,
          form: payload,
          wasDraft: !publish,
          uploadProgress: 1,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CreatePostStatus.editing,
          uploadProgress: 0,
          errorMessage: CreatePostErrorMapper.map(e),
        ),
      );
    }
  }
}
