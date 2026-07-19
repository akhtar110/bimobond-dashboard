import '../../domain/entities/chat_entities.dart';

class PaginationMetaModel extends PaginationMeta {
  const PaginationMetaModel({
    required super.total,
    required super.page,
    required super.limit,
    required super.totalPages,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaginationMetaModel(total: 0, page: 1, limit: 20, totalPages: 1);
    }
    final totalPages = _int(json['totalPages']) > 0
        ? _int(json['totalPages'])
        : _int(json['lastPage'], fallback: 1);
    return PaginationMetaModel(
      total: _int(json['total']),
      page: _int(json['page'], fallback: 1),
      limit: _int(json['limit'], fallback: 20),
      totalPages: totalPages,
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class ChatUserSummaryModel extends ChatUserSummary {
  const ChatUserSummaryModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
  });

  factory ChatUserSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ChatUserSummaryModel(id: '', username: 'unknown');
    }
    return ChatUserSummaryModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] == true,
      isBanned: json['isBanned'] == true,
    );
  }
}

class ChatParticipantModel extends ChatParticipantEntity {
  const ChatParticipantModel({
    required super.id,
    required super.chatId,
    required super.userId,
    required super.role,
    required super.isMuted,
    required super.isPinned,
    required super.joinedAt,
    super.user,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'MEMBER',
      isMuted: json['isMuted'] == true,
      isPinned: json['isPinned'] == true,
      joinedAt: _date(json['joinedAt']) ?? DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? ChatUserSummaryModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatPreviewMessageModel extends ChatPreviewMessage {
  const ChatPreviewMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.type,
    super.content,
    required super.isDeleted,
    required super.createdAt,
    super.sender,
  });

  factory ChatPreviewMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatPreviewMessageModel(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      type: chatMessageTypeFromApi(json['type']?.toString()),
      content: json['content']?.toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      sender: json['sender'] is Map<String, dynamic>
          ? ChatUserSummaryModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.isGroup,
    super.name,
    super.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
    super.participants,
    super.messageCount,
    super.participantCount,
    super.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    final messages = json['messages'];
    ChatPreviewMessage? lastMessage;
    if (messages is List && messages.isNotEmpty) {
      final first = messages.first;
      if (first is Map<String, dynamic>) {
        lastMessage = ChatPreviewMessageModel.fromJson(first);
      }
    } else if (json['lastMessage'] is Map<String, dynamic>) {
      lastMessage = ChatPreviewMessageModel.fromJson(
        json['lastMessage'] as Map<String, dynamic>,
      );
    }

    return ChatModel(
      id: json['id']?.toString() ?? '',
      isGroup: _bool(json['isGroup']),
      name: json['name']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      participants: (json['participants'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatParticipantModel.fromJson)
          .toList(),
      messageCount: count is Map ? PaginationMetaModel._int(count['messages']) : 0,
      participantCount:
          count is Map ? PaginationMetaModel._int(count['participants']) : 0,
      lastMessage: lastMessage,
    );
  }
}

class ChatMessageReactionModel extends ChatMessageReaction {
  const ChatMessageReactionModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.emoji,
    required super.createdAt,
    super.user,
  });

  factory ChatMessageReactionModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageReactionModel(
      id: json['id']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? ChatUserSummaryModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatReadReceiptModel extends ChatReadReceipt {
  const ChatReadReceiptModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.readAt,
    super.user,
  });

