part of 'create_post_bloc.dart';

sealed class CreatePostEvent {}

class CreatePostStarted extends CreatePostEvent {}

class CreatePostStepChanged extends CreatePostEvent {
  CreatePostStepChanged(this.step);
  final int step;
}

/// Attach local files (step 1 — no upload yet).
class PickMedia extends CreatePostEvent {
  PickMedia(this.files);
  final List<LocalMediaFile> files;
}

class RemoveMedia extends CreatePostEvent {
  RemoveMedia(this.id);
  final String id;
}

class ReorderMedia extends CreatePostEvent {
  ReorderMedia(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}

/// `POST /posts/upload` for pending local files.
class UploadMedia extends CreatePostEvent {}

/// Partial form update from UI sections.
class UpdateField extends CreatePostEvent {
  UpdateField(this.field, this.value);
  final CreatePostField field;
  final Object? value;
}

/// `POST /posts` with status PUBLISHED (uploads media first if needed).
class CreatePostSubmitted extends CreatePostEvent {}

/// `POST /posts` with status DRAFT.
class SaveDraft extends CreatePostEvent {}
