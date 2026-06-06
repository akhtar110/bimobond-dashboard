import '../entities/create_post_entity.dart';
import '../entities/create_post_field.dart';

/// Applies [CreatePostField] updates — keeps presentation free of business rules.
class CreatePostFormReducer {
  const CreatePostFormReducer._();

  static CreatePostEntity apply(
    CreatePostEntity form,
    CreatePostField field,
    Object? value,
  ) {
    switch (field) {
      case CreatePostField.description:
        final text = value as String?;
        return form.copyWith(
          description: text,
          clearDescription: text == null || text.trim().isEmpty,
        );
      case CreatePostField.category:
        final slug = value as String?;
        return form.copyWith(
          category: slug,
          clearCategory: slug == null,
        );
      case CreatePostField.categoryId:
        final id = value as String?;
        // Clearing the UUID also clears the display name so both fields stay
        // in sync.  Setting a new UUID keeps the existing display name until
        // the next UpdateField(category, …) event sets it.
        return form.copyWith(
          categoryId: id,
          clearCategory: id == null,
        );
      case CreatePostField.type:
        return form.copyWith(type: value as String);
      case CreatePostField.privacyStatus:
        return form.copyWith(privacyStatus: value as String);
      case CreatePostField.allowComments:
        return form.copyWith(allowComments: value as bool);
      case CreatePostField.allowDuets:
        return form.copyWith(allowDuets: value as bool);
      case CreatePostField.allowStitch:
        return form.copyWith(allowStitch: value as bool);
      case CreatePostField.isStory:
        return form.copyWith(isStory: value as bool);
      case CreatePostField.isAd:
        return form.copyWith(isAd: value as bool);
      case CreatePostField.isAuctionable:
        final enabled = value as bool;
        return form.copyWith(
          isAuctionable: enabled,
          auction: enabled ? (form.auction ?? const CreatePostAuctionEntity()) : null,
          clearAuction: !enabled,
        );
      case CreatePostField.duration:
        return form.copyWith(duration: value as int?);
      case CreatePostField.videoWidth:
        return form.copyWith(videoWidth: value as int?);
      case CreatePostField.videoHeight:
        return form.copyWith(videoHeight: value as int?);
      case CreatePostField.locationId:
        final id = value as String?;
        return form.copyWith(
          locationId: id,
          clearLocationId: id == null,
        );
      case CreatePostField.playlistId:
        final id = value as String?;
        return form.copyWith(
          playlistId: id,
          clearPlaylistId: id == null,
        );
      case CreatePostField.soundId:
        final id = value as String?;
        return form.copyWith(
          soundId: id,
          clearSoundId: id == null,
        );
      case CreatePostField.originalPostId:
        final id = value as String?;
        return form.copyWith(
          originalPostId: id,
          clearOriginalPostId: id == null,
        );
      case CreatePostField.auctionItemName:
        return _updateAuction(form, (a) => a.copyWith(itemName: value as String));
      case CreatePostField.auctionItemImageUrl:
        return _updateAuction(
          form,
          (a) => a.copyWith(itemImageUrl: value as String),
        );
      case CreatePostField.auctionStartingPriceUsd:
        return _updateAuction(
          form,
          (a) => a.copyWith(startingPriceUsd: value as double?),
        );
      case CreatePostField.auctionTargetPriceUsd:
        return _updateAuction(
          form,
          (a) => a.copyWith(targetPriceUsd: value as double?),
        );
      case CreatePostField.auctionStartedAt:
        return _updateAuction(
          form,
          (a) => a.copyWith(startedAt: value as DateTime?),
        );
      case CreatePostField.auctionEndedAt:
        return _updateAuction(
          form,
          (a) => a.copyWith(endedAt: value as DateTime?),
        );
    }
  }

  static CreatePostEntity _updateAuction(
    CreatePostEntity form,
    CreatePostAuctionEntity Function(CreatePostAuctionEntity) update,
  ) {
    final current = form.auction ?? const CreatePostAuctionEntity();
    return form.copyWith(
      isAuctionable: true,
      auction: update(current),
    );
  }
}
