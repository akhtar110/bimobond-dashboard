import '../entities/create_post_auction_entity.dart';
import '../entities/create_post_entity.dart';
import '../entities/create_post_field.dart';
import '../entities/create_post_location_entity.dart';
import '../entities/create_post_new_sound_entity.dart';
import '../entities/create_post_sound_selection_entity.dart';

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
          auction: enabled
              ? (form.auction ?? const CreatePostAuctionEntity())
              : null,
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
          clearLocation: id != null,
        );
      case CreatePostField.location:
        final location = value as CreatePostLocationEntity?;
        return form.copyWith(
          location: location,
          clearLocation: location == null,
          clearLocationId: location != null,
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
          clearNewSound: id != null,
        );
      case CreatePostField.newSound:
        final sound = value as CreatePostNewSoundEntity?;
        return form.copyWith(
          newSound: sound,
          clearNewSound: sound == null,
          clearSoundId: sound != null,
        );
      case CreatePostField.selectedSound:
        final sound = value as CreatePostSoundSelectionEntity?;
        return form.copyWith(
          selectedSound: sound,
          clearSelectedSound: sound == null,
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
      case CreatePostField.auctionStartingPriceCoins:
        return _updateAuction(
          form,
          (a) => (value == null)
              ? a.copyWith(clearStartingPriceCoins: true)
              : a.copyWith(startingPriceCoins: value as double),
        );
      case CreatePostField.auctionTargetPriceCoins:
        return _updateAuction(
          form,
          (a) => (value == null)
              ? a.copyWith(clearTargetPriceCoins: true)
              : a.copyWith(targetPriceCoins: value as double),
        );
      case CreatePostField.auctionPricingMode:
        return _updateAuction(
          form,
          (a) {
            final mode = value as AuctionPricingMode;
            if (mode == AuctionPricingMode.money) {
              return a.copyWith(
                pricingMode: mode,
                clearStartingPriceCoins: true,
                clearTargetPriceCoins: true,
              );
            }
            return a.copyWith(
              pricingMode: mode,
              clearStartingPrice: true,
              clearTargetPrice: true,
            );
          },
        );
      case CreatePostField.auctionStartingPrice:
        return _updateAuction(
          form,
          (a) => (value == null)
              ? a.copyWith(clearStartingPrice: true)
              : a.copyWith(startingPrice: value as double),
        );
      case CreatePostField.auctionTargetPrice:
        return _updateAuction(
          form,
          (a) => (value == null)
              ? a.copyWith(clearTargetPrice: true)
              : a.copyWith(targetPrice: value as double),
        );
      case CreatePostField.auctionCurrencyCode:
        return _updateAuction(
          form,
          (a) => a.copyWith(currencyCode: value as String),
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
