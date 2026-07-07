import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../sound_management/domain/entities/sound_entities.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import '../../domain/entities/create_post_location_entity.dart';
import '../../domain/entities/create_post_media_filter_entity.dart';
import '../../domain/entities/create_post_new_sound_entity.dart';
import '../../domain/entities/create_post_sound_selection_entity.dart';
import '../../domain/services/create_post_error_mapper.dart';
import '../../domain/services/create_post_form_reducer.dart';
import '../../domain/services/create_post_media_filter_service.dart';
import '../../domain/services/create_post_media_upload_service.dart';
import '../../domain/services/create_post_payload_validator.dart';
import '../../domain/services/create_post_thumbnail_service.dart';
import '../../domain/usecases/create_post_auxiliary_usecases.dart';
import '../../domain/usecases/submit_create_post_usecase.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc({
    required CreatePostMediaUploadService uploadService,
    required CreatePostThumbnailService thumbnailService,
    required SubmitCreatePost submitCreatePost,
    required CreatePostMediaFilterService mediaFilterService,
    required SearchCreatePostSounds searchSounds,
    required GetTrendingCreatePostSounds getTrendingSounds,
    required UploadCreatePostSound uploadSound,
    required SearchCreatePostLocations searchLocations,
  })  : _uploadService = uploadService,
        _thumbnailService = thumbnailService,
        _submitCreatePost = submitCreatePost,
        _mediaFilterService = mediaFilterService,
        _searchSounds = searchSounds,
        _getTrendingSounds = getTrendingSounds,
        _uploadSound = uploadSound,
        _searchLocations = searchLocations,
        super(const CreatePostState()) {
    on<CreatePostStarted>(_onStarted);
    on<CreatePostStepChanged>(_onStepChanged);
    on<PickMedia>(_onPickMedia);
    on<RemoveMedia>(_onRemoveMedia);
    on<ReorderMedia>(_onReorderMedia);
    on<UploadMedia>(_onUploadMedia);
    on<UpdateField>(_onUpdateField);
    on<SelectSound>(_onSelectSound);
    on<ClearSound>(_onClearSound);
    on<UploadOriginalSound>(_onUploadOriginalSound);
    on<SetLocation>(_onSetLocation);
    on<ClearLocation>(_onClearLocation);
    on<SearchSounds>(_onSearchSounds);
    on<SearchLocations>(_onSearchLocations);
    on<ApplyMediaFilter>(_onApplyMediaFilter);
    on<ResetMediaFilter>(_onResetMediaFilter);
    on<CreatePostSubmitted>(_onCreatePost);
    on<SaveDraft>(_onSaveDraft);
  }

  final CreatePostMediaUploadService _uploadService;
  final CreatePostThumbnailService _thumbnailService;
  final SubmitCreatePost _submitCreatePost;
  final CreatePostMediaFilterService _mediaFilterService;
  final SearchCreatePostSounds _searchSounds;
  final GetTrendingCreatePostSounds _getTrendingSounds;
  final UploadCreatePostSound _uploadSound;
  final SearchCreatePostLocations _searchLocations;

  void _onStarted(CreatePostStarted event, Emitter<CreatePostState> emit) {
    emit(
      state.copyWith(
        status: CreatePostStatus.editing,
        clearError: true,
        mediaLimitReached: false,
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
    final limitReached = merged.length > 10;
    final limited = limitReached ? merged.sublist(0, 10) : merged;

    emit(
      state.copyWith(
        form: state.form.copyWith(localMedia: limited),
        status: CreatePostStatus.editing,
        uploadProgress: 0,
        errorMessage: limitReached ? 'media_limit_reached' : null,
        clearError: !limitReached,
        mediaLimitReached: limitReached,
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
        mediaLimitReached: false,
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

  void _onSelectSound(SelectSound event, Emitter<CreatePostState> emit) {
    final sound = event.sound;
    var form = CreatePostFormReducer.apply(
      state.form,
      CreatePostField.soundId,
      sound.id,
    );
    form = CreatePostFormReducer.apply(
      form,
      CreatePostField.selectedSound,
      CreatePostSoundSelectionEntity(
        id: sound.id,
        name: sound.name,
        author: sound.author,
        audioUrl: sound.audioUrl,
        duration: sound.duration,
        coverUrl: sound.coverUrl,
      ),
    );
    emit(
      state.copyWith(
        form: form,
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  void _onClearSound(ClearSound event, Emitter<CreatePostState> emit) {
    var form = state.form.copyWith(
      clearSoundId: true,
      clearNewSound: true,
      clearSelectedSound: true,
    );
    emit(
      state.copyWith(
        form: form,
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  Future<void> _onUploadOriginalSound(
    UploadOriginalSound event,
    Emitter<CreatePostState> emit,
  ) async {
    emit(
      state.copyWith(
        soundUploadProgress: 0,
        clearError: true,
      ),
    );

    try {
      emit(state.copyWith(soundUploadProgress: 0.3));
      final uploaded = await _uploadSound(
        bytes: event.bytes,
        filename: event.filename,
        name: event.name,
        duration: event.duration,
      );
      emit(state.copyWith(soundUploadProgress: 0.8));

      var form = CreatePostFormReducer.apply(
        state.form,
        CreatePostField.newSound,
        CreatePostNewSoundEntity(
          audioUrl: uploaded.audioUrl,
          duration: uploaded.duration,
          name: uploaded.name,
          coverUrl: uploaded.coverUrl,
        ),
      );
      form = CreatePostFormReducer.apply(
        form,
        CreatePostField.selectedSound,
        CreatePostSoundSelectionEntity(
          id: uploaded.id,
          name: uploaded.name,
          author: uploaded.author,
          audioUrl: uploaded.audioUrl,
          duration: uploaded.duration,
          coverUrl: uploaded.coverUrl,
        ),
      );

      emit(
        state.copyWith(
          form: form,
          status: CreatePostStatus.editing,
          clearSoundUploadProgress: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          clearSoundUploadProgress: true,
          errorMessage: CreatePostErrorMapper.map(e),
        ),
      );
    }
  }

  void _onSetLocation(SetLocation event, Emitter<CreatePostState> emit) {
    final location = event.location;
    var form = state.form;
    if (location.id != null && location.id!.trim().isNotEmpty) {
      form = CreatePostFormReducer.apply(
        form,
        CreatePostField.locationId,
        location.id,
      );
    } else {
      form = CreatePostFormReducer.apply(
        form,
        CreatePostField.location,
        location,
      );
    }
    emit(
      state.copyWith(
        form: form,
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  void _onClearLocation(ClearLocation event, Emitter<CreatePostState> emit) {
    emit(
      state.copyWith(
        form: state.form.copyWith(
          clearLocationId: true,
          clearLocation: true,
        ),
        status: CreatePostStatus.editing,
        clearError: true,
      ),
    );
  }

  Future<void> _onSearchSounds(
    SearchSounds event,
    Emitter<CreatePostState> emit,
  ) async {
    emit(state.copyWith(soundsLoading: true, clearError: true));

    try {
      final results = event.trending
          ? await _getTrendingSounds()
          : await _searchSounds(
              page: 1,
              limit: 20,
              search: event.query,
            );
      emit(
        state.copyWith(
          soundSearchResults: results,
          soundsLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          soundSearchResults: const [],
          soundsLoading: false,
          errorMessage: CreatePostErrorMapper.map(e),
        ),
      );
    }
  }

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<CreatePostState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          locationSearchResults: const [],
          locationsLoading: false,
        ),
      );
      return;
    }

    emit(state.copyWith(locationsLoading: true, clearError: true));

    try {
      final results = await _searchLocations(
        query: query,
        page: 1,
        limit: 20,
      );
      emit(
        state.copyWith(
          locationSearchResults: results,
          locationsLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          locationSearchResults: const [],
          locationsLoading: false,
          errorMessage: CreatePostErrorMapper.map(e),
        ),
      );
    }
  }

  Future<void> _onApplyMediaFilter(
    ApplyMediaFilter event,
    Emitter<CreatePostState> emit,
  ) async {
    final index =
        state.form.localMedia.indexWhere((f) => f.id == event.mediaId);
    if (index < 0) return;

    final file = state.form.localMedia[index];
    if (file.mediaType != 'IMAGE') {
      final updated = file.copyWith(filter: event.filter);
      final media = List<LocalMediaFile>.from(state.form.localMedia)
        ..[index] = updated;
      emit(
        state.copyWith(
          form: state.form.copyWith(localMedia: media),
          status: CreatePostStatus.editing,
        ),
      );
      return;
    }

    try {
      final originalBytes = file.originalBytes ?? file.bytes;
      final filteredBytes = await _mediaFilterService.applyToImageBytes(
        originalBytes,
        event.filter,
      );
      final updated = file.copyWith(
        bytes: filteredBytes,
        filter: event.filter,
        originalBytes: originalBytes,
      );
      final media = List<LocalMediaFile>.from(state.form.localMedia)
        ..[index] = updated;
      emit(
        state.copyWith(
          form: state.form.copyWith(localMedia: media),
          status: CreatePostStatus.editing,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: CreatePostErrorMapper.map(e)));
    }
  }

  void _onResetMediaFilter(
    ResetMediaFilter event,
    Emitter<CreatePostState> emit,
  ) {
    final index =
        state.form.localMedia.indexWhere((f) => f.id == event.mediaId);
    if (index < 0) return;

    final file = state.form.localMedia[index];
    final updated = file.copyWith(resetFilter: true);
    final media = List<LocalMediaFile>.from(state.form.localMedia)
      ..[index] = updated;
    emit(
      state.copyWith(
        form: state.form.copyWith(localMedia: media),
        status: CreatePostStatus.editing,
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

    try {
      CreatePostPayloadValidator.validate(state.form);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(errorMessage: message));
      return;
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
