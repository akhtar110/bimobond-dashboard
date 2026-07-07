part of 'create_post_bloc.dart';

enum CreatePostStatus {
  initial,
  editing,
  uploadingMedia,
  mediaUploaded,
  creatingPost,
  success,
  error,
}

class CreatePostState {
  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.form = const CreatePostEntity(),
    this.step = 0,
    this.uploadProgress = 0,
    this.errorMessage,
    this.wasDraft = false,
    this.isGeneratingThumbnail = false,
    this.soundSearchResults = const [],
    this.soundsLoading = false,
    this.locationSearchResults = const [],
    this.locationsLoading = false,
    this.soundUploadProgress,
    this.mediaLimitReached = false,
  });

  final CreatePostStatus status;
  final CreatePostEntity form;
  final int step;
  final double uploadProgress;
  final String? errorMessage;
  final bool wasDraft;
  final bool isGeneratingThumbnail;
  final List<SoundEntity> soundSearchResults;
  final bool soundsLoading;
  final List<CreatePostLocationEntity> locationSearchResults;
  final bool locationsLoading;
  final double? soundUploadProgress;
  final bool mediaLimitReached;

  static const stepCount = 4;

  bool get isBusy =>
      status == CreatePostStatus.uploadingMedia ||
      status == CreatePostStatus.creatingPost ||
      isGeneratingThumbnail ||
      soundUploadProgress != null;

  bool get canPublish => form.canSubmit && !isBusy;

  bool get canSaveDraft => form.canSaveDraft && !isBusy;

  CreatePostState copyWith({
    CreatePostStatus? status,
    CreatePostEntity? form,
    int? step,
    double? uploadProgress,
    String? errorMessage,
    bool? wasDraft,
    bool? isGeneratingThumbnail,
    List<SoundEntity>? soundSearchResults,
    bool? soundsLoading,
    List<CreatePostLocationEntity>? locationSearchResults,
    bool? locationsLoading,
    double? soundUploadProgress,
    bool? mediaLimitReached,
    bool clearError = false,
    bool clearSoundUploadProgress = false,
  }) {
    return CreatePostState(
      status: status ?? this.status,
      form: form ?? this.form,
      step: step ?? this.step,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      wasDraft: wasDraft ?? this.wasDraft,
      isGeneratingThumbnail:
          isGeneratingThumbnail ?? this.isGeneratingThumbnail,
      soundSearchResults: soundSearchResults ?? this.soundSearchResults,
      soundsLoading: soundsLoading ?? this.soundsLoading,
      locationSearchResults:
          locationSearchResults ?? this.locationSearchResults,
      locationsLoading: locationsLoading ?? this.locationsLoading,
      soundUploadProgress: clearSoundUploadProgress
          ? null
          : (soundUploadProgress ?? this.soundUploadProgress),
      mediaLimitReached: mediaLimitReached ?? this.mediaLimitReached,
    );
  }
}
