import '../entities/chat_entities.dart';
import '../entities/chat_queries.dart';

abstract class ChatManagementRepository {
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
