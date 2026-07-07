import 'chat_entities.dart';

class ChatListQuery {
  const ChatListQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.userId,
    this.typeFilter = ChatTypeFilter.all,
  });

  final int page;
  final int limit;
  final String? search;
  final String? userId;
  final ChatTypeFilter typeFilter;

  ChatListQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? userId,
    ChatTypeFilter? typeFilter,
    bool clearSearch = false,
    bool clearUserId = false,
    bool clearTypeFilter = false,
  }) {
    return ChatListQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      userId: clearUserId ? null : (userId ?? this.userId),
      typeFilter: clearTypeFilter
          ? ChatTypeFilter.all
          : (typeFilter ?? this.typeFilter),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }
    final trimmedUserId = userId?.trim();
    if (trimmedUserId != null && trimmedUserId.isNotEmpty) {
      params['userId'] = trimmedUserId;
    }
    switch (typeFilter) {
      case ChatTypeFilter.all:
        break;
      case ChatTypeFilter.group:
        params['isGroup'] = 'true';
      case ChatTypeFilter.direct:
        params['isGroup'] = 'false';
    }
    return params;
  }
}

class ChatMessagesQuery {
  const ChatMessagesQuery({
    this.page = 1,
    this.limit = 50,
    this.senderId,
    this.typeFilter = ChatMessageTypeFilter.all,
    this.deletedFilter = ChatDeletedFilter.all,
    this.search,
  });

  final int page;
  final int limit;
  final String? senderId;
  final ChatMessageTypeFilter typeFilter;
  final ChatDeletedFilter deletedFilter;
  final String? search;

  ChatMessagesQuery copyWith({
    int? page,
    int? limit,
    String? senderId,
    ChatMessageTypeFilter? typeFilter,
    ChatDeletedFilter? deletedFilter,
    String? search,
    bool clearSearch = false,
    bool clearSenderId = false,
    bool clearTypeFilter = false,
    bool clearDeletedFilter = false,
  }) {
    return ChatMessagesQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      senderId: clearSenderId ? null : (senderId ?? this.senderId),
      typeFilter: clearTypeFilter
          ? ChatMessageTypeFilter.all
          : (typeFilter ?? this.typeFilter),
      deletedFilter: clearDeletedFilter
          ? ChatDeletedFilter.all
          : (deletedFilter ?? this.deletedFilter),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
    }
    final trimmedSender = senderId?.trim();
    if (trimmedSender != null && trimmedSender.isNotEmpty) {
      params['senderId'] = trimmedSender;
    }
    if (typeFilter != ChatMessageTypeFilter.all) {
      params['type'] = switch (typeFilter) {
        ChatMessageTypeFilter.text => 'TEXT',
        ChatMessageTypeFilter.image => 'IMAGE',
        ChatMessageTypeFilter.video => 'VIDEO',
        ChatMessageTypeFilter.audio => 'AUDIO',
        ChatMessageTypeFilter.postShare => 'POST_SHARE',
        ChatMessageTypeFilter.all => 'TEXT',
      };
    }
    switch (deletedFilter) {
      case ChatDeletedFilter.all:
        break;
      case ChatDeletedFilter.deletedOnly:
        params['isDeleted'] = 'true';
      case ChatDeletedFilter.activeOnly:
        params['isDeleted'] = 'false';
    }
    return params;
  }
}

class UpdateChatData {
  const UpdateChatData({this.name, this.avatarUrl});

  final String? name;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
