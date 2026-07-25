import 'package:equatable/equatable.dart';

abstract class FilterEditorEvent extends Equatable {
  const FilterEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadFilterEditorEvent extends FilterEditorEvent {
  const LoadFilterEditorEvent({this.filterId});

  final String? filterId;

  @override
  List<Object?> get props => [filterId];
}

class FilterBasicFieldChanged extends FilterEditorEvent {
  const FilterBasicFieldChanged({
    this.slug,
    this.label,
    this.customLabel,
    this.renderType,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.lutUrl,
    this.lutAsset,
    this.isActive,
    this.sortOrder,
    this.clearCustomLabel = false,
    this.clearLabelKey = false,
    this.clearEmoji = false,
    this.clearThumbnailUrl = false,
    this.clearPreviewColorHex = false,
    this.clearLutUrl = false,
    this.clearLutAsset = false,
  });

  final String? slug;
  final String? label;
  final String? customLabel;
  final String? renderType;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? lutUrl;
  final String? lutAsset;
  final bool? isActive;
  final int? sortOrder;
  final bool clearCustomLabel;
  final bool clearLabelKey;
  final bool clearEmoji;
  final bool clearThumbnailUrl;
  final bool clearPreviewColorHex;
  final bool clearLutUrl;
  final bool clearLutAsset;

  @override
  List<Object?> get props => [
    slug,
    label,
    customLabel,
    renderType,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    lutUrl,
    lutAsset,
    isActive,
    sortOrder,
    clearCustomLabel,
    clearLabelKey,
    clearEmoji,
    clearThumbnailUrl,
    clearPreviewColorHex,
    clearLutUrl,
    clearLutAsset,
  ];
}

class FilterPreviewColorChanged extends FilterEditorEvent {
  const FilterPreviewColorChanged(this.hex);

  final String? hex;

  @override
  List<Object?> get props => [hex];
}

class FilterSettingChanged extends FilterEditorEvent {
  const FilterSettingChanged({
    this.smooth,
    this.whiten,
    this.brighten,
    this.blush,
    this.lipStrength,
    this.lipTint,
    this.defaultIntensity,
    this.brightness,
    this.contrast,
    this.saturation,
    this.warmth,
    this.clearLipTint = false,
  });

  final int? smooth;
  final int? whiten;
  final int? brighten;
  final int? blush;
  final int? lipStrength;
  final String? lipTint;
  final int? defaultIntensity;
  final int? brightness;
  final int? contrast;
  final int? saturation;
  final int? warmth;
  final bool clearLipTint;

  @override
  List<Object?> get props => [
    smooth,
    whiten,
    brighten,
    blush,
    lipStrength,
    lipTint,
    defaultIntensity,
    brightness,
    contrast,
    saturation,
    warmth,
    clearLipTint,
  ];
}

class FilterAdjustmentChanged extends FilterEditorEvent {
  const FilterAdjustmentChanged(this.key, this.value);

  final String key;
  final int value;

  @override
  List<Object?> get props => [key, value];
}

class ResetFilterEditorEvent extends FilterEditorEvent {
  const ResetFilterEditorEvent();
}

class SubmitFilterEditorEvent extends FilterEditorEvent {
  const SubmitFilterEditorEvent();
}

class UploadFilterThumbnailEvent extends FilterEditorEvent {
  const UploadFilterThumbnailEvent({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}

class UploadFilterLutEvent extends FilterEditorEvent {
  const UploadFilterLutEvent({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;

  @override
  List<Object?> get props => [bytes, filename];
}

class ClearFilterEditorSaveFlagEvent extends FilterEditorEvent {
  const ClearFilterEditorSaveFlagEvent();
}

class ClearFilterEditorSubmitErrorEvent extends FilterEditorEvent {
  const ClearFilterEditorSubmitErrorEvent();
}
