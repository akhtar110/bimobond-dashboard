import 'package:equatable/equatable.dart';

import '../../domain/entities/effect_placement_entities.dart';
class EffectEditorFormData extends Equatable {
  const EffectEditorFormData({
    required this.slug,
    required this.effectType,
    this.emoji,
    this.assetUrl,
    this.previewColorHex,
    required this.labelKey,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.placement = EffectPlacementSettingsEntity.empty,
  });

  final String slug;
  final String effectType;
  final String? emoji;
  final String? assetUrl;
  final String? previewColorHex;
  final String labelKey;
  final bool requiresFaceDetection;
  final bool isScreenEffect;
  final bool isActive;
  final int sortOrder;
  final EffectPlacementSettingsEntity placement;

  String get displayLabel {
    final key = labelKey.trim();
    if (key.isNotEmpty) return key;
    final s = slug.trim();
    return s.isNotEmpty ? s : '—';
  }

  EffectEditorFormData copyWith({
    String? slug,
    String? effectType,
    String? emoji,
    String? assetUrl,
    String? previewColorHex,
    String? labelKey,
    bool? requiresFaceDetection,
    bool? isScreenEffect,
    bool? isActive,
    int? sortOrder,
    EffectPlacementSettingsEntity? placement,
    bool clearEmoji = false,
    bool clearAssetUrl = false,
    bool clearPreviewColorHex = false,
  }) {
    return EffectEditorFormData(
      slug: slug ?? this.slug,
      effectType: effectType ?? this.effectType,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      assetUrl: clearAssetUrl ? null : (assetUrl ?? this.assetUrl),
      previewColorHex: clearPreviewColorHex
          ? null
          : (previewColorHex ?? this.previewColorHex),
      labelKey: labelKey ?? this.labelKey,
      requiresFaceDetection:
          requiresFaceDetection ?? this.requiresFaceDetection,
      isScreenEffect: isScreenEffect ?? this.isScreenEffect,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      placement: placement ?? this.placement,
    );
  }

  @override
  List<Object?> get props => [
        slug,
        effectType,
        emoji,
        assetUrl,
        previewColorHex,
        labelKey,
        requiresFaceDetection,
        isScreenEffect,
        isActive,
        sortOrder,
        placement,
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
    required this.schema,
    this.effectId,
    this.placementExpanded = true,
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
  final EffectPlacementSchemaEntity schema;
  final bool placementExpanded;
  final Map<String, String> fieldErrors;
  final bool isSaving;
  final bool isUploadingAsset;
  final String? assetFileName;
  final bool saveSucceeded;
  final String? submitError;

  bool get isEditing => effectId != null;

  bool get hasUnsavedChanges => form != baseline;

  bool get hasSlugDefaults =>
      schema.defaultsForSlug(form.slug.trim()) != null;

  EffectEditorReady copyWith({
    EffectEditorFormData? form,
    EffectEditorFormData? baseline,
    EffectPlacementSchemaEntity? schema,
    String? effectId,
    bool? placementExpanded,
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
      schema: schema ?? this.schema,
      placementExpanded: placementExpanded ?? this.placementExpanded,
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      isSaving: isSaving ?? this.isSaving,
      isUploadingAsset: isUploadingAsset ?? this.isUploadingAsset,
      assetFileName:
          clearAssetFileName ? null : (assetFileName ?? this.assetFileName),
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
      submitError:
          clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        effectId,
        form,
        baseline,
        schema,
        placementExpanded,
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
