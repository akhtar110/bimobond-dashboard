import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../data/models/ar_overlay_models.dart';
import '../../domain/entities/ar_overlay_entities.dart';
import '../utils/ar_overlay_asset_kind.dart';
import '../utils/ar_overlay_picker.dart';
import '../utils/ar_overlay_lottie_cache.dart';

/// UI + upload state for create/edit AR overlay dialog.
class ArOverlayFormState extends Equatable {
  const ArOverlayFormState({
    required this.isEdit,
    this.overlayId,
    this.isUploadingLottie = false,
    this.isUploadingThumbnail = false,
    this.lottieBytes,
    this.lottieFilename,
    this.thumbnailBytes,
    this.thumbnailFilename,
    this.businessRuleError,
    this.id = '',
    this.label = '',
    this.sortOrderText = '0',
    this.lottieUrl = '',
    this.emoji = '',
    this.thumbnailUrl = '',
    this.previewColorHex = '#1E88E5',
    this.isActive = true,
    this.thumbnailSnackError,
    this.submitResult,
  });

  final bool isEdit;
  final String? overlayId;
  final bool isUploadingLottie;
  final bool isUploadingThumbnail;
  final Uint8List? lottieBytes;
  final String? lottieFilename;
  final Uint8List? thumbnailBytes;
  final String? thumbnailFilename;
  final String? businessRuleError;

  final String id;
  final String label;
  final String sortOrderText;
  final String lottieUrl;
  final String emoji;
  final String thumbnailUrl;
  final String previewColorHex;
  final bool isActive;

  /// One-shot snackbar for thumbnail upload failures.
  final String? thumbnailSnackError;

  /// Pop dialog with create/update DTO when non-null.
  final Object? submitResult;

  bool get canPreviewOverlay {
    if (lottieBytes != null && lottieBytes!.isNotEmpty) return true;
    return ArOverlayFormCubit.isRemoteAssetUrl(lottieUrl);
  }

  bool get isBusy => isUploadingLottie || isUploadingThumbnail;

  ArOverlayEntity get draftOverlay {
    final trimmedLabel = label.trim().isEmpty ? 'Overlay preview' : label.trim();
    final generatedId = trimmedLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final resolvedId = isEdit
        ? (overlayId ?? generatedId)
        : (id.trim().isNotEmpty ? id.trim() : generatedId);
    final emojiTrim = emoji.trim();
    final thumbTrim = thumbnailUrl.trim();
    final colorTrim = previewColorHex.trim();
    return ArOverlayEntity(
      id: resolvedId,
      label: trimmedLabel,
      sortOrder: int.tryParse(sortOrderText.trim()) ?? 0,
      lottieUrl: lottieUrl.trim(),
      emoji: emojiTrim.isEmpty ? null : emojiTrim,
      thumbnailUrl: thumbTrim.isEmpty ? null : thumbTrim,
      previewColorHex: colorTrim.isEmpty ? null : colorTrim,
      isActive: isActive,
    );
  }

