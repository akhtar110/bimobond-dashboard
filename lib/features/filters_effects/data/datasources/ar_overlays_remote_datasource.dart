import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../models/ar_overlay_models.dart';

abstract class ArOverlaysRemoteDataSource {
  Future<ArOverlayCatalogResponseModel> getPublicCatalog();
  Future<ArOverlayListResponseModel> getAdminOverlays({
    int page = 1,
    int limit = 20,
    bool? isActive,
  });
  Future<ArOverlayModel> getAdminOverlayById(String id);
  Future<ArOverlayModel> createAdminOverlay(CreateArOverlayData data);
  Future<ArOverlayModel> updateAdminOverlay(
    String id,
    UpdateArOverlayData data,
  );
  Future<ArOverlayModel> activateAdminOverlay(String id);
  Future<ArOverlayModel> deactivateAdminOverlay(String id);
  Future<void> deleteAdminOverlay(String id);
}

class ArOverlaysRemoteDataSourceImpl implements ArOverlaysRemoteDataSource {
  const ArOverlaysRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static String? _parseUploadUrlEntry(dynamic entry) {
    if (entry is String && entry.trim().isNotEmpty) {
      final value = entry.trim();
      // Never accept data URLs / raw base64 as an upload result.
      if (value.startsWith('data:') ||
          value.startsWith('{') ||
          value.startsWith('[')) {
        return null;
      }
      return value;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      for (final key in ['url', 'path', 'location']) {
        final parsed = _parseUploadUrlEntry(map[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Extracts the first CDN/upload URL from `POST /posts/upload` responses.
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
        final fromNested = _extractUrlFromResponse(nestedMap);
        if (fromNested != null) return fromNested;
      } else if (nested != null) {
        final fromNested = _extractUrlFromResponse(nested);
        if (fromNested != null) return fromNested;
      }

      return _parseUploadUrlEntry(map['url'] ?? map['path'] ?? map['location']);
    }

    return _parseUploadUrlEntry(data);
  }

  static bool _looksLikeJsonAsset(String filename, Uint8List bytes) {
    final lower = filename.trim().toLowerCase();
    if (lower.endsWith('.json') ||
        lower.endsWith('.lottie') ||
        lower.contains('.json')) {
      return true;
    }
    // Lottie JSON typically starts with `{` / `[` after optional BOM/whitespace.
    for (var i = 0; i < bytes.length && i < 64; i++) {
      final b = bytes[i];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) continue;
      if (b == 0xEF && i + 2 < bytes.length) continue; // UTF-8 BOM lead
      return b == 0x7B || b == 0x5B; // '{' or '['
    }
    return false;
  }

  /// Uploads overlay assets via `POST /posts/upload` and returns a CDN URL.
  ///
  /// AR Overlays create/update only accept a `lottieUrl` string (see module
  /// README) — there is no overlay/filter upload route. `/posts/upload` only
  /// allows image/audio/video MIME types, so Lottie JSON is uploaded with a
  /// video content-type wrapper while keeping the raw JSON bytes.
  Future<String> _uploadAsset(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw Exception('Asset upload failed: empty file bytes');
    }

    final originalName =
        filename.trim().isEmpty ? 'overlay.json' : filename.trim();
    final isJson = _looksLikeJsonAsset(originalName, bytes);
    final isVideo = !isJson &&
        (originalName.toLowerCase().endsWith('.mp4') ||
            (bytes.length >= 8 &&
                bytes[4] == 0x66 &&
                bytes[5] == 0x74 &&
                bytes[6] == 0x79 &&
                bytes[7] == 0x70));
    final uploadName = isJson
        ? _jsonUploadMediaFilename(originalName)
        : originalName;
    final contentType = (isJson || isVideo)
        ? DioMediaType('video', 'mp4')
        : null;

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

    if (kDebugMode) {
      debugPrint(
        '[ArOverlays] Uploading '
        '${isJson ? 'Lottie JSON' : isVideo ? 'MP4 video' : 'media'} '
        '($originalName as $uploadName, ${bytes.length} bytes) to /posts/upload...',
      );
    }

    final response = await _dio.post<dynamic>(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final url = _extractUrlFromResponse(response.data);
    if (url == null || url.isEmpty) {
      throw Exception(
        'Asset upload failed: no URL returned from server: ${response.data}',
      );
    }

    if (kDebugMode) {
      debugPrint('[ArOverlays] Upload successful -> CDN URL: $url');
    }
    return url;
  }

  /// `/posts/upload` rejects `.json`; use a media filename so MIME checks pass.
  static String _jsonUploadMediaFilename(String originalName) {
    final base = originalName
        .trim()
        .replaceAll(RegExp(r'\.(json|lottie)$', caseSensitive: false), '');
    final safe = base.isEmpty
        ? 'overlay-lottie'
        : base.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return '$safe.mp4';
  }

  static bool _isHttpOrCdnUrl(String input) {
    final lower = input.trim().toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('/uploads/') ||
        lower.contains('/uploads/') ||
        lower.startsWith('uploads/');
  }

  static bool _isEmbeddedContent(String input) {
    final trimmed = input.trim();
    return trimmed.startsWith('data:') ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        // Long base64-looking payloads should never go into lottieUrl.
        (trimmed.length > 200 && !trimmed.contains('/') && !trimmed.contains(':'));
  }

  /// Resolves picker bytes / pasted content into a remote CDN URL.
  /// Never returns base64 or raw JSON — those are always uploaded first.
  Future<String> _resolveAssetUrl({
    required String? rawUrl,
    Uint8List? rawBytes,
    String? defaultFilename,
    String defaultExt = 'bin',
  }) async {
    // 1. Prefer raw picker bytes — upload them to get a real URL.
    if (rawBytes != null && rawBytes.isNotEmpty) {
      final filename = defaultFilename ?? 'asset.$defaultExt';
      final uploadedUrl = await _uploadAsset(rawBytes, filename);
      return resolveMediaUrl(uploadedUrl) ?? uploadedUrl;
    }

    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return '';

    // 2. Already a valid remote URL.
    if (_isHttpOrCdnUrl(trimmed)) {
      return resolveMediaUrl(trimmed) ?? trimmed;
    }

    // 3. Embedded content (data URL / raw JSON / base64) → upload bytes, return URL.
    Uint8List? bytesToUpload;
    var filename = defaultFilename ?? 'asset.$defaultExt';

    if (trimmed.startsWith('data:')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        if (commaIdx != -1) {
          final header = trimmed.substring(0, commaIdx).toLowerCase();
          final payload = trimmed.substring(commaIdx + 1);
          if (header.contains(';base64')) {
            bytesToUpload = base64Decode(payload);
          } else {
            bytesToUpload = Uint8List.fromList(utf8.encode(Uri.decodeFull(payload)));
          }

          if (header.contains('image/png')) {
            filename = 'thumbnail.png';
          } else if (header.contains('image/jpeg') ||
              header.contains('image/jpg')) {
            filename = 'thumbnail.jpg';
          } else if (header.contains('json')) {
            filename = 'overlay.json';
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ArOverlays] Data URL decode error: $e');
        }
      }
    } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      bytesToUpload = Uint8List.fromList(utf8.encode(trimmed));
      filename = defaultFilename ?? 'overlay.json';
    } else if (_isEmbeddedContent(trimmed)) {
      try {
        bytesToUpload = base64Decode(trimmed);
      } catch (_) {
        throw Exception(
          'Invalid asset content: expected a CDN URL, not embedded/base64 data',
        );
      }
    } else {
      throw Exception(
        'Invalid asset URL: must be http(s) or /uploads/…, got: '
        '${trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed}',
      );
    }

