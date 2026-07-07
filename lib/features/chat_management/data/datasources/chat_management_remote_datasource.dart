import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/chat_entities.dart';
import '../../domain/entities/chat_queries.dart';
import '../models/chat_models.dart';

abstract class ChatManagementRemoteDataSource {
  Future<ChatListPageEntity> getAllChats(ChatListQuery query);
  Future<ChatEntity> getChatById(String id);
  Future<ChatMessagesPageEntity> getChatMessages(
    String chatId,
    ChatMessagesQuery query,
  );
  Future<ChatEntity> updateChat(String id, UpdateChatData data);
  Future<void> deleteChat(String id);
  Future<void> deleteMessage(String messageId);
  Future<ChatBulkResultEntity> bulkAction({
    required ChatBulkAction action,
    List<String> chatIds = const [],
    List<String> messageIds = const [],
  });
}

class ChatManagementRemoteDataSourceImpl
    implements ChatManagementRemoteDataSource {
  ChatManagementRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  Future<Options> _authorizedOptions({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken =
        user != null ? await user.getIdToken(forceRefresh) : null;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Missing or invalid authorization header');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: await _authorizedOptions(forceRefresh: forceRefresh),
      );
    } on DioException catch (e) {
      if (!forceRefresh && e.response?.statusCode == 401) {
        return _get(
          path,
          queryParameters: queryParameters,
          forceRefresh: true,
        );
      }
      rethrow;
    }
  }

  @override
  Future<ChatListPageEntity> getAllChats(ChatListQuery query) async {
    final response = await _get(
      '/chats/admin/all',
      queryParameters: query.toQueryParameters(),
    );
    return parseChatListPage(response.data);
  }

  @override
  Future<ChatEntity> getChatById(String id) async {
    final response = await _get('/chats/admin/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return ChatModel.fromJson(payload);
    }
    throw Exception('Invalid chat response');
  }

  @override
  Future<ChatMessagesPageEntity> getChatMessages(
    String chatId,
    ChatMessagesQuery query,
  ) async {
    final response = await _get(
      '/chats/admin/$chatId/messages',
      queryParameters: query.toQueryParameters(),
    );
    return parseChatMessagesPage(response.data);
  }

  @override
  Future<ChatEntity> updateChat(String id, UpdateChatData data) async {
    final response = await _dio.patch(
      '/chats/admin/$id',
      data: data.toJson(),
      options: await _authorizedOptions(),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final payload = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return ChatModel.fromJson(payload);
    }
    throw Exception('Invalid chat update response');
  }

  @override
  Future<void> deleteChat(String id) async {
    await _dio.delete(
      '/chats/admin/$id',
      options: await _authorizedOptions(),
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _dio.delete(
      '/chats/admin/messages/$messageId',
      options: await _authorizedOptions(),
    );
  }

  @override
  Future<ChatBulkResultEntity> bulkAction({
    required ChatBulkAction action,
    List<String> chatIds = const [],
    List<String> messageIds = const [],
  }) async {
    final body = <String, dynamic>{
      'action': switch (action) {
        ChatBulkAction.deleteChats => 'DELETE_CHATS',
        ChatBulkAction.deleteMessages => 'DELETE_MESSAGES',
      },
    };
    if (chatIds.isNotEmpty) body['chatIds'] = chatIds;
    if (messageIds.isNotEmpty) body['messageIds'] = messageIds;

    final response = await _dio.post(
      '/chats/admin/bulk',
      data: body,
      options: await _authorizedOptions(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ChatBulkResultModel.fromJson(data, action);
    }
    throw Exception('Invalid bulk response');
  }
}