  ArOverlayFormState copyWith({
    bool? isUploadingLottie,
    bool? isUploadingThumbnail,
    Uint8List? lottieBytes,
    String? lottieFilename,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
    String? businessRuleError,
    String? id,
    String? label,
    String? sortOrderText,
    String? lottieUrl,
    String? emoji,
    String? thumbnailUrl,
    String? previewColorHex,
    bool? isActive,
    String? thumbnailSnackError,
    Object? submitResult,
    bool clearLottieBytes = false,
    bool clearLottieFilename = false,
    bool clearThumbnailBytes = false,
    bool clearThumbnailFilename = false,
    bool clearBusinessRuleError = false,
    bool clearThumbnailSnackError = false,
    bool clearSubmitResult = false,
  }) {
    return ArOverlayFormState(
      isEdit: isEdit,
      overlayId: overlayId,
      isUploadingLottie: isUploadingLottie ?? this.isUploadingLottie,
      isUploadingThumbnail: isUploadingThumbnail ?? this.isUploadingThumbnail,
      lottieBytes: clearLottieBytes ? null : (lottieBytes ?? this.lottieBytes),
      lottieFilename:
          clearLottieFilename ? null : (lottieFilename ?? this.lottieFilename),
      thumbnailBytes:
          clearThumbnailBytes ? null : (thumbnailBytes ?? this.thumbnailBytes),
      thumbnailFilename: clearThumbnailFilename
          ? null
          : (thumbnailFilename ?? this.thumbnailFilename),
      businessRuleError: clearBusinessRuleError
          ? null
          : (businessRuleError ?? this.businessRuleError),
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrderText: sortOrderText ?? this.sortOrderText,
      lottieUrl: lottieUrl ?? this.lottieUrl,
      emoji: emoji ?? this.emoji,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewColorHex: previewColorHex ?? this.previewColorHex,
      isActive: isActive ?? this.isActive,
      thumbnailSnackError: clearThumbnailSnackError
          ? null
          : (thumbnailSnackError ?? this.thumbnailSnackError),
      submitResult:
          clearSubmitResult ? null : (submitResult ?? this.submitResult),
    );
  }

  @override
  List<Object?> get props => [
        isEdit,
        overlayId,
        isUploadingLottie,
        isUploadingThumbnail,
        lottieBytes,
        lottieFilename,
        thumbnailBytes,
        thumbnailFilename,
        businessRuleError,
        id,
        label,
        sortOrderText,
        lottieUrl,
        emoji,
        thumbnailUrl,
        previewColorHex,
        isActive,
        thumbnailSnackError,
        submitResult,
      ];
}

class ArOverlayFormCubit extends Cubit<ArOverlayFormState> {
  ArOverlayFormCubit({
    required Dio dio,
    ArOverlayEntity? overlay,
  })  : _dio = dio,
        super(
          ArOverlayFormState(
            isEdit: overlay != null,
            overlayId: overlay?.id,
            id: overlay?.id ?? '',
            label: overlay?.label ?? '',
            sortOrderText: (overlay?.sortOrder ?? 0).toString(),
            lottieUrl: overlay?.lottieUrl ?? '',
            emoji: overlay?.emoji ?? '',
            thumbnailUrl: overlay?.thumbnailUrl ?? '',
            previewColorHex: overlay?.previewColorHex ?? '#1E88E5',
            isActive: overlay?.isActive ?? true,
          ),
        );

  final Dio _dio;

  void syncField({
    String? id,
    String? label,
    String? sortOrderText,
    String? lottieUrl,
    String? emoji,
    String? thumbnailUrl,
    String? previewColorHex,
  }) {
    final next = state.copyWith(
      id: id,
      label: label,
      sortOrderText: sortOrderText,
      lottieUrl: lottieUrl,
      emoji: emoji,
      thumbnailUrl: thumbnailUrl,
      previewColorHex: previewColorHex,
      clearBusinessRuleError: true,
    );
    if (next == state) return;
    emit(next);
  }

  void clearBusinessRuleError() {
    if (state.businessRuleError == null) return;
    emit(state.copyWith(clearBusinessRuleError: true));
  }

  void clearThumbnailSnackError() {
    if (state.thumbnailSnackError == null) return;
    emit(state.copyWith(clearThumbnailSnackError: true));
  }

  void clearSubmitResult() {
    if (state.submitResult == null) return;
    emit(state.copyWith(clearSubmitResult: true));
  }

