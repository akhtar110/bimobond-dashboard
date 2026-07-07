part of 'chat_management_bloc.dart';

sealed class ChatManagementState extends Equatable {
  const ChatManagementState();

  @override
  List<Object?> get props => [];
}

class ChatManagementInitial extends ChatManagementState {
  const ChatManagementInitial();
}

class ChatManagementLoaded extends ChatManagementState {
  const ChatManagementLoaded({
    required this.chats,
    required this.listQuery,
    this.filterUser,
    required this.messages,
    required this.messagesQuery,
    required this.selectedChatIds,
    required this.selectedMessageIds,
    required this.isLoadingChats,
    required this.isLoadingMoreChats,
    required this.isLoadingMessages,
    required this.isLoadingMoreMessages,
    required this.isSubmitting,
    required this.isSocketConnected,
    required this.analytics,
    this.chatsMeta,
    this.selectedChat,
    this.messagesMeta,
    this.typingUserId,
    this.successMessage,
    this.failureMessage,
    this.listFilterRevision = 0,
    this.messagesFilterRevision = 0,
  });

  final List<ChatEntity> chats;
  final PaginationMeta? chatsMeta;
  final ChatListQuery listQuery;
  final UserEntity? filterUser;
  final ChatEntity? selectedChat;
  final List<ChatMessageEntity> messages;
  final PaginationMeta? messagesMeta;
  final ChatMessagesQuery messagesQuery;
  final Set<String> selectedChatIds;
  final Set<String> selectedMessageIds;
  final bool isLoadingChats;
  final bool isLoadingMoreChats;
  final bool isLoadingMessages;
  final bool isLoadingMoreMessages;
  final bool isSubmitting;
  final bool isSocketConnected;
  final String? typingUserId;
  final String? successMessage;
  final String? failureMessage;
  final ChatMessageAnalytics analytics;
  final int listFilterRevision;
  final int messagesFilterRevision;

  bool get hasChatSelection => selectedChatIds.isNotEmpty;
  bool get hasMessageSelection => selectedMessageIds.isNotEmpty;
  bool get allChatsSelected =>
      chats.isNotEmpty && chats.every((c) => selectedChatIds.contains(c.id));
  bool get someChatsSelected =>
      chats.any((c) => selectedChatIds.contains(c.id)) && !allChatsSelected;
  bool get allMessagesSelected => messages.isNotEmpty &&
      messages.every((m) => selectedMessageIds.contains(m.id));
  bool get someMessagesSelected =>
      messages.any((m) => selectedMessageIds.contains(m.id)) &&
      !allMessagesSelected;

  @override
  List<Object?> get props => [
        chats,
        chatsMeta,
        listQuery,
        filterUser,
        selectedChat,
        messages,
        messagesMeta,
        messagesQuery,
        selectedChatIds,
        selectedMessageIds,
        isLoadingChats,
        isLoadingMoreChats,
        isLoadingMessages,
        isLoadingMoreMessages,
        isSubmitting,
        isSocketConnected,
        typingUserId,
        successMessage,
        failureMessage,
        analytics,
        listFilterRevision,
        messagesFilterRevision,
      ];
}
