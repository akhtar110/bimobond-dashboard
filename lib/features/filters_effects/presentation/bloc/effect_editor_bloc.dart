import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/effect_placement_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/effect_placement_visibility.dart';
import '../utils/fe_effect_emoji_display.dart';
import '../utils/fe_preview_color_utils.dart';
import 'effect_editor_event.dart';
import 'effect_editor_state.dart';

class EffectEditorBloc extends Bloc<EffectEditorEvent, EffectEditorState> {
  EffectEditorBloc({
    required GetEffectPlacementSchemaUseCase getSchema,
    required GetCameraEffectUseCase getEffect,
    required CreateCameraEffectUseCase createEffect,
    required UpdateCameraEffectUseCase updateEffect,
    required UploadEffectAssetUseCase uploadEffectAsset,
  })  : _getSchema = getSchema,
        _getEffect = getEffect,
        _createEffect = createEffect,
        _updateEffect = updateEffect,
        _uploadEffectAsset = uploadEffectAsset,
        super(const EffectEditorInitial()) {
    on<LoadEffectEditorEvent>(_onLoad);
    on<EffectBasicFieldChanged>(_onBasicChanged);
    on<UploadEffectAssetEvent>(_onUploadAsset);
    on<EffectPreviewColorChanged>(_onPreviewColorChanged);
    on<EffectAnchorTypeChanged>(_onAnchorTypeChanged);
    on<EffectLandmarksChanged>(_onLandmarksChanged);
    on<EffectPlacementNumericChanged>(_onPlacementNumericChanged);
    on<EffectFallbackAnchorTypeChanged>(_onFallbackAnchorChanged);
    on<ApplyPlacementDefaultsEvent>(_onApplyDefaults);
    on<ResetPlacementEvent>(_onResetPlacement);
    on<ResetEffectEditorEvent>(_onResetEditor);
    on<EffectPlacementExpansionToggled>(_onPlacementExpansionToggled);
    on<SubmitEffectEditorEvent>(_onSubmit);
    on<ClearEffectEditorSaveFlagEvent>(_onClearSaveFlag);
    on<ClearEffectEditorSubmitErrorEvent>(_onClearSubmitError);
  }

  final GetEffectPlacementSchemaUseCase _getSchema;
  final GetCameraEffectUseCase _getEffect;
  final CreateCameraEffectUseCase _createEffect;
  final UpdateCameraEffectUseCase _updateEffect;
  final UploadEffectAssetUseCase _uploadEffectAsset;

  Future<void> _onLoad(
    LoadEffectEditorEvent event,
    Emitter<EffectEditorState> emit,
  ) async {
    emit(const EffectEditorLoading());
    try {
      final schema = await _getSchema();
      if (event.effectId != null) {
        final effect = await _getEffect(event.effectId!);
        final form = _formFromEntity(effect);
        emit(
          EffectEditorReady(
            effectId: effect.id,
            form: form,
            baseline: form,
            schema: schema,
            assetFileName: _assetFileNameFromUrl(effect.assetUrl),
          ),
        );
        return;
      }

      final form = EffectEditorFormData(
        slug: '',
        effectType: CameraEffectTypeApi.faceAr,
        previewColorHex: defaultPreviewColorHex(required: true),
        labelKey: '',
        placement: const EffectPlacementSettingsEntity(
          anchorType: CameraEffectAnchorTypeApi.onFace,
        ),
      );
      emit(
        EffectEditorReady(
          form: form,
          baseline: form,
          schema: schema,
        ),
      );
    } catch (e) {
      emit(EffectEditorError(_formatError(e)));
    }
  }

