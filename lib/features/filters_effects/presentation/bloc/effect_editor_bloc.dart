import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/effect_anchor_form_data.dart';
import '../utils/fe_api_errors.dart';
import '../utils/fe_effect_emoji_display.dart';
import '../utils/fe_preview_color_utils.dart';
import 'effect_editor_event.dart';
import 'effect_editor_state.dart';

class EffectEditorBloc extends Bloc<EffectEditorEvent, EffectEditorState> {
  EffectEditorBloc({
    required GetCameraEffectUseCase getEffect,
    required CreateCameraEffectUseCase createEffect,
    required UpdateCameraEffectUseCase updateEffect,
    required UploadEffectAssetUseCase uploadEffectAsset,
  }) : _getEffect = getEffect,
       _createEffect = createEffect,
       _updateEffect = updateEffect,
       _uploadEffectAsset = uploadEffectAsset,
       super(const EffectEditorInitial()) {
    on<LoadEffectEditorEvent>(_onLoad);
    on<EffectBasicFieldChanged>(_onBasicChanged);
    on<EffectAnchorChanged>(_onAnchorChanged);
    on<EffectStickersChanged>(_onStickersChanged);
    on<UploadEffectAssetEvent>(_onUploadAsset);
    on<EffectPreviewColorChanged>(_onPreviewColorChanged);
    on<ResetEffectEditorEvent>(_onResetEditor);
    on<SubmitEffectEditorEvent>(_onSubmit);
    on<ClearEffectEditorSaveFlagEvent>(_onClearSaveFlag);
    on<ClearEffectEditorSubmitErrorEvent>(_onClearSubmitError);
  }

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
      if (event.effectId != null) {
        final effect = await _getEffect(event.effectId!);
        final form = _formFromEntity(effect);
        emit(
          EffectEditorReady(
            effectId: effect.id,
            form: form,
            baseline: form,
            assetFileName:
                _assetFileNameFromUrl(effect.assetUrl) ?? effect.assetAsset,
          ),
        );
        return;
      }

