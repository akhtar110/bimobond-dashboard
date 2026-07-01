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
  });

  final CreatePostStatus status;
  final CreatePostEntity form;
  final int step;
  final double uploadProgress;
  final String? errorMessage;
  final bool wasDraft;
  final bool isGeneratingThumbnail;

  static const stepCount = 4;

  bool get isBusy =>
      status == CreatePostStatus.uploadingMedia ||
      status == CreatePostStatus.creatingPost ||
      isGeneratingThumbnail;

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
    bool clearError = false,
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
    );
  }
}
