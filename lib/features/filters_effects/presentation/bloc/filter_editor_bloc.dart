import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/filters_effects_remote_datasource.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/fe_preview_color_utils.dart';
import 'filter_editor_event.dart';
import 'filter_editor_state.dart';

class FilterEditorBloc extends Bloc<FilterEditorEvent, FilterEditorState> {
  FilterEditorBloc({
    required GetFilterSettingsSchemaUseCase getSchema,
    required GetCameraFilterUseCase getFilter,
    required CreateCameraFilterUseCase createFilter,
    required UpdateCameraFilterUseCase updateFilter,
    required UploadEffectAssetUseCase uploadFilterThumbnail,
  })  : _getSchema = getSchema,
        _getFilter = getFilter,
        _createFilter = createFilter,
        _updateFilter = updateFilter,
        _uploadFilterThumbnail = uploadFilterThumbnail,
        super(const FilterEditorInitial()) {
    on<LoadFilterEditorEvent>(_onLoad);
    on<LoadFilterSchemaEvent>(_onLoadSchema);
    on<LoadFilterDetailEvent>(_onLoadDetail);
    on<FilterBasicFieldChanged>(_onBasicChanged);
    on<FilterSliderChanged>(_onSliderChanged);
    on<FilterPreviewColorChanged>(_onPreviewColorChanged);
    on<FilterSettingsSearchChanged>(_onSearchChanged);
    on<FilterGroupExpansionToggled>(_onGroupToggled);
    on<FilterToggleAllGroupsEvent>(_onToggleAllGroups);
    on<ResetFilterSettingsEvent>(_onResetSettings);
    on<ResetFilterEditorEvent>(_onResetEditor);
    on<UploadFilterThumbnailEvent>(_onUploadThumbnail);
    on<SubmitFilterEditorEvent>(_onSubmit);
    on<ClearFilterEditorSaveFlagEvent>(_onClearSaveFlag);
    on<ClearFilterEditorSubmitErrorEvent>(_onClearSubmitError);
  }

  final GetFilterSettingsSchemaUseCase _getSchema;
  final GetCameraFilterUseCase _getFilter;
  final CreateCameraFilterUseCase _createFilter;
  final UpdateCameraFilterUseCase _updateFilter;
  final UploadEffectAssetUseCase _uploadFilterThumbnail;

  Future<void> _onLoad(
    LoadFilterEditorEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    emit(const FilterEditorLoading());
    try {
      final schema = await _getSchema();
      if (event.filterId != null) {
        final filter = await _getFilter(event.filterId!);
        final form = _formFromEntity(filter, schema);
        emit(
          FilterEditorReady(
            filterId: filter.id,
            form: form,
            baseline: form,
            schema: schema,
            colorMatrix: filter.colorMatrix,
            expandedGroups: schema.groups.map((g) => g.key).toSet(),
          ),
        );
        return;
      }

      final form = FilterEditorFormData(
        slug: '',
        engineKey: kCameraAwesomeEngineKeys.first,
        engineType: CameraFilterEngineTypeApi.camerawesome,
        filterSettings: FilterSettingsEntity(schema.defaultValues()),
      );
      emit(
        FilterEditorReady(
          form: form,
          baseline: form,
          schema: schema,
          expandedGroups: schema.groups.map((g) => g.key).toSet(),
        ),
      );
    } catch (e) {
      emit(FilterEditorError(_formatError(e)));
    }
  }

  Future<void> _onLoadSchema(
    LoadFilterSchemaEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    final current = state;
    if (current is! FilterEditorReady) return;
    try {
      final schema = await _getSchema();
      emit(current.copyWith(schema: schema));
    } catch (e) {
      emit(FilterEditorError(_formatError(e)));
    }
  }

  Future<void> _onLoadDetail(
    LoadFilterDetailEvent event,
    Emitter<FilterEditorState> emit,
  ) async {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(const FilterEditorLoading());
    try {
      final filter = await _getFilter(event.filterId);
      final form = _formFromEntity(filter, current.schema);
      emit(
        FilterEditorReady(
          filterId: filter.id,
          form: form,
          baseline: form,
          schema: current.schema,
          colorMatrix: filter.colorMatrix,
          expandedGroups: current.schema.groups.map((g) => g.key).toSet(),
        ),
      );
    } catch (e) {
      emit(FilterEditorError(_formatError(e)));
    }
  }

