import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';

/// Immutable snapshot of the filter editor form for dirty-checking.
class FilterEditorFormData extends Equatable {
  const FilterEditorFormData({
    required this.slug,
    required this.label,
    this.customLabel,
    this.labelKey,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.filterSettings = FilterSettingsEntity.empty,
    this.isActive = true,
    this.sortOrder = 0,
    this.isOriginal = false,
    this.isBeautyDefault = false,
    this.renderType = CameraFilterRenderTypeApi.lut,
    this.lutUrl,
    this.lutAsset,
    this.adjustments = const {},
    this.colorMatrix = const [],
  });

  final String slug;
  final String label;
  final String? customLabel;
  final String? labelKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final FilterSettingsEntity filterSettings;
  final bool isActive;
  final int sortOrder;
  final bool isOriginal;
  final bool isBeautyDefault;
  final String renderType;
  final String? lutUrl;
  final String? lutAsset;
  final Map<String, int> adjustments;
  final List<double> colorMatrix;

  bool get isLut => CameraFilterRenderTypeApi.isLut(renderType);

  bool get isMatrix => CameraFilterRenderTypeApi.isMatrix(renderType);

  String get displayLabel {
    final custom = customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final primary = label.trim();
    if (primary.isNotEmpty) return primary;
    final s = slug.trim();
    return s.isNotEmpty ? s : '—';
  }

  CameraFilterAdjustments get adjustmentsPayload =>
      CameraFilterAdjustments(
        adjustments.map((key, value) => MapEntry(key, value)),
      );

  FilterEditorFormData copyWith({
    String? slug,
    String? label,
    String? customLabel,
    String? labelKey,
    String? emoji,
    String? thumbnailUrl,
    String? previewColorHex,
    FilterSettingsEntity? filterSettings,
    bool? isActive,
    int? sortOrder,
    bool? isOriginal,
    bool? isBeautyDefault,
    String? renderType,
    String? lutUrl,
    String? lutAsset,
    Map<String, int>? adjustments,
    List<double>? colorMatrix,
    bool clearCustomLabel = false,
    bool clearLabelKey = false,
    bool clearEmoji = false,
    bool clearThumbnailUrl = false,
    bool clearPreviewColorHex = false,
    bool clearLutUrl = false,
    bool clearLutAsset = false,
    bool clearAdjustments = false,
  }) {
    return FilterEditorFormData(
      slug: slug ?? this.slug,
      label: label ?? this.label,
      customLabel: clearCustomLabel ? null : (customLabel ?? this.customLabel),
      labelKey: clearLabelKey ? null : (labelKey ?? this.labelKey),
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      thumbnailUrl: clearThumbnailUrl
          ? null
          : (thumbnailUrl ?? this.thumbnailUrl),
      previewColorHex: clearPreviewColorHex
          ? null
          : (previewColorHex ?? this.previewColorHex),
      filterSettings: filterSettings ?? this.filterSettings,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      isOriginal: isOriginal ?? this.isOriginal,
      isBeautyDefault: isBeautyDefault ?? this.isBeautyDefault,
      renderType: renderType ?? this.renderType,
      lutUrl: clearLutUrl ? null : (lutUrl ?? this.lutUrl),
      lutAsset: clearLutAsset ? null : (lutAsset ?? this.lutAsset),
      adjustments: clearAdjustments
          ? const {}
          : (adjustments ?? this.adjustments),
      colorMatrix: colorMatrix ?? this.colorMatrix,
    );
  }

  @override
  List<Object?> get props => [
    slug,
    label,
    customLabel,
    labelKey,
    emoji,
    thumbnailUrl,
    previewColorHex,
    filterSettings,
    isActive,
    sortOrder,
    isOriginal,
    isBeautyDefault,
    renderType,
    lutUrl,
    lutAsset,
    adjustments,
    colorMatrix,
  ];
}

abstract class FilterEditorState extends Equatable {
  const FilterEditorState();

  @override
  List<Object?> get props => [];
}

class FilterEditorInitial extends FilterEditorState {
  const FilterEditorInitial();
}

class FilterEditorLoading extends FilterEditorState {
  const FilterEditorLoading();
}

class FilterEditorReady extends FilterEditorState {
  const FilterEditorReady({
    required this.form,
    required this.baseline,
    this.filterId,
    this.settingsSchema,
    this.fieldErrors = const {},
    this.isSaving = false,
    this.isUploadingThumbnail = false,
    this.thumbnailFileName,
    this.isUploadingLut = false,
    this.lutFileName,
    this.lutPreviewBytes,
    this.saveSucceeded = false,
    this.submitError,
  });

  final String? filterId;
  final FilterEditorFormData form;
  final FilterEditorFormData baseline;
  final FilterSettingsSchemaEntity? settingsSchema;
  final Map<String, String> fieldErrors;
  final bool isSaving;
  final bool isUploadingThumbnail;
  final String? thumbnailFileName;
  final bool isUploadingLut;
  final String? lutFileName;
  final Uint8List? lutPreviewBytes;
  final bool saveSucceeded;
  final String? submitError;

  bool get isEditing => filterId != null;

  bool get hasUnsavedChanges => form != baseline;

  FilterEditorReady copyWith({
    FilterEditorFormData? form,
    FilterEditorFormData? baseline,
    String? filterId,
    FilterSettingsSchemaEntity? settingsSchema,
    Map<String, String>? fieldErrors,
    bool? isSaving,
    bool? isUploadingThumbnail,
    String? thumbnailFileName,
    bool? isUploadingLut,
    String? lutFileName,
    Uint8List? lutPreviewBytes,
    bool? saveSucceeded,
    String? submitError,
    bool clearFieldErrors = false,
    bool clearSubmitError = false,
    bool clearThumbnailFileName = false,
    bool clearLutFileName = false,
    bool clearLutPreviewBytes = false,
  }) {
    return FilterEditorReady(
      filterId: filterId ?? this.filterId,
      form: form ?? this.form,
      baseline: baseline ?? this.baseline,
      settingsSchema: settingsSchema ?? this.settingsSchema,
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      isSaving: isSaving ?? this.isSaving,
      isUploadingThumbnail: isUploadingThumbnail ?? this.isUploadingThumbnail,
      thumbnailFileName: clearThumbnailFileName
          ? null
          : (thumbnailFileName ?? this.thumbnailFileName),
      isUploadingLut: isUploadingLut ?? this.isUploadingLut,
      lutFileName: clearLutFileName ? null : (lutFileName ?? this.lutFileName),
      lutPreviewBytes: clearLutPreviewBytes
          ? null
          : (lutPreviewBytes ?? this.lutPreviewBytes),
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
    filterId,
    form,
    baseline,
    settingsSchema,
    fieldErrors,
    isSaving,
    isUploadingThumbnail,
    thumbnailFileName,
    isUploadingLut,
    lutFileName,
    lutPreviewBytes,
    saveSucceeded,
    submitError,
  ];
}

class FilterEditorError extends FilterEditorState {
  const FilterEditorError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