  factory ChatReadReceiptModel.fromJson(Map<String, dynamic> json) {
    return ChatReadReceiptModel(
      id: json['id']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      readAt: _date(json['readAt']) ?? DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? ChatUserSummaryModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.type,
    super.content,
    super.mediaUrl,
    super.sharedPostId,
    super.sharedPost,
    super.locationPayload,
    super.replyToId,
    required super.isDeleted,
    required super.createdAt,
    required super.updatedAt,
    super.sender,
    super.reactions,
    super.readReceipts,
    super.replyTo,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    ChatMessageEntity? replyTo;
    if (json['replyTo'] is Map<String, dynamic>) {
      replyTo = ChatMessageModel.fromJson(json['replyTo'] as Map<String, dynamic>);
    }

    final type = chatMessageTypeFromApi(json['type']?.toString());
    final payloadMap = _parsePayloadMap(json['payload']);
    final sharedPost = _parseSharedPost(json['sharedPost']);
    final sharedPostId =
        json['sharedPostId']?.toString() ?? sharedPost?.id;

    ChatMessageLocationPayload? locationPayload;
    if (type == ChatMessageType.location || type == ChatMessageType.unknown) {
      locationPayload = ChatMessageLocationPayloadModel.fromPayload(payloadMap);
    }
    final resolvedType = locationPayload != null && type == ChatMessageType.unknown
        ? ChatMessageType.location
        : type;

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      type: resolvedType,
      content: json['content']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      sharedPostId: sharedPostId,
      sharedPost: sharedPost,
      locationPayload: locationPayload,
      replyToId: json['replyToId']?.toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? _date(json['createdAt']) ?? DateTime.now(),
      sender: json['sender'] is Map<String, dynamic>
          ? ChatUserSummaryModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      reactions: (json['reactions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageReactionModel.fromJson)
          .toList(),
      readReceipts: (json['readReceipts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatReadReceiptModel.fromJson)
          .toList(),
      replyTo: replyTo,
    );
  }
}

class ChatSharedPostSummaryModel extends ChatSharedPostSummary {
  const ChatSharedPostSummaryModel({
    required super.id,
    super.description,
    super.thumbnailUrl,
    super.type,
    super.userName,
    super.userFullName,
    super.userProfileImage,
  });

  factory ChatSharedPostSummaryModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json['author'] is Map<String, dynamic>
            ? json['author'] as Map<String, dynamic>
            : null;

    return ChatSharedPostSummaryModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['caption']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ??
          json['thumbnail']?.toString(),
      type: json['type']?.toString(),
      userName: user?['username']?.toString(),
      userFullName: user?['fullName']?.toString() ?? user?['name']?.toString(),
      userProfileImage: user?['avatarUrl']?.toString() ??
          user?['profileImage']?.toString(),
    );
  }
}

class ChatMessageLocationPayloadModel extends ChatMessageLocationPayload {
  const ChatMessageLocationPayloadModel({
    required super.latitude,
    required super.longitude,
    super.name,
    super.address,
    super.placeId,
  });

  static ChatMessageLocationPayload? fromPayload(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final lat = _double(json['latitude'] ?? json['lat']);
    final lng = _double(json['longitude'] ?? json['lng']);
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat == 0 && lng == 0) return null;

    return ChatMessageLocationPayloadModel(
      latitude: lat,
      longitude: lng,
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      placeId: json['placeId']?.toString(),
    );
  }
}

Map<String, dynamic>? _parsePayloadMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

ChatSharedPostSummary? _parseSharedPost(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return ChatSharedPostSummaryModel.fromJson(raw);
  }
  if (raw is Map) {
    return ChatSharedPostSummaryModel.fromJson(Map<String, dynamic>.from(raw));
  }
  return null;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class ChatBulkResultModel extends ChatBulkResultEntity {
  const ChatBulkResultModel({
    required super.action,
    required super.successCount,
    super.failedCount,
    required super.notFoundCount,
    super.chatIds,
    super.messageIds,
    super.notFoundIds,
  });

  factory ChatBulkResultModel.fromJson(
    Map<String, dynamic> json,
    ChatBulkAction fallbackAction,
  ) {
    final actionRaw = json['action']?.toString();
    final action = switch (actionRaw) {
      'DELETE_CHATS' => ChatBulkAction.deleteChats,
      'DELETE_MESSAGES' => ChatBulkAction.deleteMessages,
      _ => fallbackAction,
    };

    return ChatBulkResultModel(
      action: action,
      successCount: PaginationMetaModel._int(json['successCount']),
      failedCount: PaginationMetaModel._int(json['failedCount']),
      notFoundCount: PaginationMetaModel._int(json['notFoundCount']),
      chatIds: _ids(json['chatIds']),
      messageIds: _ids(json['messageIds']),
      notFoundIds: _ids(json['notFoundIds']),
    );
  }

  static List<String> _ids(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

DateTime? _date(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

bool _bool(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

List<Map<String, dynamic>> _extractChatList(Map<String, dynamic> raw) {
  dynamic rawList = raw['data'] ?? raw['chats'];
  if (rawList is Map) {
    final map = Map<String, dynamic>.from(rawList);
    rawList = map['data'] ?? map['chats'] ?? map['items'];
  }
  if (rawList is! List) return const [];
  return rawList
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

List<Map<String, dynamic>> _extractMessageList(Map<String, dynamic> raw) {
  dynamic rawList = raw['data'] ?? raw['messages'];
  if (rawList is Map) {
    final map = Map<String, dynamic>.from(rawList);
    rawList = map['data'] ?? map['messages'] ?? map['items'];
  }
  if (rawList is! List) return const [];
  return rawList
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

Map<String, dynamic>? _extractMeta(Map<String, dynamic> raw) {
  final top = raw['meta'] ?? raw['pagination'];
  if (top is Map<String, dynamic>) return top;

  final payload = raw['data'];
  if (payload is Map<String, dynamic>) {
    final nested = payload['meta'] ?? payload['pagination'];
    if (nested is Map<String, dynamic>) return nested;
  }
  return null;
}

ChatListPageEntity parseChatListPage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final list = _extractChatList(data).map(ChatModel.fromJson).toList();
    return ChatListPageEntity(
      chats: list,
      meta: PaginationMetaModel.fromJson(_extractMeta(data)),
    );
  }
  if (data is List) {
    return ChatListPageEntity(
      chats: data.whereType<Map<String, dynamic>>().map(ChatModel.fromJson).toList(),
      meta: const PaginationMetaModel(total: 0, page: 1, limit: 20, totalPages: 1),
    );
  }
  return const ChatListPageEntity(
    chats: [],
    meta: PaginationMetaModel(total: 0, page: 1, limit: 20, totalPages: 1),
  );
}

ChatMessagesPageEntity parseChatMessagesPage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final list = _extractMessageList(data).map(ChatMessageModel.fromJson).toList();
    return ChatMessagesPageEntity(
      messages: list,
      meta: PaginationMetaModel.fromJson(_extractMeta(data)),
    );
  }
  if (data is List) {
    return ChatMessagesPageEntity(
      messages: data.whereType<Map<String, dynamic>>().map(ChatMessageModel.fromJson).toList(),
      meta: const PaginationMetaModel(total: 0, page: 1, limit: 50, totalPages: 1),
    );
  }
  return const ChatMessagesPageEntity(
    messages: [],
    meta: PaginationMetaModel(total: 0, page: 1, limit: 50, totalPages: 1),
  );
}
