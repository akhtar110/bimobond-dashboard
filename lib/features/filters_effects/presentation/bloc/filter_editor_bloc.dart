import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/fe_api_errors.dart';
import '../utils/fe_preview_color_utils.dart';
import '../utils/filter_lut_picker.dart';
import 'filter_editor_event.dart';
import 'filter_editor_state.dart';

class FilterEditorBloc extends Bloc<FilterEditorEvent, FilterEditorState> {
  FilterEditorBloc({
    required GetCameraFilterUseCase getFilter,
    required CreateCameraFilterUseCase createFilter,
    required UpdateCameraFilterUseCase updateFilter,
    required GetFilterSettingsSchemaUseCase getFilterSettingsSchema,
    required UploadEffectAssetUseCase uploadFilterThumbnail,
    required UploadFilterLutUseCase uploadFilterLut,
  }) : _getFilter = getFilter,
       _createFilter = createFilter,
       _updateFilter = updateFilter,
       _getFilterSettingsSchema = getFilterSettingsSchema,
       _uploadFilterThumbnail = uploadFilterThumbnail,
       _uploadFilterLut = uploadFilterLut,
       super(const FilterEditorInitial()) {
    on<LoadFilterEditorEvent>(_onLoad);
    on<FilterBasicFieldChanged>(_onBasicChanged);
    on<FilterPreviewColorChanged>(_onPreviewColorChanged);
    on<FilterSettingChanged>(_onSettingChanged);
    on<FilterAdjustmentChanged>(_onAdjustmentChanged);
    on<ResetFilterEditorEvent>(_onResetEditor);
    on<UploadFilterThumbnailEvent>(_onUploadThumbnail);
    on<UploadFilterLutEvent>(_onUploadLut);
    on<SubmitFilterEditorEvent>(_onSubmit);
    on<ClearFilterEditorSaveFlagEvent>(_onClearSaveFlag);
    on<ClearFilterEditorSubmitErrorEvent>(_onClearSubmitError);
  }

  final GetCameraFilterUseCase _getFilter;
  final CreateCameraFilterUseCase _createFilter;
  final UpdateCameraFilterUseCase _updateFilter;
  final GetFilterSettingsSchemaUseCase _getFilterSettingsSchema;
  final UploadEffectAssetUseCase _uploadFilterThumbnail;
  final UploadFilterLutUseCase _uploadFilterLut;

  Future<FilterSettingsSchemaEntity?> _loadSettingsSchema() async {
    try {
      return await _getFilterSettingsSchema();
    } catch (_) {
      return null;
    }
  }

  Map<String, int> _adjustmentsFromEntity(CameraFilterEntity filter) {
    return filter.effectiveAdjustments.values.map(
      (key, value) => MapEntry(key, value.round()),
    );
  }

  Future<void> _onLoad(
    LoadFilterEditorEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    emit(const FilterEditorLoading());
    try {
      if (event.filterId != null) {
        final results = await Future.wait([
          _loadSettingsSchema(),
          _getFilter(event.filterId!),
        ]);
        final schema = results[0] as FilterSettingsSchemaEntity?;
        final filter = results[1] as CameraFilterEntity;
        final form = _formFromEntity(filter);
        emit(
          FilterEditorReady(
            filterId: filter.id,
            form: form,
            baseline: form,
            settingsSchema: schema,
            lutFileName: _lutFileNameFromFilter(filter),
          ),
        );
        return;
      }

      final schema = await _loadSettingsSchema();
      const form = FilterEditorFormData(slug: '', label: '');
      emit(FilterEditorReady(form: form, baseline: form, settingsSchema: schema));
    } catch (e) {
      emit(FilterEditorError(formatFeApiError(e)));
    }
  }