      const form = EffectEditorFormData(
        slug: '',
        renderType: CameraEffectRenderTypeApi.none,
        label: '',
      );
      emit(const EffectEditorReady(form: form, baseline: form));
    } catch (e) {
      emit(EffectEditorError(formatFeApiError(e)));
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
      renderType: event.renderType,
      label: event.label,
      labelKey: event.labelKey,
      emoji: event.emoji,
      thumbnailUrl: event.thumbnailUrl,
      previewColorHex: event.previewColorHex,
      assetUrl: event.assetUrl,
      assetAsset: event.assetAsset,
      distortionPreset: event.distortionPreset,
      isActive: event.isActive,
      sortOrder: event.sortOrder,
      clearLabelKey: event.clearLabelKey,
      clearEmoji: event.clearEmoji,
      clearThumbnailUrl: event.clearThumbnailUrl,
      clearPreviewColorHex: event.clearPreviewColorHex,
      clearAssetUrl: event.clearAssetUrl,
      clearAssetAsset: event.clearAssetAsset,
      clearDistortionPreset: event.clearDistortionPreset,
    );
    if (event.renderType != null) {
      final type = CameraEffectRenderTypeApi.fromResponse(event.renderType!);
      form = form.copyWith(renderType: type);
      form = _normalizeFormForRenderType(form);
      if (CameraEffectRenderTypeApi.isSticker(type) && form.anchor.isEmpty) {
        form = form.copyWith(anchor: EffectAnchorFormData.glassesPreset);
      }
    }
    emit(current.copyWith(form: form, clearFieldErrors: true));
  }

  void _onAnchorChanged(
    EffectAnchorChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(anchor: event.anchor),
        clearFieldErrors: true,
      ),
    );
  }

  void _onStickersChanged(
    EffectStickersChanged event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(
      current.copyWith(
        form: current.form.copyWith(stickers: event.stickers),
        clearFieldErrors: true,
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
          fieldErrors: {'assetUrl': formatFeApiError(e)},
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

  void _onResetEditor(
    ResetEffectEditorEvent event,
    Emitter<EffectEditorState> emit,
  ) {
    final current = state;
    if (current is! EffectEditorReady) return;
    emit(current.copyWith(form: current.baseline, clearFieldErrors: true));
  }

  Future<void> _onSubmit(
    SubmitEffectEditorEvent event,
    Emitter<EffectEditorState> emit,
  ) async {
    final current = state;
    if (current is! EffectEditorReady ||
        current.isSaving ||
        current.isUploadingAsset) {
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
        await _updateEffect(current.effectId!, _buildUpdateRequest(current));
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
      renderType: CameraEffectRenderTypeApi.fromResponse(effect.renderType),
      label: effect.label,
      labelKey: effect.labelKey,
      emoji: emoji,
      thumbnailUrl: effect.thumbnailUrl,
      previewColorHex: effect.previewColorHex,
      assetUrl: assetUrl,
      assetAsset: effect.assetAsset,
      anchor: EffectAnchorFormData.fromMap(effect.anchor),
      stickers: effect.stickers,
      distortionPreset: effect.distortionPreset,
      isActive: effect.isActive,
      sortOrder: effect.sortOrder,
    );
  }

  Map<String, String> _validate(EffectEditorFormData form) {
    final errors = <String, String>{};
    final slug = form.slug.trim();
    final label = form.label.trim();
    if (slug.isEmpty) {
      errors['slug'] = 'feRequired';
    } else if (slug.length > 50) {
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
    final emojiText = FeEffectEmojiDisplay.textEmoji(form.emoji);
    if (emojiText != null && emojiText.length > 16) {
      errors['emoji'] = 'feEmojiTooLong';
    }
    final hex = form.previewColorHex?.trim();
    if (hex != null && hex.isNotEmpty) {
      if (hex.length > 7 || !isValidFePreviewHex(hex)) {
        errors['previewColorHex'] = 'feInvalidHex';
      }
    }

    if (CameraEffectRenderTypeApi.isSticker(form.renderType)) {
      final hasAsset =
          (form.assetUrl?.trim().isNotEmpty ?? false) ||
          (form.assetAsset?.trim().isNotEmpty ?? false);
      if (!hasAsset) errors['asset'] = 'feEffectAssetRequired';
      errors.addAll(_anchorFieldErrors(form.anchor, prefix: 'anchor'));
    } else if (CameraEffectRenderTypeApi.isComposite(form.renderType)) {
      if (form.stickers.isEmpty) {
        errors['stickers'] = 'feEffectStickersRequired';
      } else {
        for (var i = 0; i < form.stickers.length; i++) {
          final layer = form.stickers[i];
          if (!layer.hasAsset) {
            errors['stickers'] = 'feEffectStickerLayerInvalid';
            break;
          }
          if (layer.anchor.isEmpty) {
            errors['stickers'] = 'feEffectStickerLayerInvalid';
            break;
          }
          final layerAnchor = EffectAnchorFormData.fromMap(layer.anchor);
          if (layerAnchor.hasInvalidNumbers) {
            errors['stickers'] = 'feEffectAnchorNumbersInvalid';
            break;
          }
        }
      }
    } else if (CameraEffectRenderTypeApi.isDistortion(form.renderType)) {
      final preset = form.distortionPreset?.trim() ?? '';
      if (preset.isEmpty ||
          !CameraDistortionPresetApi.values.contains(
            CameraDistortionPresetApi.fromResponse(preset),
          )) {
        errors['distortionPreset'] = 'feDistortionPresetRequired';
      }
    }

    final assetUrl = form.assetUrl?.trim();
    if (assetUrl != null && assetUrl.isNotEmpty) {
      final uri = Uri.tryParse(assetUrl);
      if (uri == null || !uri.hasScheme) {
        errors['assetUrl'] = 'feInvalidUrl';
      }
    }
    return errors;
  }

  CreateEffectRequest _buildCreateRequest(EffectEditorReady current) {
    final form = current.form;
    return CreateEffectRequest(
      slug: form.slug.trim(),
      renderType: form.renderType,
      label: form.label.trim(),
      labelKey: _nullableTrim(form.labelKey),
      emoji: _emojiForApi(form.emoji),
      thumbnailUrl: _nullableTrim(form.thumbnailUrl),
      previewColorHex: _nullableTrim(form.previewColorHex),
      assetUrl: CameraEffectRenderTypeApi.isSticker(form.renderType)
          ? _nullableTrim(form.assetUrl)
          : null,
      assetAsset: CameraEffectRenderTypeApi.isSticker(form.renderType)
          ? _nullableTrim(form.assetAsset)
          : null,
      anchor: CameraEffectRenderTypeApi.isSticker(form.renderType)
          ? form.anchor.toMap()
          : const {},
      stickers: CameraEffectRenderTypeApi.isComposite(form.renderType)
          ? form.stickers
          : const [],
      distortionPreset: CameraEffectRenderTypeApi.isDistortion(form.renderType)
          ? form.distortionPreset
          : null,
      sortOrder: form.sortOrder,
      isActive: form.isActive,
    );
  }

  UpdateEffectRequest _buildUpdateRequest(EffectEditorReady current) {
    final form = current.form;
    final baseline = current.baseline;
    final isSticker = CameraEffectRenderTypeApi.isSticker(form.renderType);
    final isComposite = CameraEffectRenderTypeApi.isComposite(form.renderType);
    final isDistortion = CameraEffectRenderTypeApi.isDistortion(form.renderType);
    final anchor = form.anchor.toMap();
    final baselineAnchor = baseline.anchor.toMap();
    final renderTypeChanged = !CameraEffectRenderTypeApi.matches(
      form.renderType,
      baseline.renderType,
    );

    return UpdateEffectRequest(
      slug: form.slug.trim() != baseline.slug ? form.slug.trim() : null,
      renderType: renderTypeChanged ? form.renderType : null,
      label: form.label.trim() != baseline.label ? form.label.trim() : null,
      labelKey: form.labelKey != baseline.labelKey ? form.labelKey : null,
      emoji: form.emoji != baseline.emoji ? _emojiForApi(form.emoji) : null,
      thumbnailUrl: form.thumbnailUrl != baseline.thumbnailUrl
          ? form.thumbnailUrl
          : null,
      previewColorHex: form.previewColorHex != baseline.previewColorHex
          ? form.previewColorHex
          : null,
      assetUrl: isSticker && form.assetUrl != baseline.assetUrl
          ? _nullableTrim(form.assetUrl)
          : null,
      assetAsset: isSticker && form.assetAsset != baseline.assetAsset
          ? _nullableTrim(form.assetAsset)
          : null,
      anchor: isSticker && !_mapEquals(anchor, baselineAnchor) ? anchor : null,
      stickers: isComposite && form.stickers != baseline.stickers
          ? form.stickers
          : null,
      distortionPreset:
          isDistortion && form.distortionPreset != baseline.distortionPreset
          ? form.distortionPreset
          : null,
      sortOrder: form.sortOrder != baseline.sortOrder ? form.sortOrder : null,
      isActive: form.isActive != baseline.isActive ? form.isActive : null,
      clearLabelKey:
          (form.labelKey == null || form.labelKey!.isEmpty) &&
          (baseline.labelKey?.isNotEmpty ?? false),
      clearEmoji:
          (form.emoji == null || form.emoji!.trim().isEmpty) &&
          (baseline.emoji?.trim().isNotEmpty ?? false),
      clearThumbnailUrl:
          (form.thumbnailUrl == null || form.thumbnailUrl!.isEmpty) &&
          (baseline.thumbnailUrl?.isNotEmpty ?? false),
      clearPreviewColorHex:
          (form.previewColorHex == null || form.previewColorHex!.isEmpty) &&
          (baseline.previewColorHex?.isNotEmpty ?? false),
      clearAssetUrl:
          isSticker &&
          (form.assetUrl == null || form.assetUrl!.trim().isEmpty) &&
          (baseline.assetUrl?.trim().isNotEmpty ?? false),
      clearAssetAsset:
          isSticker &&
          (form.assetAsset == null || form.assetAsset!.trim().isEmpty) &&
          (baseline.assetAsset?.trim().isNotEmpty ?? false),
      clearDistortionPreset:
          isDistortion &&
          (form.distortionPreset == null || form.distortionPreset!.isEmpty) &&
          (baseline.distortionPreset?.isNotEmpty ?? false),
    );
  }

  EffectEditorFormData _normalizeFormForRenderType(EffectEditorFormData form) {
    final type = form.renderType;
    if (CameraEffectRenderTypeApi.isSticker(type)) {
      return form.copyWith(
        stickers: const [],
        clearDistortionPreset: true,
      );
    }
    if (CameraEffectRenderTypeApi.isComposite(type)) {
      return form.copyWith(
        anchor: EffectAnchorFormData.empty,
        clearAssetUrl: true,
        clearAssetAsset: true,
        clearDistortionPreset: true,
      );
    }
    if (CameraEffectRenderTypeApi.isDistortion(type)) {
      return form.copyWith(
        anchor: EffectAnchorFormData.empty,
        stickers: const [],
        clearAssetUrl: true,
        clearAssetAsset: true,
      );
    }
    return form.copyWith(
      anchor: EffectAnchorFormData.empty,
      stickers: const [],
      clearAssetUrl: true,
      clearAssetAsset: true,
      clearDistortionPreset: true,
    );
  }

  Map<String, String> _anchorFieldErrors(
    EffectAnchorFormData anchor, {
    required String prefix,
  }) {
    final errors = <String, String>{};
    if (anchor.hasInvalidNumbers) {
      errors[prefix] = 'feEffectAnchorNumbersInvalid';
      return errors;
    }
    if (anchor.isEmpty) {
      errors[prefix] = 'feEffectAnchorRequired';
    }
    return errors;
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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
    void consider(String text) {
      final lower = text.toLowerCase();
      if (lower.contains('slug')) errors['slug'] = text;
      if (lower.contains('label')) errors['label'] = text;
      if (lower.contains('anchor')) errors['anchor'] = text;
      if (lower.contains('sticker')) errors['stickers'] = text;
      if (lower.contains('distortion')) errors['distortionPreset'] = text;
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
