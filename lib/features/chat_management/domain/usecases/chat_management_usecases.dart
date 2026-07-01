import '../entities/chat_entities.dart';
import '../entities/chat_queries.dart';
import '../repositories/chat_management_repository.dart';

class GetAllChats {
  const GetAllChats(this.repository);
  final ChatManagementRepository repository;
  Future<ChatListPageEntity> call(ChatListQuery query) =>
      repository.getAllChats(query);
}

class GetChatById {
  const GetChatById(this.repository);
  final ChatManagementRepository repository;
  Future<ChatEntity> call(String id) => repository.getChatById(id);
}

class GetChatMessages {
  const GetChatMessages(this.repository);
  final ChatManagementRepository repository;
  Future<ChatMessagesPageEntity> call(String chatId, ChatMessagesQuery query) =>
      repository.getChatMessages(chatId, query);
}

class UpdateChat {
  const UpdateChat(this.repository);
  final ChatManagementRepository repository;
  Future<ChatEntity> call(String id, UpdateChatData data) =>
      repository.updateChat(id, data);
}

class DeleteChat {
  const DeleteChat(this.repository);
  final ChatManagementRepository repository;
  Future<void> call(String id) => repository.deleteChat(id);
}

class DeleteChatMessage {
  const DeleteChatMessage(this.repository);
  final ChatManagementRepository repository;
  Future<void> call(String messageId) => repository.deleteMessage(messageId);
}

class BulkChatModeration {
  const BulkChatModeration(this.repository);
  final ChatManagementRepository repository;
  Future<ChatBulkResultEntity> call({
    required ChatBulkAction action,
    List<String> chatIds = const [],
    List<String> messageIds = const [],
  }) =>
      repository.bulkAction(
        action: action,
        chatIds: chatIds,
        messageIds: messageIds,
      );
}
