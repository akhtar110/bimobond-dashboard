part of 'chat_management_bloc.dart';

sealed class ChatManagementEvent extends Equatable {
  const ChatManagementEvent();

  @override
  List<Object?> get props => [];
}

class ChatManagementStarted extends ChatManagementEvent {
  const ChatManagementStarted();
}

class ChatManagementStopped extends ChatManagementEvent {
  const ChatManagementStopped();
}

class ChatsRefreshed extends ChatManagementEvent {
  const ChatsRefreshed();
}

class ChatsLoadMoreRequested extends ChatManagementEvent {
  const ChatsLoadMoreRequested();
}

class ChatsGoToPageRequested extends ChatManagementEvent {
  const ChatsGoToPageRequested(this.page);
  final int page;

  @override
  List<Object?> get props => [page];
}

class ChatSelected extends ChatManagementEvent {
  const ChatSelected(this.chatId);
  final String chatId;

  @override
  List<Object?> get props => [chatId];
}

class MessagesLoadMoreRequested extends ChatManagementEvent {
  const MessagesLoadMoreRequested();
}

class MessagesGoToPageRequested extends ChatManagementEvent {
  const MessagesGoToPageRequested(this.page);
  final int page;

  @override
  List<Object?> get props => [page];
}

class ChatsSearchChanged extends ChatManagementEvent {
  const ChatsSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ChatsTypeFilterChanged extends ChatManagementEvent {
  const ChatsTypeFilterChanged(this.filter);
  final ChatTypeFilter filter;

  @override
  List<Object?> get props => [filter];
}

class ChatsParticipantFilterChanged extends ChatManagementEvent {
  const ChatsParticipantFilterChanged(this.user);
  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}

class ChatsFiltersReset extends ChatManagementEvent {
  const ChatsFiltersReset();
}

class MessagesSearchChanged extends ChatManagementEvent {
  const MessagesSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class MessagesRefreshed extends ChatManagementEvent {
  const MessagesRefreshed(this.chatId);
  final String chatId;

  @override
  List<Object?> get props => [chatId];
}

class MessagesTypeFilterChanged extends ChatManagementEvent {
  const MessagesTypeFilterChanged(this.filter);
  final ChatMessageTypeFilter filter;

  @override
  List<Object?> get props => [filter];
}

class MessagesDeletedFilterChanged extends ChatManagementEvent {
  const MessagesDeletedFilterChanged(this.filter);
  final ChatDeletedFilter filter;

  @override
  List<Object?> get props => [filter];
}

class ChatSelectionToggled extends ChatManagementEvent {
  const ChatSelectionToggled(this.chatId);
  final String chatId;

  @override
  List<Object?> get props => [chatId];
}

class ChatsSelectAllToggled extends ChatManagementEvent {
  const ChatsSelectAllToggled();
}

class ChatsSelectAllVisible extends ChatManagementEvent {
  const ChatsSelectAllVisible();
}

class ChatSelectionCleared extends ChatManagementEvent {
  const ChatSelectionCleared();
}

class MessageSelectionToggled extends ChatManagementEvent {
  const MessageSelectionToggled(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

class MessagesSelectAllToggled extends ChatManagementEvent {
  const MessagesSelectAllToggled();
}

class MessagesSelectAllVisible extends ChatManagementEvent {
  const MessagesSelectAllVisible();
}

class MessageSelectionCleared extends ChatManagementEvent {
  const MessageSelectionCleared();
}

class ChatDeleteRequested extends ChatManagementEvent {
  const ChatDeleteRequested(this.chatId);
  final String chatId;

  @override
  List<Object?> get props => [chatId];
}

class MessageDeleteRequested extends ChatManagementEvent {
  const MessageDeleteRequested(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

class ChatsBulkDeleteRequested extends ChatManagementEvent {
  const ChatsBulkDeleteRequested();
}

class MessagesBulkDeleteRequested extends ChatManagementEvent {
  const MessagesBulkDeleteRequested();
}

class ChatMetadataUpdateRequested extends ChatManagementEvent {
  const ChatMetadataUpdateRequested({
    required this.chatId,
    this.name,
    this.avatarUrl,
  });

  final String chatId;
  final String? name;
  final String? avatarUrl;

  @override
  List<Object?> get props => [chatId, name, avatarUrl];
}

class ChatSocketEventReceived extends ChatManagementEvent {
  const ChatSocketEventReceived(this.event);
  final ChatSocketEvent event;

  @override
  List<Object?> get props => [event];
}

class ChatFeedbackCleared extends ChatManagementEvent {
  const ChatFeedbackCleared();
}