  void _onBasicChanged(
    FilterBasicFieldChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          slug: event.slug,
          engineKey: event.engineKey,
          engineType: event.engineType,
          labelKey: event.labelKey,
          customLabel: event.customLabel,
          thumbnailUrl: event.thumbnailUrl,
          previewColorHex: event.previewColorHex,
          isOriginal: event.isOriginal,
          isBeautyDefault: event.isBeautyDefault,
          isActive: event.isActive,
          sortOrder: event.sortOrder,
          clearLabelKey: event.clearLabelKey,
          clearCustomLabel: event.clearCustomLabel,
          clearThumbnailUrl: event.clearThumbnailUrl,
          clearPreviewColorHex: event.clearPreviewColorHex,
        ),
        clearFieldErrors: true,
        clearThumbnailFileName: event.clearThumbnailUrl,
      ),
    );
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
          fieldErrors: {'thumbnailUrl': _formatError(e)},
        ),
      );
    }
  }

  void _onSliderChanged(
    FilterSliderChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          filterSettings:
              current.form.filterSettings.withValue(event.key, event.value),
        ),
      ),
    );
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

  void _onSearchChanged(
    FilterSettingsSearchChanged event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(current.copyWith(settingsSearchQuery: event.query.trim()));
  }

  void _onGroupToggled(
    FilterGroupExpansionToggled event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    final next = Set<String>.from(current.expandedGroups);
    if (next.contains(event.groupKey)) {
      next.remove(event.groupKey);
    } else {
      next.add(event.groupKey);
    }
    emit(
      current.copyWith(
        expandedGroups: next,
        allGroupsExpanded: false,
      ),
    );
  }

  void _onToggleAllGroups(
    FilterToggleAllGroupsEvent event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(
      current.copyWith(
        allGroupsExpanded: event.expand,
        expandedGroups: event.expand
            ? current.schema.groups.map((g) => g.key).toSet()
            : const {},
      ),
    );
  }

  void _onResetSettings(
    ResetFilterSettingsEvent event,
    Emitter<FilterEditorState> emit,
  ) {
    final current = state;
    if (current is! FilterEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          filterSettings:
              current.form.filterSettings.resetToDefaults(current.schema),
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
        current.isUploadingThumbnail) {
      return;
    }

    final errors = _validate(current);
    if (errors.isNotEmpty) {
      emit(current.copyWith(fieldErrors: errors));
      return;
    }

    emit(current.copyWith(isSaving: true, clearFieldErrors: true, clearSubmitError: true));
    try {
      if (current.isEditing) {
        final request = _buildUpdateRequest(current);
        await _updateFilter(
          current.filterId!,
          request,
          schema: current.schema,
        );
      } else {
        final request = _buildCreateRequest(current);
        await _createFilter(request, schema: current.schema);
      }
      emit(
        current.copyWith(
          isSaving: false,
          saveSucceeded: true,
          baseline: current.form,
        ),
      );
    } catch (e) {
      final message = _formatError(e);
      final serverErrors = _serverFieldErrors(e);
      if (serverErrors.isNotEmpty) {
        emit(
          current.copyWith(
            isSaving: false,
            fieldErrors: serverErrors,
          ),
        );
      } else {
        emit(
          current.copyWith(
            isSaving: false,
            submitError: message,
          ),
        );
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

  FilterEditorFormData _formFromEntity(
    CameraFilterEntity filter,
    FilterSettingsSchemaEntity schema,
  ) {
    final defaults = schema.defaultValues();
    final merged = Map<String, int>.from(defaults);
    merged.addAll(filter.filterSettings.values);
    return FilterEditorFormData(
      slug: filter.slug,
      engineKey: filter.engineKey,
      engineType: filter.engineType,
      labelKey: filter.labelKey,
      customLabel: filter.customLabel,
      thumbnailUrl: filter.thumbnailUrl,
      previewColorHex: filter.previewColorHex,
      isOriginal: filter.isOriginal,
      isBeautyDefault: filter.isBeautyDefault,
      isActive: filter.isActive,
      sortOrder: filter.sortOrder,
      filterSettings: FilterSettingsEntity(merged),
    );
  }

  Map<String, String> _validate(FilterEditorReady current) {
    final errors = <String, String>{};
    final form = current.form;
    if (form.slug.trim().isEmpty) {
      errors['slug'] = 'feRequired';
    }
    if (form.engineKey.trim().isEmpty) {
      errors['engineKey'] = 'feRequired';
    }
    final hex = form.previewColorHex?.trim();
    if (hex != null && hex.isNotEmpty && !isValidFePreviewHex(hex)) {
      errors['previewColorHex'] = 'feInvalidHex';
    }
    return errors;
  }

  CreateFilterRequest _buildCreateRequest(FilterEditorReady current) {
    final form = current.form;
    return CreateFilterRequest(
      slug: form.slug.trim(),
      engineKey: form.engineKey.trim(),
      engineType: form.engineType,
      labelKey: _nullableTrim(form.labelKey),
      customLabel: _nullableTrim(form.customLabel),
      thumbnailUrl: _nullableTrim(form.thumbnailUrl),
      previewColorHex: _nullableTrim(form.previewColorHex),
      isOriginal: form.isOriginal,
      isBeautyDefault: form.isBeautyDefault,
      sortOrder: form.sortOrder,
      isActive: form.isActive,
      filterSettings: form.filterSettings,
    );
  }

  UpdateFilterRequest _buildUpdateRequest(FilterEditorReady current) {
    final form = current.form;
    final baseline = current.baseline;
    final settingsChanged = form.filterSettings != baseline.filterSettings;
    final settingsAreDefaults = form.filterSettings.equalsDefaults(current.schema);
    final request = UpdateFilterRequest(
      slug: form.slug.trim() != baseline.slug ? form.slug.trim() : null,
      engineKey:
          form.engineKey.trim() != baseline.engineKey ? form.engineKey.trim() : null,
      engineType: form.engineType != baseline.engineType ? form.engineType : null,
      labelKey: form.labelKey != baseline.labelKey ? form.labelKey : null,
      customLabel:
          form.customLabel != baseline.customLabel ? form.customLabel : null,
      thumbnailUrl:
          form.thumbnailUrl != baseline.thumbnailUrl ? form.thumbnailUrl : null,
      previewColorHex: form.previewColorHex != baseline.previewColorHex
          ? form.previewColorHex
          : null,
      isOriginal:
          form.isOriginal != baseline.isOriginal ? form.isOriginal : null,
      isBeautyDefault: form.isBeautyDefault != baseline.isBeautyDefault
          ? form.isBeautyDefault
          : null,
      sortOrder:
          form.sortOrder != baseline.sortOrder ? form.sortOrder : null,
      isActive: form.isActive != baseline.isActive ? form.isActive : null,
      filterSettings:
          settingsChanged && !settingsAreDefaults ? form.filterSettings : null,
      clearFilterSettings: settingsChanged && settingsAreDefaults,
      clearLabelKey: (form.labelKey == null || form.labelKey!.isEmpty) &&
          (baseline.labelKey?.isNotEmpty ?? false),
      clearCustomLabel: (form.customLabel == null || form.customLabel!.isEmpty) &&
          (baseline.customLabel?.isNotEmpty ?? false),
      clearThumbnailUrl:
          (form.thumbnailUrl == null || form.thumbnailUrl!.isEmpty) &&
              (baseline.thumbnailUrl?.isNotEmpty ?? false),
      clearPreviewColorHex:
          (form.previewColorHex == null || form.previewColorHex!.isEmpty) &&
              (baseline.previewColorHex?.isNotEmpty ?? false),
    );
    return request;
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
    if (message is String && message.toLowerCase().contains('slug')) {
      errors['slug'] = message;
    } else if (message is List) {
      for (final item in message) {
        final text = item.toString();
        if (text.toLowerCase().contains('slug')) {
          errors['slug'] = text;
        }
      }
    }
    return errors;
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) return message.join('\n');
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }
}