  /// Attaches a Lottie JSON or MP4 video animation asset and uploads it.
  Future<void> attachOverlayAsset() async {
    final res = await pickArOverlayAnimationFile();
    if (res == null || isClosed) return;

    final kind = resolveArOverlayAssetKind(
      nameOrUrl: res.name,
      bytes: res.bytes,
    );
    if (kind == null) {
      emit(
        state.copyWith(
          businessRuleError:
              'Only a Lottie JSON (.json) or MP4 video (.mp4) file is accepted for overlays.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isUploadingLottie: true,
        clearBusinessRuleError: true,
        lottieBytes: res.bytes,
        lottieFilename: res.name,
      ),
    );

    try {
      final uploadName = kind == ArOverlayAssetKind.lottie
          ? _normalizeUploadFilename(res.name, json: true)
          : _normalizeUploadFilename(res.name, json: false, video: true);
      final uploadedUrl = await _uploadFile(res.bytes, uploadName);
      if (isClosed) return;
      ArOverlayLottieCache.putBytes(uploadedUrl, res.bytes);
      emit(
        state.copyWith(
          isUploadingLottie: false,
          lottieUrl: uploadedUrl,
          lottieBytes: res.bytes,
          lottieFilename: res.name,
          clearBusinessRuleError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isUploadingLottie: false,
          clearLottieBytes: true,
          clearLottieFilename: true,
          businessRuleError:
              'Failed to upload overlay asset: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  /// Kept for call-site compatibility; prefers [attachOverlayAsset].
  Future<void> attachLottieJson() => attachOverlayAsset();

  Future<void> attachThumbnailImage() async {
    final res = await pickArOverlayImageFile();
    if (res == null || isClosed) return;

    emit(
      state.copyWith(
        isUploadingThumbnail: true,
        clearBusinessRuleError: true,
        thumbnailBytes: res.bytes,
        thumbnailFilename: res.name,
        clearThumbnailSnackError: true,
      ),
    );

    try {
      final uploadedUrl = await _uploadFile(res.bytes, res.name);
      if (isClosed) return;
      emit(
        state.copyWith(
          isUploadingThumbnail: false,
          thumbnailUrl: uploadedUrl,
          clearThumbnailBytes: true,
          clearThumbnailFilename: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isUploadingThumbnail: false,
          clearThumbnailBytes: true,
          clearThumbnailFilename: true,
          thumbnailSnackError:
              'Failed to upload thumbnail: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  /// Validates and builds create/update payload. Controllers must be synced
  /// into [state] first via [syncField].
  Future<void> submit() async {
    emit(state.copyWith(clearBusinessRuleError: true, clearSubmitResult: true));
    if (state.isBusy) return;

    final label = state.label.trim();
    final generatedId = label.isNotEmpty
        ? label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        : 'overlay_${DateTime.now().millisecondsSinceEpoch}';
    final id = state.isEdit
        ? state.overlayId!
        : (state.id.trim().isNotEmpty ? state.id.trim() : generatedId);
    final sortOrder = int.tryParse(state.sortOrderText.trim()) ?? 0;
    var lottieUrl = state.lottieUrl.trim();
    final emoji = state.emoji.trim();
    var thumbnailUrl = state.thumbnailUrl.trim();
    final previewColorHex = state.previewColorHex.trim();

    try {
      if (!isRemoteAssetUrl(lottieUrl)) {
        if (state.lottieBytes == null || state.lottieBytes!.isEmpty) {
          emit(
            state.copyWith(
              businessRuleError:
                  'Overlay animation must be uploaded to a CDN URL. Attach a .json/.mp4 file or paste an http(s) /uploads URL.',
            ),
          );
          return;
        }
        emit(state.copyWith(isUploadingLottie: true));
        final uploaded = await _uploadFile(
          state.lottieBytes!,
          state.lottieFilename ?? 'overlay.json',
        );
        if (isClosed) return;
        lottieUrl = uploaded;
        emit(
          state.copyWith(
            isUploadingLottie: false,
            lottieUrl: uploaded,
            clearLottieBytes: true,
          ),
        );
      }

      if (thumbnailUrl.isNotEmpty && !isRemoteAssetUrl(thumbnailUrl)) {
        if (state.thumbnailBytes == null || state.thumbnailBytes!.isEmpty) {
          emit(
            state.copyWith(
              businessRuleError:
                  'Thumbnail must be a CDN URL. Attach an image or clear the field.',
            ),
          );
          return;
        }
        emit(state.copyWith(isUploadingThumbnail: true));
        final uploaded = await _uploadFile(
          state.thumbnailBytes!,
          state.thumbnailFilename ?? 'thumbnail.png',
        );
        if (isClosed) return;
        thumbnailUrl = uploaded;
        emit(
          state.copyWith(
            isUploadingThumbnail: false,
            thumbnailUrl: uploaded,
            clearThumbnailBytes: true,
          ),
        );
      } else if (thumbnailUrl.isEmpty &&
          state.thumbnailBytes != null &&
          state.thumbnailBytes!.isNotEmpty) {
        emit(state.copyWith(isUploadingThumbnail: true));
        final uploaded = await _uploadFile(
          state.thumbnailBytes!,
          state.thumbnailFilename ?? 'thumbnail.png',
        );
        if (isClosed) return;
        thumbnailUrl = uploaded;
        emit(
          state.copyWith(
            isUploadingThumbnail: false,
            thumbnailUrl: uploaded,
            clearThumbnailBytes: true,
          ),
        );
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isUploadingLottie: false,
          isUploadingThumbnail: false,
          businessRuleError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return;
    }

    if (emoji.isEmpty && thumbnailUrl.isEmpty) {
      emit(
        state.copyWith(
          businessRuleError:
              'Business Rule Error: At least one of Emoji or Thumbnail URL/Image must be provided.',
        ),
      );
      return;
    }

    if (state.isEdit) {
      emit(
        state.copyWith(
          submitResult: UpdateArOverlayData(
            label: label,
            sortOrder: sortOrder,
            lottieUrl: lottieUrl,
            emoji: emoji,
            thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
            previewColorHex: previewColorHex,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          submitResult: CreateArOverlayData(
            id: id,
            label: label,
            sortOrder: sortOrder,
            lottieUrl: lottieUrl,
            emoji: emoji.isEmpty ? null : emoji,
            thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
            previewColorHex: previewColorHex.isEmpty ? null : previewColorHex,
          ),
        ),
      );
    }
  }

  static bool isRemoteAssetUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('data:')) return false;
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return false;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('/uploads/') ||
        lower.contains('/uploads/') ||
        lower.startsWith('uploads/');
  }

  static bool _looksLikeJsonAsset(String filename, Uint8List bytes) {
    return resolveArOverlayAssetKind(nameOrUrl: filename, bytes: bytes) ==
        ArOverlayAssetKind.lottie;
  }

  static bool _looksLikeVideoAsset(String filename, Uint8List bytes) {
    return resolveArOverlayAssetKind(nameOrUrl: filename, bytes: bytes) ==
        ArOverlayAssetKind.video;
  }

  static String _normalizeUploadFilename(
    String filename, {
    required bool json,
    bool video = false,
  }) {
    final cleaned = filename.trim().isEmpty
        ? (json
            ? 'overlay.json'
            : video
                ? 'overlay.mp4'
                : 'file.bin')
        : filename.trim();
    if (json && !cleaned.toLowerCase().endsWith('.json')) {
      return '$cleaned.json';
    }
    if (video && !cleaned.toLowerCase().endsWith('.mp4')) {
      return '$cleaned.mp4';
    }
    return cleaned;
  }

  static String _jsonUploadMediaFilename(String originalName) {
    final base = originalName
        .trim()
        .replaceAll(RegExp(r'\.(json|lottie)$', caseSensitive: false), '');
    final safe = base.isEmpty
        ? 'overlay-lottie'
        : base.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return '$safe.mp4';
  }

  static String? _parseUploadUrlEntry(dynamic entry) {
    if (entry is String && entry.trim().isNotEmpty) {
      final value = entry.trim();
      if (value.startsWith('data:') ||
          value.startsWith('{') ||
          value.startsWith('[')) {
        return null;
      }
      return value;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      for (final key in ['url', 'path', 'location', 'fileUrl', 'src']) {
        final parsed = _parseUploadUrlEntry(map[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _extractUrlFromResponse(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      return _parseUploadUrlEntry(data);
    }

    if (data is List && data.isNotEmpty) {
      for (final item in data) {
        final parsed = _parseUploadUrlEntry(item);
        if (parsed != null) return parsed;
      }
      return null;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final topUrls = map['urls'];
      if (topUrls is List && topUrls.isNotEmpty) {
        for (final item in topUrls) {
          final parsed = _parseUploadUrlEntry(item);
          if (parsed != null) return parsed;
        }
      }

      final nested = map['data'];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final nestedUrls = nestedMap['urls'];
        if (nestedUrls is List && nestedUrls.isNotEmpty) {
          for (final item in nestedUrls) {
            final parsed = _parseUploadUrlEntry(item);
            if (parsed != null) return parsed;
          }
        }
        final nestedFiles = nestedMap['files'];
        if (nestedFiles is List && nestedFiles.isNotEmpty) {
          for (final item in nestedFiles) {
            final parsed = _parseUploadUrlEntry(item);
            if (parsed != null) return parsed;
          }
        }
        final fromNested = _extractUrlFromResponse(nestedMap);
        if (fromNested != null) return fromNested;
      } else if (nested is List && nested.isNotEmpty) {
        final fromNested = _extractUrlFromResponse(nested);
        if (fromNested != null) return fromNested;
      } else if (nested is String) {
        final parsed = _parseUploadUrlEntry(nested);
        if (parsed != null) return parsed;
      }

      final files = map['files'];
      if (files is List && files.isNotEmpty) {
        for (final item in files) {
          final parsed = _parseUploadUrlEntry(item);
          if (parsed != null) return parsed;
        }
      }

      return _parseUploadUrlEntry(
        map['url'] ?? map['path'] ?? map['location'] ?? map['fileUrl'],
      );
    }

    return null;
  }

  Future<String> _uploadFile(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw Exception('Selected file is empty');
    }

    final isJson = _looksLikeJsonAsset(filename, bytes);
    final isVideo = _looksLikeVideoAsset(filename, bytes);
    final originalName = _normalizeUploadFilename(
      filename,
      json: isJson,
      video: isVideo,
    );
    // `/posts/upload` rejects `.json`; disguise Lottie as video MIME.
    // Real MP4 uploads keep a true `.mp4` filename + video content-type.
    final uploadName =
        isJson ? _jsonUploadMediaFilename(originalName) : originalName;
    final contentType = (isJson || isVideo)
        ? DioMediaType('video', 'mp4')
        : null;

    if (kDebugMode) {
      debugPrint(
        '[ArOverlayFormCubit] Uploading '
        '${isJson ? 'Lottie JSON' : isVideo ? 'MP4 video' : 'image'} '
        '$originalName as $uploadName (${bytes.length} bytes) → /posts/upload',
      );
    }

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'files',
        MultipartFile.fromBytes(
          bytes,
          filename: uploadName,
          contentType: contentType,
        ),
      ),
    );

    final response = await _dio.post<dynamic>(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    if (kDebugMode) {
      debugPrint('[ArOverlayFormCubit] Upload response: ${response.data}');
    }

    final extracted = _extractUrlFromResponse(response.data);
    if (extracted == null || extracted.isEmpty) {
      throw Exception(
        'Upload succeeded but no CDN URL was returned: ${response.data}',
      );
    }

    final resolved = resolveMediaUrl(extracted) ?? extracted;
    if (!isRemoteAssetUrl(resolved)) {
      throw Exception('Upload returned an invalid URL: $resolved');
    }
    return resolved;
  }
}
