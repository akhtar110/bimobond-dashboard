import 'dart:typed_data';

/// A file picked locally, optionally linked to an uploaded server URL.
class LocalMediaFile {
  const LocalMediaFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.mediaType,
    this.uploadedUrl,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  /// `IMAGE` or `VIDEO`
  final String mediaType;
  final String? uploadedUrl;

  bool get isUploaded => uploadedUrl != null && uploadedUrl!.isNotEmpty;

  LocalMediaFile copyWith({String? uploadedUrl}) {
    return LocalMediaFile(
      id: id,
      name: name,
      bytes: bytes,
      mediaType: mediaType,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
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