  void _onBasicChanged(
    FilterBasicFieldChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;

    var nextForm = current.form.copyWith(
      slug: event.slug,
      label: event.label,
      customLabel: event.customLabel,
      labelKey: event.labelKey,
      emoji: event.emoji,
      thumbnailUrl: event.thumbnailUrl,
      previewColorHex: event.previewColorHex,
      lutUrl: event.lutUrl,
      lutAsset: event.lutAsset,
      isActive: event.isActive,
      sortOrder: event.sortOrder,
      clearCustomLabel: event.clearCustomLabel,
      clearLabelKey: event.clearLabelKey,
      clearEmoji: event.clearEmoji,
      clearThumbnailUrl: event.clearThumbnailUrl,
      clearPreviewColorHex: event.clearPreviewColorHex,
      clearLutUrl: event.clearLutUrl,
      clearLutAsset: event.clearLutAsset,
    );

    if (event.renderType != null) {
      final normalized = CameraFilterRenderTypeApi.fromResponse(
        event.renderType!,
      );
      if (normalized != current.form.renderType) {
        nextForm = nextForm.copyWith(
          renderType: normalized,
          clearLutUrl: normalized == CameraFilterRenderTypeApi.matrix,
          clearLutAsset: normalized == CameraFilterRenderTypeApi.matrix,
          clearAdjustments: normalized == CameraFilterRenderTypeApi.lut,
        );
      }
    }

    emit(
      current.copyWith(
        form: nextForm,
        clearFieldErrors: true,
        clearLutFileName: event.clearLutUrl,
        clearLutPreviewBytes: event.clearLutUrl,
      ),
    );
  }

  void _onSettingChanged(
    FilterSettingChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;

    final nextSettings = current.form.filterSettings.copyWith(
      smooth: event.smooth,
      whiten: event.whiten,
      brighten: event.brighten,
      blush: event.blush,
      lipStrength: event.lipStrength,
      lipTint: event.lipTint,
      defaultIntensity: event.defaultIntensity,
      brightness: event.brightness,
      contrast: event.contrast,
      saturation: event.saturation,
      warmth: event.warmth,
      clearLipTint: event.clearLipTint,
    );

    emit(
      current.copyWith(
        form: current.form.copyWith(filterSettings: nextSettings),
        clearFieldErrors: true,
      ),
    );
  }

  void _onAdjustmentChanged(
    FilterAdjustmentChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    final next = Map<String, int>.from(current.form.adjustments)
      ..[event.key] = event.value;
    emit(
      current.copyWith(
        form: current.form.copyWith(adjustments: next),
        clearFieldErrors: true,
      ),
    );
  }

