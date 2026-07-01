import 'dart:html' as html;
import 'dart:typed_data';

String? videoPreviewMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.mkv')) return 'video/x-matroska';
  if (lower.endsWith('.avi')) return 'video/x-msvideo';
  return 'video/mp4';
}

String? createVideoPreviewUri(Uint8List bytes, String fileName) {
  if (bytes.isEmpty) return null;
  final blob = html.Blob([bytes], videoPreviewMimeType(fileName));
  return html.Url.createObjectUrlFromBlob(blob);
}

void disposeVideoPreviewUri(String uri) {
  html.Url.revokeObjectUrl(uri);
}