  void _onBasicChanged(
    EffectBasicFieldChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;

    var form = current.form.copyWith(
      slug: event.slug,
      effectType: event.effectType,
      emoji: event.emoji,
      assetUrl: event.assetUrl,
      labelKey: event.labelKey,
      requiresFaceDetection: event.requiresFaceDetection,
      isScreenEffect: event.isScreenEffect,
      isActive: event.isActive,
      sortOrder: event.sortOrder,
      clearEmoji: event.clearEmoji,
      clearAssetUrl: event.clearAssetUrl,
    );

    if (event.effectType != null) {
      form = _syncFlagsForEffectType(form, event.effectType!);
    }
    if (event.isScreenEffect == true) {
      form = _applyScreenEffectPlacement(form);
    }

    emit(
      current.copyWith(
        form: form,
        clearFieldErrors: true,
        clearAssetFileName: event.clearAssetUrl,
      ),
    );
  }

  Future<void> _onUploadAsset(
    UploadEffectAssetEvent event,
    Emitter<EffectEditorState> emit,
  ) async {
    final current = state;
    if (current is! EffectEditorReady || current.isUploadingAsset) return;

    emit(
      current.copyWith(
        isUploadingAsset: true,
        clearFieldErrors: true,
        clearSubmitError: true,
      ),
    );

    try {
      final url = await _uploadEffectAsset(event.bytes, event.filename);
      final latest = state;
      if (latest is! EffectEditorReady) return;
      emit(
        latest.copyWith(
          isUploadingAsset: false,
          assetFileName: event.filename,
          form: latest.form.copyWith(assetUrl: url),
        ),
      );
    } catch (e) {
      final latest = state;
      if (latest is! EffectEditorReady) return;
      emit(
        latest.copyWith(
          isUploadingAsset: false,
          fieldErrors: {'assetUrl': _formatError(e)},
        ),
      );
    }
  }

