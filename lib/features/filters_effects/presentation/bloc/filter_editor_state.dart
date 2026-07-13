import 'package:equatable/equatable.dart';

import '../../domain/entities/filter_settings_entities.dart';

/// Immutable snapshot of the filter editor form for dirty-checking.
class FilterEditorFormData extends Equatable {
  const FilterEditorFormData({
    required this.slug,
    required this.engineKey,
    required this.engineType,
    this.labelKey,
    this.customLabel,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isOriginal = false,
    this.isBeautyDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.filterSettings = FilterSettingsEntity.empty,
  });

  final String slug;
  final String engineKey;
  final String engineType;
  final String? labelKey;
  final String? customLabel;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool isOriginal;
  final bool isBeautyDefault;
  final bool isActive;
  final int sortOrder;
  final FilterSettingsEntity filterSettings;

  String get displayLabel {
    final custom = customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final key = labelKey?.trim();
    if (key != null && key.isNotEmpty) return key;
    final s = slug.trim();
    return s.isNotEmpty ? s : '—';
  }

  FilterEditorFormData copyWith({
    String? slug,
    String? engineKey,
    String? engineType,
    String? labelKey,
    String? customLabel,
    String? thumbnailUrl,
    String? previewColorHex,
    bool? isOriginal,
    bool? isBeautyDefault,
    bool? isActive,
    int? sortOrder,
    FilterSettingsEntity? filterSettings,
    bool clearLabelKey = false,
    bool clearCustomLabel = false,
    bool clearThumbnailUrl = false,
    bool clearPreviewColorHex = false,
  }) {
    return FilterEditorFormData(
      slug: slug ?? this.slug,
      engineKey: engineKey ?? this.engineKey,
      engineType: engineType ?? this.engineType,
      labelKey: clearLabelKey ? null : (labelKey ?? this.labelKey),
      customLabel:
          clearCustomLabel ? null : (customLabel ?? this.customLabel),
      thumbnailUrl:
          clearThumbnailUrl ? null : (thumbnailUrl ?? this.thumbnailUrl),
      previewColorHex: clearPreviewColorHex
          ? null
          : (previewColorHex ?? this.previewColorHex),
      isOriginal: isOriginal ?? this.isOriginal,
      isBeautyDefault: isBeautyDefault ?? this.isBeautyDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      filterSettings: filterSettings ?? this.filterSettings,
    );
  }

  @override
  List<Object?> get props => [
        slug,
        engineKey,
        engineType,
        labelKey,
        customLabel,
        thumbnailUrl,
        previewColorHex,
        isOriginal,
        isBeautyDefault,
        isActive,
        sortOrder,
        filterSettings,
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
    required this.schema,
    this.filterId,
    this.colorMatrix = const [],
    this.expandedGroups = const {},
    this.allGroupsExpanded = true,
    this.settingsSearchQuery = '',
    this.fieldErrors = const {},
    this.isSaving = false,
    this.isUploadingThumbnail = false,
    this.thumbnailFileName,
    this.saveSucceeded = false,
    this.submitError,
  });

  final String? filterId;
  final FilterEditorFormData form;
  final FilterEditorFormData baseline;
  final FilterSettingsSchemaEntity schema;
  final List<double> colorMatrix;
  final Set<String> expandedGroups;
  final bool allGroupsExpanded;
  final String settingsSearchQuery;
  final Map<String, String> fieldErrors;
  final bool isSaving;
  final bool isUploadingThumbnail;
  final String? thumbnailFileName;
  final bool saveSucceeded;
  final String? submitError;

  bool get isEditing => filterId != null;

  bool get hasUnsavedChanges => form != baseline;

  bool isGroupExpanded(String groupKey) =>
      allGroupsExpanded || expandedGroups.contains(groupKey);

  FilterEditorReady copyWith({
    FilterEditorFormData? form,
    FilterEditorFormData? baseline,
    FilterSettingsSchemaEntity? schema,
    String? filterId,
    List<double>? colorMatrix,
    Set<String>? expandedGroups,
    bool? allGroupsExpanded,
    String? settingsSearchQuery,
    Map<String, String>? fieldErrors,
    bool? isSaving,
    bool? isUploadingThumbnail,
    String? thumbnailFileName,
    bool? saveSucceeded,
    String? submitError,
    bool clearFieldErrors = false,
    bool clearSubmitError = false,
    bool clearThumbnailFileName = false,
  }) {
    return FilterEditorReady(
      filterId: filterId ?? this.filterId,
      form: form ?? this.form,
      baseline: baseline ?? this.baseline,
      schema: schema ?? this.schema,
      colorMatrix: colorMatrix ?? this.colorMatrix,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      allGroupsExpanded: allGroupsExpanded ?? this.allGroupsExpanded,
      settingsSearchQuery: settingsSearchQuery ?? this.settingsSearchQuery,
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      isSaving: isSaving ?? this.isSaving,
      isUploadingThumbnail:
          isUploadingThumbnail ?? this.isUploadingThumbnail,
      thumbnailFileName: clearThumbnailFileName
          ? null
          : (thumbnailFileName ?? this.thumbnailFileName),
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
      submitError:
          clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        filterId,
        form,
        baseline,
        schema,
        colorMatrix,
        expandedGroups,
        allGroupsExpanded,
        settingsSearchQuery,
        fieldErrors,
        isSaving,
        isUploadingThumbnail,
        thumbnailFileName,
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