  Future<void> _onUploadLut(
    UploadFilterLutEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    final current = state;
    if (current is! FilterEditorReady || current.isUploadingLut) return;

    if (!isAllowedFilterLutFilename(event.filename)) {
      emit(
        current.copyWith(
          fieldErrors: {'lutUrl': 'feInvalidLutFileType'},
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isUploadingLut: true,
        lutFileName: event.filename,
        lutPreviewBytes: Uint8List.fromList(event.bytes),
        clearFieldErrors: true,
        clearSubmitError: true,
      ),
    );

    try {
      final result = await _uploadFilterLut(event.bytes, event.filename);
      final latest = state;
      if (latest is! FilterEditorReady) return;

      emit(
        latest.copyWith(
          isUploadingLut: false,
          lutFileName: event.filename,
          lutPreviewBytes: Uint8List.fromList(event.bytes),
          form: latest.form.copyWith(
            lutUrl: result.lutUrl,
            lutAsset: result.lutAsset?.trim().isNotEmpty == true
                ? result.lutAsset
                : latest.form.lutAsset,
          ),
        ),
      );
    } catch (e) {
      final latest = state;
      if (latest is! FilterEditorReady) return;
      emit(
        latest.copyWith(
          isUploadingLut: false,
          fieldErrors: {'lutUrl': formatFeApiError(e)},
        ),
      );
    }
  }

  Future<void> _onUploadThumbnail(
    UploadFilterThumbnailEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    final current = state;
    if (current is! FilterEditorReady || current.isUploadingThumbnail) return;

    emit(
      current.copyWith(
        isUploadingThumbnail: true,
        clearFieldErrors: true,
        clearSubmitError: true,
      ),
    );

    try {
      final url = await _uploadFilterThumbnail(event.bytes, event.filename);
      final latest = state;
      if (latest is! FilterEditorReady) return;
      emit(
        latest.copyWith(
          isUploadingThumbnail: false,
          thumbnailFileName: event.filename,
          form: latest.form.copyWith(thumbnailUrl: url),
        ),
      );
    } catch (e) {
      final latest = state;
      if (latest is! FilterEditorReady) return;
      emit(
        latest.copyWith(
          isUploadingThumbnail: false,
          fieldErrors: {'thumbnailUrl': formatFeApiError(e)},
        ),
      );
    }
  }

  void _onPreviewColorChanged(
    FilterPreviewColorChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    final hex = event.hex?.trim().toUpperCase();
    emit(
      current.copyWith(
        form: current.form.copyWith(
          previewColorHex: hex == null || hex.isEmpty ? null : hex,
          clearPreviewColorHex: hex == null || hex.isEmpty,
        ),
      ),
    );
  }

  void _onResetEditor(
    ResetFilterEditorEvent event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(current.copyWith(form: current.baseline, clearFieldErrors: true));
  }

  Future<void> _onSubmit(
    SubmitFilterEditorEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    final current = state;
    if (current is! FilterEditorReady ||
        current.isSaving ||
        current.isUploadingThumbnail ||
        current.isUploadingLut) {
      return;
    }

    final errors = _validate(current.form);
    if (errors.isNotEmpty) {
      emit(current.copyWith(fieldErrors: errors));
      return;
    }

    emit(
      current.copyWith(
        isSaving: true,
        clearFieldErrors: true,
        clearSubmitError: true,
      ),
    );
    try {
      if (current.isEditing) {
        await _updateFilter(current.filterId!, _buildUpdateRequest(current));
      } else {
        await _createFilter(_buildCreateRequest(current));
      }
      emit(
        current.copyWith(
          isSaving: false,
          saveSucceeded: true,
          baseline: current.form,
        ),
      );
    } catch (e) {
      final message = formatFeApiError(e);
      final serverErrors = _serverFieldErrors(e);
      if (serverErrors.isNotEmpty) {
        emit(current.copyWith(isSaving: false, fieldErrors: serverErrors));
      } else {
        emit(current.copyWith(isSaving: false, submitError: message));
      }
    }
  }

  void _onClearSaveFlag(
    ClearFilterEditorSaveFlagEvent event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(current.copyWith(saveSucceeded: false));
  }

  void _onClearSubmitError(
    ClearFilterEditorSubmitErrorEvent event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(current.copyWith(clearSubmitError: true));
  }

  FilterEditorFormData _formFromEntity(CameraFilterEntity filter) {
    return FilterEditorFormData(
      slug: filter.slug,
      label: filter.label,
      customLabel: filter.customLabel,
      labelKey: filter.labelKey,
      emoji: filter.emoji,
      thumbnailUrl: filter.thumbnailUrl,
      previewColorHex: filter.previewColorHex,
      filterSettings: filter.filterSettings,
      isActive: filter.isActive,
      sortOrder: filter.sortOrder,
      isOriginal: filter.isOriginal,
      isBeautyDefault: filter.isBeautyDefault,
      renderType: CameraFilterRenderTypeApi.fromResponse(filter.renderType),
      lutUrl: filter.lutUrl,
      lutAsset: filter.lutAsset,
      adjustments: _adjustmentsFromEntity(filter),
      colorMatrix: List<double>.from(filter.colorMatrix),
    );
  }

  Map<String, String> _validate(FilterEditorFormData form) {
    final errors = <String, String>{};
    final slug = form.slug.trim();
    final label = form.label.trim();
    if (slug.isEmpty) {
      errors['slug'] = 'feRequired';
    } else if (slug.length > 80) {
      errors['slug'] = 'feSlugTooLong';
    }
    if (label.isEmpty) {
      errors['label'] = 'feRequired';
    } else if (label.length > 80) {
      errors['label'] = 'feLabelTooLong';
    }
    final labelKey = form.labelKey?.trim();
    if (labelKey != null && labelKey.length > 100) {
      errors['labelKey'] = 'feLabelKeyTooLong';
    }
    final emoji = form.emoji?.trim();
    if (emoji != null && emoji.length > 16) {
      errors['emoji'] = 'feEmojiTooLong';
    }
    final hex = form.previewColorHex?.trim();
    if (hex != null && hex.isNotEmpty) {
      if (hex.length > 7 || !isValidFePreviewHex(hex)) {
        errors['previewColorHex'] = 'feInvalidHex';
      }
    }
    final lipTint = form.filterSettings.lipTint?.trim();
    if (lipTint != null && lipTint.isNotEmpty) {
      if (lipTint.length > 7 || !isValidFePreviewHex(lipTint)) {
        errors['lipTint'] = 'feInvalidHex';
      }
    }
    if (form.sortOrder < 0) {
      errors['sortOrder'] = 'feInvalidSortOrder';
    }
    final thumb = form.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      final uri = Uri.tryParse(thumb);
      if (uri == null || !uri.hasScheme) {
        errors['thumbnailUrl'] = 'feInvalidUrl';
      }
    }
    return errors;
  }

