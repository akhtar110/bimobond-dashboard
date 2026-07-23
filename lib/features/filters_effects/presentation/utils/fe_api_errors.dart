import 'package:dio/dio.dart';

/// Maps camera-studio admin API failures to localization keys or server text.
String formatFeApiError(
  Object error, {
  String conflictKey = 'feSlugAlreadyExists',
}) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is List) {
        return message.map((e) => e.toString()).join('\n');
      }
    }
    return switch (status) {
      400 => 'feValidationFailed',
      401 => 'feUnauthorized',
      403 => 'feCameraStudioPermissionDenied',
      404 => 'feResourceNotFound',
      409 => conflictKey,
      _ => error.message ?? 'Request failed',
    };
  }
  return error.toString();
}
