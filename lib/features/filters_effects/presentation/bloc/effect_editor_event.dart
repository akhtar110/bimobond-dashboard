import 'package:equatable/equatable.dart';

abstract class EffectEditorEvent extends Equatable {
  const EffectEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadEffectEditorEvent extends EffectEditorEvent {
  const LoadEffectEditorEvent({this.effectId});

  final String? effectId;

  @override
  List<Object?> get props => [effectId];
}

class EffectBasicFieldChanged extends EffectEditorEvent {
  const EffectBasicFieldChanged({
    this.slug,
    this.effectType,
    this.emoji,
    this.assetUrl,
    this.labelKey,
    this.requiresFaceDetection,
    this.isScreenEffect,
    this.isActive,
    this.sortOrder,
    this.clearEmoji = false,
    this.clearAssetUrl = false,
  });

  final String? slug;
  final String? effectType;
  final String? emoji;
  final String? assetUrl;
  final String? labelKey;
  final bool? requiresFaceDetection;
  final bool? isScreenEffect;
  final bool? isActive;
  final int? sortOrder;
  final bool clearEmoji;
  final bool clearAssetUrl;

  @override
  List<Object?> get props => [
        slug,
        effectType,
        emoji,
        assetUrl,
        labelKey,
        requiresFaceDetection,
        isScreenEffect,
        isActive,
        sortOrder,
        clearEmoji,
        clearAssetUrl,
      ];
}

class UploadEffectAssetEvent extends EffectEditorEvent {
  const UploadEffectAssetEvent({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}

class EffectPreviewColorChanged extends EffectEditorEvent {
  const EffectPreviewColorChanged(this.hex);

  final String? hex;

  @override
  List<Object?> get props => [hex];
}

class EffectAnchorTypeChanged extends EffectEditorEvent {
  const EffectAnchorTypeChanged(this.anchorType);

  final String? anchorType;

  @override
  List<Object?> get props => [anchorType];
}

class EffectLandmarksChanged extends EffectEditorEvent {
  const EffectLandmarksChanged(this.landmarks);

  final List<String> landmarks;

  @override
  List<Object?> get props => [landmarks];
}

class EffectPlacementNumericChanged extends EffectEditorEvent {
  const EffectPlacementNumericChanged({
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.fallbackOffsetY,
    this.fallbackScaleFactor,
    this.clearScaleFactor = false,
    this.clearOffsetX = false,
    this.clearOffsetY = false,
    this.clearLandmarkSize = false,
    this.clearFallbackOffsetY = false,
    this.clearFallbackScaleFactor = false,
  });

  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final double? fallbackOffsetY;
  final double? fallbackScaleFactor;
  final bool clearScaleFactor;
  final bool clearOffsetX;
  final bool clearOffsetY;
  final bool clearLandmarkSize;
  final bool clearFallbackOffsetY;
  final bool clearFallbackScaleFactor;

  @override
  List<Object?> get props => [
        scaleFactor,
        offsetX,
        offsetY,
        landmarkSize,
        fallbackOffsetY,
        fallbackScaleFactor,
        clearScaleFactor,
        clearOffsetX,
        clearOffsetY,
        clearLandmarkSize,
        clearFallbackOffsetY,
        clearFallbackScaleFactor,
      ];
}

class EffectFallbackAnchorTypeChanged extends EffectEditorEvent {
  const EffectFallbackAnchorTypeChanged(this.anchorType);

  final String? anchorType;

  @override
  List<Object?> get props => [anchorType];
}

class ApplyPlacementDefaultsEvent extends EffectEditorEvent {
  const ApplyPlacementDefaultsEvent();
}

class ResetPlacementEvent extends EffectEditorEvent {
  const ResetPlacementEvent();
}

class ResetEffectEditorEvent extends EffectEditorEvent {
  const ResetEffectEditorEvent();
}

class EffectPlacementExpansionToggled extends EffectEditorEvent {
  const EffectPlacementExpansionToggled();
}

class SubmitEffectEditorEvent extends EffectEditorEvent {
  const SubmitEffectEditorEvent();
}

class ClearEffectEditorSaveFlagEvent extends EffectEditorEvent {
  const ClearEffectEditorSaveFlagEvent();
}

class ClearEffectEditorSubmitErrorEvent extends EffectEditorEvent {
  const ClearEffectEditorSubmitErrorEvent();
}