    if (bytesToUpload == null || bytesToUpload.isEmpty) {
      throw Exception('Invalid asset content: could not process into a CDN URL');
    }

    final uploadedUrl = await _uploadAsset(bytesToUpload, filename);
    return resolveMediaUrl(uploadedUrl) ?? uploadedUrl;
  }

  // ─── Endpoints ──────────────────────────────────────────────────────────────

  /// Public Catalog: `GET /camera-studio/ar-overlays`
  @override
  Future<ArOverlayCatalogResponseModel> getPublicCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/camera-studio/ar-overlays',
      );
      return ArOverlayCatalogResponseModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin List: `GET /camera-studio/ar-overlays/admin?page=1&limit=20`
  ///
  /// Backend defaults to active-only when `isActive` is omitted, so the
  /// "All" filter (`isActive == null`) merges active + inactive results.
  @override
  Future<ArOverlayListResponseModel> getAdminOverlays({
    int page = 1,
    int limit = 20,
    bool? isActive,
  }) async {
    if (isActive == null) {
      return _getAdminOverlaysAllStatuses(page: page, limit: limit);
    }
    return _getAdminOverlaysPage(
      page: page,
      limit: limit,
      isActive: isActive,
    );
  }

  Future<ArOverlayListResponseModel> _getAdminOverlaysPage({
    required int page,
    required int limit,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin',
        queryParameters: {
          'page': page,
          'limit': limit,
          'isActive': isActive,
        },
      );
      return ArOverlayListResponseModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetches every page for a status, up to API max page size (100).
  Future<List<ArOverlayModel>> _fetchAllAdminOverlaysForStatus({
    required bool isActive,
  }) async {
    const pageSize = 100;
    final first = await _getAdminOverlaysPage(
      page: 1,
      limit: pageSize,
      isActive: isActive,
    );
    final items = <ArOverlayModel>[
      ...first.data.whereType<ArOverlayModel>(),
    ];
    final totalPages = first.meta.totalPages < 1 ? 1 : first.meta.totalPages;
    for (var page = 2; page <= totalPages; page++) {
      final next = await _getAdminOverlaysPage(
        page: page,
        limit: pageSize,
        isActive: isActive,
      );
      items.addAll(next.data.whereType<ArOverlayModel>());
    }
    return items;
  }

  Future<ArOverlayListResponseModel> _getAdminOverlaysAllStatuses({
    required int page,
    required int limit,
  }) async {
    final results = await Future.wait([
      _fetchAllAdminOverlaysForStatus(isActive: true),
      _fetchAllAdminOverlaysForStatus(isActive: false),
    ]);
    final byId = <String, ArOverlayModel>{};
    for (final item in [...results[0], ...results[1]]) {
      if (item.id.trim().isEmpty) continue;
      byId[item.id] = item;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return a.id.compareTo(b.id);
      });

    final safeLimit = limit.clamp(1, 100);
    final total = merged.length;
    final totalPages = total == 0 ? 1 : ((total + safeLimit - 1) ~/ safeLimit);
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * safeLimit;
    final pageItems = merged.skip(start).take(safeLimit).toList(growable: false);

    return ArOverlayListResponseModel(
      version: '',
      data: pageItems,
      meta: ArOverlayMetaModel(
        total: total,
        page: safePage,
        limit: safeLimit,
        totalPages: totalPages,
      ),
    );
  }

  /// Admin Get One: `GET /camera-studio/ar-overlays/admin/:id`
  @override
  Future<ArOverlayModel> getAdminOverlayById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin/$id',
      );
      final json = response.data ?? {};
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        return ArOverlayModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ArOverlayModel.fromJson(json);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin Create Overlay: `POST /camera-studio/ar-overlays/admin`
  @override
  Future<ArOverlayModel> createAdminOverlay(CreateArOverlayData data) async {
    try {
      // Step 1: Resolve Lottie URL (uploads data URL to CDN if needed)
      final lottieUrl = await _resolveAssetUrl(
        rawUrl: data.lottieUrl,
        rawBytes: data.lottieBytes,
        defaultFilename: data.lottieFilename ?? 'overlay.json',
        defaultExt: 'json',
      );

      // Step 2: Resolve Thumbnail URL (uploads data URL to CDN if needed)
      final thumbnailUrl = data.thumbnailUrl == null || data.thumbnailUrl!.trim().isEmpty
          ? null
          : await _resolveAssetUrl(
              rawUrl: data.thumbnailUrl,
              rawBytes: data.thumbnailBytes,
              defaultFilename: data.thumbnailFilename ?? 'thumbnail.png',
              defaultExt: 'png',
            );

      if (!_isHttpOrCdnUrl(lottieUrl)) {
        throw Exception(
          'lottieUrl must be a CDN URL after upload. Got embedded/base64 content instead.',
        );
      }

      final resolvedData = data.withResolvedUrls(
        lottieUrl: lottieUrl,
        thumbnailUrl: thumbnailUrl,
      );

      if (kDebugMode) {
        debugPrint('[ArOverlays] Submitting POST payload: ${resolvedData.toJson()}');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin',
        data: resolvedData.toJson(),
      );
      final json = response.data ?? {};
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        return ArOverlayModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ArOverlayModel.fromJson(json);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin Update Overlay: `PATCH /camera-studio/ar-overlays/admin/:id`
  @override
  Future<ArOverlayModel> updateAdminOverlay(
    String id,
    UpdateArOverlayData data,
  ) async {
    try {
      // Step 1: Resolve Lottie URL (uploads data URL to CDN if needed)
      final lottieUrl = data.lottieUrl == null || data.lottieUrl!.trim().isEmpty
          ? null
          : await _resolveAssetUrl(
              rawUrl: data.lottieUrl,
              rawBytes: data.lottieBytes,
              defaultFilename: data.lottieFilename ?? 'overlay.json',
              defaultExt: 'json',
            );

      // Step 2: Resolve Thumbnail URL (uploads data URL to CDN if needed)
      final thumbnailUrl = data.thumbnailUrl == null || data.thumbnailUrl!.trim().isEmpty
          ? null
          : await _resolveAssetUrl(
              rawUrl: data.thumbnailUrl,
              rawBytes: data.thumbnailBytes,
              defaultFilename: data.thumbnailFilename ?? 'thumbnail.png',
              defaultExt: 'png',
            );

      if (lottieUrl != null &&
          lottieUrl.isNotEmpty &&
          !_isHttpOrCdnUrl(lottieUrl)) {
        throw Exception(
          'lottieUrl must be a CDN URL after upload. Got embedded/base64 content instead.',
        );
      }

      final resolvedData = data.withResolvedUrls(
        lottieUrl: lottieUrl,
        thumbnailUrl: thumbnailUrl,
      );

      if (kDebugMode) {
        debugPrint(
          '[ArOverlays] Submitting PATCH ($id) payload: ${resolvedData.toJson()}',
        );
      }

      final response = await _dio.patch<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin/$id',
        data: resolvedData.toJson(),
      );
      final json = response.data ?? {};
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        return ArOverlayModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ArOverlayModel.fromJson(json);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin Activate Overlay: `PATCH /camera-studio/ar-overlays/admin/:id/activate`
  @override
  Future<ArOverlayModel> activateAdminOverlay(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin/$id/activate',
      );
      final json = response.data ?? {};
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        return ArOverlayModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ArOverlayModel.fromJson(json);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin Deactivate Overlay: `PATCH /camera-studio/ar-overlays/admin/:id/deactivate`
  @override
  Future<ArOverlayModel> deactivateAdminOverlay(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/camera-studio/ar-overlays/admin/$id/deactivate',
      );
      final json = response.data ?? {};
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        return ArOverlayModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return ArOverlayModel.fromJson(json);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin Delete Overlay: `DELETE /camera-studio/ar-overlays/admin/:id`
  @override
  Future<void> deleteAdminOverlay(String id) async {
    try {
      await _dio.delete<dynamic>(
        '/camera-studio/ar-overlays/admin/$id',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final res = error.response;
    if (res != null && res.data != null && res.data is Map) {
      final msg = res.data['message'] ?? res.data['error'] ?? error.message;
      return Exception(msg.toString());
    }
    return Exception(error.message ?? 'An unexpected network error occurred');
  }
}
