import 'package:dio/dio.dart';

/// Shared helpers for mapping backend error responses to user-facing text.
class ApiErrorMessages {
  ApiErrorMessages._();

  static String from(Object error) {
    if (error is DioException) {
      final message = _extractMessage(error.response?.data);
      if (message != null && message.isNotEmpty) return message;
      return error.message ?? error.toString();
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  static bool isForbidden(Object error) =>
      error is DioException && error.response?.statusCode == 403;

  static String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      return message.map((e) => e.toString()).join(', ');
    }
    return null;
  }
}
