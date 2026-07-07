import '../../domain/entities/create_post_entity.dart';

/// Validates create-post payload rules from the Posts API.
class CreatePostPayloadValidator {
  const CreatePostPayloadValidator._();

  static void validate(CreatePostEntity entity) {
    if (entity.soundId != null &&
        entity.soundId!.trim().isNotEmpty &&
        entity.newSound != null) {
      throw Exception('sound_conflict');
    }

    if (entity.locationId != null &&
        entity.locationId!.trim().isNotEmpty &&
        entity.location != null &&
        entity.location!.isComplete) {
      throw Exception('location_conflict');
    }
  }

  static bool resolvesLocationId(CreatePostEntity entity) {
    final id = entity.locationId?.trim();
    return id != null && id.isNotEmpty;
  }

  static CreatePostLocationEntity? resolvesInlineLocation(
    CreatePostEntity entity,
  ) {
    if (resolvesLocationId(entity)) return null;
    final location = entity.location;
    if (location != null && location.isComplete) return location;
    return null;
  }
}
