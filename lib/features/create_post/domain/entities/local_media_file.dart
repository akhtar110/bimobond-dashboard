import 'dart:typed_data';

import 'create_post_media_filter_entity.dart';

/// A file picked locally, optionally linked to an uploaded server URL.
class LocalMediaFile {
  const LocalMediaFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.mediaType,
    this.uploadedUrl,
    this.filter = CreatePostMediaFilterEntity.neutral,
    this.originalBytes,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  /// `IMAGE` or `VIDEO`
  final String mediaType;
  final String? uploadedUrl;
  final CreatePostMediaFilterEntity filter;

  /// Original bytes before filter processing (for reset).
  final Uint8List? originalBytes;

  bool get isUploaded => uploadedUrl != null && uploadedUrl!.isNotEmpty;

  bool get hasFilter => !filter.isNeutral;

  Uint8List get sourceBytes => originalBytes ?? bytes;

  LocalMediaFile copyWith({
    Uint8List? bytes,
    String? uploadedUrl,
    CreatePostMediaFilterEntity? filter,
    Uint8List? originalBytes,
    bool clearUploadedUrl = false,
    bool resetFilter = false,
  }) {
    return LocalMediaFile(
      id: id,
      name: name,
      bytes: resetFilter ? (originalBytes ?? this.bytes) : (bytes ?? this.bytes),
      mediaType: mediaType,
      uploadedUrl: clearUploadedUrl ? null : (uploadedUrl ?? this.uploadedUrl),
      filter: resetFilter
          ? CreatePostMediaFilterEntity.neutral
          : (filter ?? this.filter),
      originalBytes: resetFilter
          ? null
          : (originalBytes ?? this.originalBytes ?? this.bytes),
    );
  }

  static String inferMediaType(String filename) {
    final lower = filename.toLowerCase();
    const videoExt = ['.mp4', '.mov', '.webm', '.mkv', '.avi'];
    for (final ext in videoExt) {
      if (lower.endsWith(ext)) return 'VIDEO';
    }
    return 'IMAGE';
  }
}
