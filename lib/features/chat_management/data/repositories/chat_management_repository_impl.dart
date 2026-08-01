import '../../domain/entities/chat_entities.dart';
import '../../domain/entities/chat_queries.dart';
import '../../domain/repositories/chat_management_repository.dart';
import '../datasources/chat_management_remote_datasource.dart';

class ChatManagementRepositoryImpl implements ChatManagementRepository {
  const ChatManagementRepositoryImpl(this.remoteDataSource);

  final ChatManagementRemoteDataSource remoteDataSource;

  @override
  Future<ChatListPageEntity> getAllChats(ChatListQuery query) =>
      remoteDataSource.getAllChats(query);

  @override
  Future<ChatEntity> getChatById(String id) =>
      remoteDataSource.getChatById(id);

  @override
  Future<ChatMessagesPageEntity> getChatMessages(
    String chatId,
    ChatMessagesQuery query,
  ) =>
      remoteDataSource.getChatMessages(chatId, query);

  @override
  Future<ChatEntity> updateChat(String id, UpdateChatData data) =>
      remoteDataSource.updateChat(id, data);

  @override
  Future<ChatDeleteResultEntity> deleteChat(String id) =>
      remoteDataSource.deleteChat(id);

  @override
  Future<ChatMessageDeleteResultEntity> deleteMessage(String messageId) =>
      remoteDataSource.deleteMessage(messageId);

  @override
  Future<ChatBulkResultEntity> bulkAction({
    required ChatBulkAction action,
    List<String> chatIds = const [],
    List<String> messageIds = const [],
  }) =>
      remoteDataSource.bulkAction(
        action: action,
        chatIds: chatIds,
        messageIds: messageIds,
      );
}
