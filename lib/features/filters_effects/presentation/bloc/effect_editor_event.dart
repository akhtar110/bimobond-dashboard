import 'package:equatable/equatable.dart';

import '../../domain/entities/filters_effects_entities.dart';
import '../utils/effect_anchor_form_data.dart';

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
    this.renderType,
    this.label,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.assetUrl,
    this.assetAsset,
    this.distortionPreset,
    this.isActive,
    this.sortOrder,
    this.clearLabelKey = false,
    this.clearEmoji = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
    this.clearAssetUrl = false,
    this.clearAssetAsset = false,
    this.clearDistortionPreset = false,
  });

  final String? slug;
  final String? renderType;
  final String? label;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? assetUrl;
  final String? assetAsset;
  final String? distortionPreset;
  final bool? isActive;
  final int? sortOrder;
  final bool clearLabelKey;
  final bool clearEmoji;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;
  final bool clearAssetUrl;
  final bool clearAssetAsset;
  final bool clearDistortionPreset;

  @override
  List<Object?> get props => [
    slug,
    renderType,
    label,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    assetUrl,
    assetAsset,
    distortionPreset,
    isActive,
    sortOrder,
    clearLabelKey,
    clearEmoji,
    clearThumbnailUrl,
    clearPreviewColorHex,
    clearAssetUrl,
    clearAssetAsset,
    clearDistortionPreset,
  ];
}

class EffectAnchorChanged extends EffectEditorEvent {
  const EffectAnchorChanged(this.anchor);

  final EffectAnchorFormData anchor;

  @override
  List<Object?> get props => [anchor];
}

class EffectStickersChanged extends EffectEditorEvent {
  const EffectStickersChanged(this.stickers);

  final List<CameraEffectStickerLayer> stickers;

  @override
  List<Object?> get props => [stickers];
}

class UploadEffectAssetEvent extends EffectEditorEvent {
  const UploadEffectAssetEvent({required this.bytes, required this.filename});

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

class ResetEffectEditorEvent extends EffectEditorEvent {
  const ResetEffectEditorEvent();
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
