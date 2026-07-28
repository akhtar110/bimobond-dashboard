import 'package:dio/dio.dart';

/// Localization key shown when create/update hits a duplicate filter/effect.
const feFilterEffectAlreadyExistsKey = 'feFilterEffectAlreadyExists';

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

/// True when the backend reports a duplicate filter/effect (name/slug).
bool isFeDuplicateConflict(Object error) {
  final raw = _feErrorMessageText(error).toLowerCase();
  final looksLikeDuplicate = raw.contains('already exist') ||
      raw.contains('duplicate') ||
      raw.contains('unique constraint') ||
      raw.contains('unique_violation') ||
      raw.contains('e11000') || // Mongo duplicate key
      ((raw.contains('name') ||
              raw.contains('slug') ||
              raw.contains('label') ||
              raw.contains('filter') ||
              raw.contains('effect')) &&
          (raw.contains('exist') ||
              raw.contains('taken') ||
              raw.contains('in use') ||
              raw.contains('conflict')));

  if (error is DioException) {
    final code = error.response?.statusCode;
    final data = error.response?.data;
    final bodyCode = data is Map ? data['statusCode'] : null;
    if (code == 409 || bodyCode == 409) return true;
    if ((code == 400 || code == 422 || bodyCode == 400 || bodyCode == 422) &&
        looksLikeDuplicate) {
      return true;
    }
  }

  return looksLikeDuplicate;
}

String _feErrorMessageText(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List) {
        return message.map((e) => e.toString()).join(' ');
      }
      final err = data['error'];
      if (err is String && err.trim().isNotEmpty) return err;
    }
    return error.message ?? error.toString();
  }
  return error.toString();
}
