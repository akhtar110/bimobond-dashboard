import 'package:dio/dio.dart';

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
  Future<ChatDeleteResultEntity> deleteChat(String id);
  Future<ChatMessageDeleteResultEntity> deleteMessage(String messageId);
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

  Map<String, dynamic>? _bodyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> body) {
    final nested = body['data'];
    if (nested is Map<String, dynamic>) return nested;
    return body;
  }

  @override
  Future<ChatListPageEntity> getAllChats(ChatListQuery query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/chats/admin/all',
      queryParameters: query.toQueryParameters(),
    );
    return parseChatListPage(response.data);
  }

  @override
  Future<ChatEntity> getChatById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/chats/admin/$id');
    final body = _bodyMap(response.data);
    if (body == null) throw Exception('Invalid chat response');
    return ChatModel.fromJson(_unwrapPayload(body));
  }

  @override
  Future<ChatMessagesPageEntity> getChatMessages(
    String chatId,
    ChatMessagesQuery query,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/chats/admin/$chatId/messages',
      queryParameters: query.toQueryParameters(),
    );
    return parseChatMessagesPage(response.data);
  }

  @override
  Future<ChatEntity> updateChat(String id, UpdateChatData data) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/chats/admin/$id',
      data: data.toJson(),
    );
    final body = _bodyMap(response.data);
    if (body == null) throw Exception('Invalid chat update response');
    return ChatModel.fromJson(_unwrapPayload(body));
  }

  @override
  Future<ChatDeleteResultEntity> deleteChat(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/chats/admin/$id',
    );
    final body = _bodyMap(response.data);
    if (body == null) throw Exception('Invalid delete chat response');
    return ChatDeleteResultModel.fromJson(body, fallbackChatId: id);
  }

  @override
  Future<ChatMessageDeleteResultEntity> deleteMessage(String messageId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/chats/admin/messages/$messageId',
    );
    final body = _bodyMap(response.data);
    if (body == null) throw Exception('Invalid delete message response');
    return ChatMessageDeleteResultModel.fromJson(
      body,
      fallbackMessageId: messageId,
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

    final response = await _dio.post<Map<String, dynamic>>(
      '/chats/admin/bulk',
      data: body,
    );
    final data = _bodyMap(response.data);
    if (data == null) throw Exception('Invalid bulk response');
    return ChatBulkResultModel.fromJson(data, action);
  }
}
