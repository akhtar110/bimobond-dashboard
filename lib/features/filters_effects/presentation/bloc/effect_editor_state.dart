import 'package:equatable/equatable.dart';

import '../../domain/entities/filters_effects_entities.dart';
import '../utils/effect_anchor_form_data.dart';

class EffectEditorFormData extends Equatable {
  const EffectEditorFormData({
    required this.slug,
    required this.renderType,
    required this.label,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.assetUrl,
    this.assetAsset,
    this.anchor = EffectAnchorFormData.empty,
    this.stickers = const [],
    this.distortionPreset,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String slug;
  final String renderType;
  final String label;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final String? assetUrl;
  final String? assetAsset;
  final EffectAnchorFormData anchor;
  final List<CameraEffectStickerLayer> stickers;
  final String? distortionPreset;
  final bool isActive;
  final int sortOrder;

  String get displayLabel {
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    final s = slug.trim();
    return s.isNotEmpty ? s : '—';
  }

  EffectEditorFormData copyWith({
    String? slug,
    String? renderType,
    String? label,
    String? labelKey,
    String? emoji,
    String? thumbnailUrl,
    String? previewColorHex,
    String? assetUrl,
    String? assetAsset,
    EffectAnchorFormData? anchor,
    List<CameraEffectStickerLayer>? stickers,
    String? distortionPreset,
    bool? isActive,
    int? sortOrder,
    bool clearLabelKey = false,
    bool clearEmoji = false,
    bool clearThumbnailUrl = false,
    bool clearPreviewColorHex = false,
    bool clearAssetUrl = false,
    bool clearAssetAsset = false,
    bool clearDistortionPreset = false,
  }) {
    return EffectEditorFormData(
      slug: slug ?? this.slug,
      renderType: renderType ?? this.renderType,
      label: label ?? this.label,
      labelKey: clearLabelKey ? null : (labelKey ?? this.labelKey),
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      thumbnailUrl: clearThumbnailUrl
          ? null
          : (thumbnailUrl ?? this.thumbnailUrl),
      previewColorHex: clearPreviewColorHex
          ? null
          : (previewColorHex ?? this.previewColorHex),
      assetUrl: clearAssetUrl ? null : (assetUrl ?? this.assetUrl),
      assetAsset: clearAssetAsset ? null : (assetAsset ?? this.assetAsset),
      anchor: anchor ?? this.anchor,
      stickers: stickers ?? this.stickers,
      distortionPreset: clearDistortionPreset
          ? null
          : (distortionPreset ?? this.distortionPreset),
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

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
    anchor,
    stickers,
    distortionPreset,
    isActive,
    sortOrder,
  ];
}

abstract class EffectEditorState extends Equatable {
  const EffectEditorState();

  @override
  List<Object?> get props => [];
}

class EffectEditorInitial extends EffectEditorState {
  const EffectEditorInitial();
}

class EffectEditorLoading extends EffectEditorState {
  const EffectEditorLoading();
}

class EffectEditorReady extends EffectEditorState {
  const EffectEditorReady({
    required this.form,
    required this.baseline,
    this.effectId,
    this.fieldErrors = const {},
    this.isSaving = false,
    this.isUploadingAsset = false,
    this.assetFileName,
    this.saveSucceeded = false,
    this.submitError,
  });

  final String? effectId;
  final EffectEditorFormData form;
  final EffectEditorFormData baseline;
  final Map<String, String> fieldErrors;
  final bool isSaving;
  final bool isUploadingAsset;
  final String? assetFileName;
  final bool saveSucceeded;
  final String? submitError;

  bool get isEditing => effectId != null;

  bool get hasUnsavedChanges => form != baseline;

  EffectEditorReady copyWith({
    EffectEditorFormData? form,
    EffectEditorFormData? baseline,
    String? effectId,
    Map<String, String>? fieldErrors,
    bool? isSaving,
    bool? isUploadingAsset,
    String? assetFileName,
    bool? saveSucceeded,
    String? submitError,
    bool clearFieldErrors = false,
    bool clearSubmitError = false,
    bool clearAssetFileName = false,
  }) {
    return EffectEditorReady(
      effectId: effectId ?? this.effectId,
      form: form ?? this.form,
      baseline: baseline ?? this.baseline,
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      isSaving: isSaving ?? this.isSaving,
      isUploadingAsset: isUploadingAsset ?? this.isUploadingAsset,
      assetFileName: clearAssetFileName
          ? null
          : (assetFileName ?? this.assetFileName),
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
    effectId,
    form,
    baseline,
    fieldErrors,
    isSaving,
    isUploadingAsset,
    assetFileName,
    saveSucceeded,
    submitError,
  ];
}

class EffectEditorError extends EffectEditorState {
  const EffectEditorError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