  void _onPreviewColorChanged(
    EffectPreviewColorChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
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

  void _onAnchorTypeChanged(
    EffectAnchorTypeChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    final anchorType = event.anchorType == null || event.anchorType!.isEmpty
        ? null
        : CameraEffectAnchorTypeApi.normalize(event.anchorType!);
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.form.placement.copyWith(
            anchorType: anchorType,
            clearAnchorLandmarks: true,
          ),
        ),
      ),
    );
  }

  void _onLandmarksChanged(
    EffectLandmarksChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.form.placement.copyWith(
            anchorLandmarks: event.landmarks,
          ),
        ),
      ),
    );
  }

  void _onPlacementNumericChanged(
    EffectPlacementNumericChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.form.placement.copyWith(
            scaleFactor: event.scaleFactor,
            offsetX: event.offsetX,
            offsetY: event.offsetY,
            landmarkSize: event.landmarkSize,
            fallbackOffsetY: event.fallbackOffsetY,
            fallbackScaleFactor: event.fallbackScaleFactor,
            clearScaleFactor: event.clearScaleFactor,
            clearOffsetX: event.clearOffsetX,
            clearOffsetY: event.clearOffsetY,
            clearLandmarkSize: event.clearLandmarkSize,
            clearFallbackOffsetY: event.clearFallbackOffsetY,
            clearFallbackScaleFactor: event.clearFallbackScaleFactor,
          ),
        ),
      ),
    );
  }

  void _onFallbackAnchorChanged(
    EffectFallbackAnchorTypeChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.form.placement.copyWith(
            fallbackAnchorType: event.anchorType == null ||
                    event.anchorType!.isEmpty
                ? null
                : CameraEffectAnchorTypeApi.normalize(event.anchorType!),
            clearFallbackAnchorType:
                event.anchorType == null || event.anchorType!.isEmpty,
          ),
        ),
      ),
    );
  }

  void _onApplyDefaults(
    ApplyPlacementDefaultsEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    final defaults = current.schema.defaultsForSlug(current.form.slug.trim());
    if (defaults == null) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.form.placement.mergeDefaults(defaults),
        ),
      ),
    );
  }

  void _onResetPlacement(
    ResetPlacementEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(
          placement: current.baseline.placement,
        ),
      ),
    );
  }

  void _onResetEditor(
    ResetEffectEditorEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(current.copyWith(form: current.baseline, clearFieldErrors: true));
  }

  void _onPlacementExpansionToggled(
    EffectPlacementExpansionToggled event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(placementExpanded: !current.placementExpanded),
    );
  }

  Future<void> _onSubmit(
    SubmitEffectEditorEvent event,
    Emitter<EffectEditorState> emit,
  ) async {
    final current = state;
    if (current is! EffectEditorReady || current.isSaving || current.isUploadingAsset) {
      return;
    }

    final errors = _validate(current);
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
        final request = _buildUpdateRequest(current);
        await _updateEffect(
          current.effectId!,
          request,
          baselinePlacement: current.baseline.placement,
        );
      } else {
        await _createEffect(_buildCreateRequest(current));
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
    ClearEffectEditorSaveFlagEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(current.copyWith(saveSucceeded: false));
  }

  void _onClearSubmitError(
    ClearEffectEditorSubmitErrorEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(current.copyWith(clearSubmitError: true));
  }

  EffectEditorFormData _formFromEntity(CameraEffectEntity effect) {
    var emoji = effect.emoji;
    var assetUrl = effect.assetUrl;
    if (FeEffectEmojiDisplay.isImageUrl(emoji)) {
      assetUrl ??= emoji;
      emoji = FeEffectEmojiDisplay.textEmoji(emoji);
    }

    return EffectEditorFormData(
      slug: effect.slug,
      effectType: effect.effectType,
      emoji: emoji,
      assetUrl: assetUrl,
      previewColorHex: effect.previewColorHex,
      labelKey: effect.labelKey,
      requiresFaceDetection: effect.requiresFaceDetection,
      isScreenEffect: effect.isScreenEffect,
      isActive: effect.isActive,
      sortOrder: effect.sortOrder,
      placement: effect.placement,
    );
  }

  EffectEditorFormData _syncFlagsForEffectType(
    EffectEditorFormData form,
    String effectType,
  ) {
    final normalized = CameraEffectTypeApi.normalize(effectType);
    final flags = CameraEffectTypeApi.flagsForType(
      normalized,
      requiresFaceDetection: form.requiresFaceDetection,
    );
    var next = form.copyWith(
      effectType: normalized,
      requiresFaceDetection: flags.requiresFaceDetection,
      isScreenEffect: flags.isScreenEffect,
    );
    if (flags.isScreenEffect) {
      next = _applyScreenEffectPlacement(next);
    }
    return next;
  }

  EffectEditorFormData _applyScreenEffectPlacement(EffectEditorFormData form) {
    return form.copyWith(
      requiresFaceDetection: false,
      isScreenEffect: true,
      placement: form.placement.copyWith(
        anchorType: CameraEffectAnchorTypeApi.screen,
        clearAnchorLandmarks: true,
        clearScaleFactor: true,
        clearOffsetX: true,
        clearOffsetY: true,
        clearLandmarkSize: true,
        clearFallbackAnchorType: true,
        clearFallbackOffsetY: true,
        clearFallbackScaleFactor: true,
      ),
    );
  }

  Map<String, String> _validate(EffectEditorReady current) {
    final errors = <String, String>{};
    final form = current.form;
    if (form.slug.trim().isEmpty) errors['slug'] = 'feRequired';
    if (form.labelKey.trim().isEmpty) errors['labelKey'] = 'feRequired';
    final hex = form.previewColorHex?.trim();
    if (hex == null || hex.isEmpty) {
      errors['previewColorHex'] = 'feRequired';
    } else if (!isValidFePreviewHex(hex)) {
      errors['previewColorHex'] = 'feInvalidHex';
    }
    final asset = form.assetUrl?.trim();
    if (asset != null && asset.isNotEmpty) {
      final uri = Uri.tryParse(asset);
      if (uri == null || !uri.hasScheme) {
        errors['assetUrl'] = 'feInvalidUrl';
      }
    }

    final emojiText = FeEffectEmojiDisplay.textEmoji(form.emoji);
    if (emojiText != null && emojiText.length > 16) {
      errors['emoji'] = 'feEmojiTooLong';
    }

    if (EffectPlacementVisibility.placementEnabled(
      requiresFaceDetection: form.requiresFaceDetection,
      isScreenEffect: form.isScreenEffect,
    )) {
      final anchor = form.placement.anchorType;
      if (anchor == null || anchor.isEmpty) {
        errors['anchorType'] = 'feRequired';
      }
      if (EffectPlacementVisibility.showLandmarkMultiSelect(anchor) &&
          form.placement.anchorLandmarks.isEmpty) {
        errors['anchorLandmarks'] = 'feRequired';
      }
      if (EffectPlacementVisibility.showLandmarkSingleSelect(anchor) &&
          form.placement.anchorLandmarks.isEmpty) {
        errors['anchorLandmarks'] = 'feRequired';
      }
    }

    return errors;
  }

  CreateEffectRequest _buildCreateRequest(EffectEditorReady current) {
    final form = current.form;
    return CreateEffectRequest(
      slug: form.slug.trim(),
      effectType: form.effectType,
      emoji: _emojiForApi(form.emoji),
      assetUrl: _nullableTrim(form.assetUrl),
      previewColorHex: form.previewColorHex!.trim(),
      labelKey: form.labelKey.trim(),
      requiresFaceDetection: form.requiresFaceDetection,
      isScreenEffect: form.isScreenEffect,
      sortOrder: form.sortOrder,
      isActive: form.isActive,
      placement: form.placement,
    );
  }

  UpdateEffectRequest _buildUpdateRequest(EffectEditorReady current) {
    final form = current.form;
    final baseline = current.baseline;
    return UpdateEffectRequest(
      slug: form.slug.trim() != baseline.slug ? form.slug.trim() : null,
      effectType:
          form.effectType != baseline.effectType ? form.effectType : null,
      emoji: form.emoji != baseline.emoji ? _emojiForApi(form.emoji) : null,
      assetUrl: form.assetUrl != baseline.assetUrl
          ? _nullableTrim(form.assetUrl)
          : null,
      previewColorHex: form.previewColorHex != baseline.previewColorHex
          ? form.previewColorHex?.trim()
          : null,
      labelKey: form.labelKey.trim() != baseline.labelKey
          ? form.labelKey.trim()
          : null,
      requiresFaceDetection: form.requiresFaceDetection !=
              baseline.requiresFaceDetection
          ? form.requiresFaceDetection
          : null,
      isScreenEffect: form.isScreenEffect != baseline.isScreenEffect
          ? form.isScreenEffect
          : null,
      sortOrder:
          form.sortOrder != baseline.sortOrder ? form.sortOrder : null,
      isActive: form.isActive != baseline.isActive ? form.isActive : null,
      placement: form.placement != baseline.placement ? form.placement : null,
      clearEmoji: (form.emoji == null || form.emoji!.trim().isEmpty) &&
          (baseline.emoji?.trim().isNotEmpty ?? false),
      clearAssetUrl: (form.assetUrl == null || form.assetUrl!.trim().isEmpty) &&
          (baseline.assetUrl?.trim().isNotEmpty ?? false),
      clearAnchorLandmarks: form.placement.anchorLandmarks.isEmpty &&
          baseline.placement.anchorLandmarks.isNotEmpty,
    );
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _emojiForApi(String? value) {
    final text = FeEffectEmojiDisplay.textEmoji(_nullableTrim(value));
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? _assetFileNameFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }

  Map<String, String> _serverFieldErrors(Object error) {
    if (error is! DioException) return const {};
    final data = error.response?.data;
    if (data is! Map) return const {};
    final errors = <String, String>{};
    final message = data['message'];
    if (message is String) {
      if (message.toLowerCase().contains('slug')) errors['slug'] = message;
    } else if (message is List) {
      for (final item in message) {
        final text = item.toString();
        if (text.toLowerCase().contains('slug')) errors['slug'] = text;
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
