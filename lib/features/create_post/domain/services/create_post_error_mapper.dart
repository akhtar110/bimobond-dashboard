import 'package:dio/dio.dart';

class CreatePostErrorMapper {
  const CreatePostErrorMapper._();

  static String map(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List) {
          return message.map((m) => m.toString()).join('\n');
        }
        if (message is String && message.isNotEmpty) {
          return message;
        }
        final err = data['error'];
        if (err is String && err.isNotEmpty) {
          return err;
        }
      }
      return error.message ?? error.toString();
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
