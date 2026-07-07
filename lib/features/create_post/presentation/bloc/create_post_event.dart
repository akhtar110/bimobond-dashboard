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

class SelectSound extends CreatePostEvent {
  SelectSound(this.sound);
  final SoundEntity sound;
}

class ClearSound extends CreatePostEvent {}

class UploadOriginalSound extends CreatePostEvent {
  UploadOriginalSound({
    required this.bytes,
    required this.filename,
    required this.name,
    required this.duration,
  });

  final List<int> bytes;
  final String filename;
  final String name;
  final int duration;
}

class SetLocation extends CreatePostEvent {
  SetLocation(this.location);
  final CreatePostLocationEntity location;
}

class ClearLocation extends CreatePostEvent {}

class SearchSounds extends CreatePostEvent {
  SearchSounds({this.query, this.trending = false});

  final String? query;
  final bool trending;
}

class SearchLocations extends CreatePostEvent {
  SearchLocations(this.query);
  final String query;
}

class ApplyMediaFilter extends CreatePostEvent {
  ApplyMediaFilter({required this.mediaId, required this.filter});

  final String mediaId;
  final CreatePostMediaFilterEntity filter;
}

class ResetMediaFilter extends CreatePostEvent {
  ResetMediaFilter(this.mediaId);
  final String mediaId;
}

/// `POST /posts` with status PUBLISHED (uploads media first if needed).
class CreatePostSubmitted extends CreatePostEvent {}

/// `POST /posts` with status DRAFT.
class SaveDraft extends CreatePostEvent {}