  CreateFilterRequest _buildCreateRequest(FilterEditorReady current) {
    final form = current.form;
    return CreateFilterRequest(
      slug: form.slug.trim(),
      label: form.label.trim(),
      customLabel: _nullableTrim(form.customLabel),
      labelKey: _nullableTrim(form.labelKey),
      emoji: _nullableTrim(form.emoji),
      thumbnailUrl: _nullableTrim(form.thumbnailUrl),
      previewColorHex: _nullableTrim(form.previewColorHex),
      filterSettings: form.filterSettings,
      sortOrder: form.sortOrder,
      isActive: form.isActive,
    );
  }

  UpdateFilterRequest _buildUpdateRequest(FilterEditorReady current) {
    final form = current.form;
    final baseline = current.baseline;
    final settingsChanged = form.filterSettings != baseline.filterSettings;

    return UpdateFilterRequest(
      slug: form.slug.trim() != baseline.slug ? form.slug.trim() : null,
      label: form.label.trim() != baseline.label ? form.label.trim() : null,
      customLabel: form.customLabel != baseline.customLabel
          ? _nullableTrim(form.customLabel)
          : null,
      labelKey: form.labelKey != baseline.labelKey ? _nullableTrim(form.labelKey) : null,
      emoji: form.emoji != baseline.emoji ? _nullableTrim(form.emoji) : null,
      thumbnailUrl: form.thumbnailUrl != baseline.thumbnailUrl
          ? _nullableTrim(form.thumbnailUrl)
          : null,
      previewColorHex: form.previewColorHex != baseline.previewColorHex
          ? _nullableTrim(form.previewColorHex)
          : null,
      filterSettings: settingsChanged ? form.filterSettings : null,
      sortOrder: form.sortOrder != baseline.sortOrder ? form.sortOrder : null,
      isActive: form.isActive != baseline.isActive ? form.isActive : null,
      clearCustomLabel:
          (form.customLabel == null || form.customLabel!.isEmpty) &&
          (baseline.customLabel?.isNotEmpty ?? false),
      clearLabelKey:
          (form.labelKey == null || form.labelKey!.isEmpty) &&
          (baseline.labelKey?.isNotEmpty ?? false),
      clearEmoji:
          (form.emoji == null || form.emoji!.isEmpty) &&
          (baseline.emoji?.isNotEmpty ?? false),
      clearThumbnailUrl:
          (form.thumbnailUrl == null || form.thumbnailUrl!.isEmpty) &&
          (baseline.thumbnailUrl?.isNotEmpty ?? false),
      clearPreviewColorHex:
          (form.previewColorHex == null || form.previewColorHex!.isEmpty) &&
          (baseline.previewColorHex?.isNotEmpty ?? false),
    );
  }



  String? _lutFileNameFromFilter(CameraFilterEntity filter) {
    final asset = filter.lutAsset?.trim();
    if (asset != null && asset.isNotEmpty) return asset;
    final url = filter.lutUrl?.trim();
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Map<String, String> _serverFieldErrors(Object error) {
    if (error is! DioException) return const {};
    final data = error.response?.data;
    if (data is! Map) return const {};
    final errors = <String, String>{};
    final message = data['message'];
    void consider(String text) {
      final lower = text.toLowerCase();
      if (lower.contains('slug')) errors['slug'] = text;
      if (lower.contains('label')) errors['label'] = text;
      if (lower.contains('lut')) errors['lut'] = text;
    }

    if (message is String) {
      consider(message);
    } else if (message is List) {
      for (final item in message) {
        consider(item.toString());
      }
    }
    return errors;
  }
}
