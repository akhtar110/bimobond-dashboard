import 'package:equatable/equatable.dart';

enum ChatMessageType {
  text,
  audio,
  image,
  video,
  postShare,
  location,
  unknown,
}

enum ChatBulkAction { deleteChats, deleteMessages }

enum ChatTypeFilter { all, group, direct }

enum ChatMessageTypeFilter { all, text, image, video, audio, postShare, location }

enum ChatDeletedFilter { all, deletedOnly, activeOnly }

ChatMessageType chatMessageTypeFromApi(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'TEXT':
      return ChatMessageType.text;
    case 'AUDIO':
      return ChatMessageType.audio;
    case 'IMAGE':
      return ChatMessageType.image;
    case 'VIDEO':
      return ChatMessageType.video;
    case 'POST_SHARE':
      return ChatMessageType.postShare;
    case 'LOCATION':
      return ChatMessageType.location;
    default:
      return ChatMessageType.unknown;
  }
}

String chatMessageTypeToApi(ChatMessageType type) {
  switch (type) {
    case ChatMessageType.text:
      return 'TEXT';
    case ChatMessageType.audio:
      return 'AUDIO';
    case ChatMessageType.image:
      return 'IMAGE';
    case ChatMessageType.video:
      return 'VIDEO';
    case ChatMessageType.postShare:
      return 'POST_SHARE';
    case ChatMessageType.location:
      return 'LOCATION';
    case ChatMessageType.unknown:
      return 'TEXT';
  }
}

class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

class ChatUserSummary extends Equatable {
  const ChatUserSummary({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : username;

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isVerified, isBanned];
}

class ChatParticipantEntity extends Equatable {
  const ChatParticipantEntity({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.role,
    required this.isMuted,
    required this.isPinned,
    required this.joinedAt,
    this.user,
  });

  final String id;
  final String chatId;
  final String userId;
  final String role;
  final bool isMuted;
  final bool isPinned;
  final DateTime joinedAt;
  final ChatUserSummary? user;

  @override
  List<Object?> get props =>
      [id, chatId, userId, role, isMuted, isPinned, joinedAt, user];
}

class ChatPreviewMessage extends Equatable {
  const ChatPreviewMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.content,
    required this.isDeleted,
    required this.createdAt,
    this.sender,
  });

  final String id;
  final String chatId;
  final String senderId;
  final ChatMessageType type;
  final String? content;
  final bool isDeleted;
  final DateTime createdAt;
  final ChatUserSummary? sender;

  @override
  List<Object?> get props =>
      [id, chatId, senderId, type, content, isDeleted, createdAt, sender];
}

class ChatEntity extends Equatable {
  const ChatEntity({
    required this.id,
    required this.isGroup,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.messageCount = 0,
    this.participantCount = 0,
    this.lastMessage,
  });

  final String id;
  final bool isGroup;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipantEntity> participants;
  final int messageCount;
  final int participantCount;
  final ChatPreviewMessage? lastMessage;

  String displayTitle({String directFallback = 'Direct chat'}) {
    if (name?.trim().isNotEmpty == true) return name!.trim();
    if (!isGroup && participants.length >= 2) {
      return participants
          .map((p) => p.user?.displayName ?? p.userId)
          .take(2)
          .join(' & ');
    }
    if (participants.isNotEmpty) {
      return participants.first.user?.displayName ?? directFallback;
    }
    return directFallback;
  }

  @override
  List<Object?> get props => [
        id,
        isGroup,
        name,
        avatarUrl,
        createdAt,
        updatedAt,
        participants,
        messageCount,
        participantCount,
        lastMessage,
      ];
}

class ChatMessageReaction extends Equatable {
  const ChatMessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.user,
  });

  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  final ChatUserSummary? user;

  @override
  List<Object?> get props => [id, messageId, userId, emoji, createdAt, user];
}

class ChatReadReceipt extends Equatable {
  const ChatReadReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.readAt,
    this.user,
  });

  final String id;
  final String messageId;
  final String userId;
  final DateTime readAt;
  final ChatUserSummary? user;

  @override
  List<Object?> get props => [id, messageId, userId, readAt, user];
}

/// Embedded post summary on POST_SHARE messages (`sharedPost` from API).
class ChatSharedPostSummary extends Equatable {
  const ChatSharedPostSummary({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.type,
    this.userName,
    this.userFullName,
    this.userProfileImage,
  });

  final String id;
  final String? description;
  final String? thumbnailUrl;
  final String? type;
  final String? userName;
  final String? userFullName;
  final String? userProfileImage;

  @override
  List<Object?> get props => [
        id,
        description,
        thumbnailUrl,
        type,
        userName,
        userFullName,
        userProfileImage,
      ];
}

/// LOCATION message payload (`payload` from API).
class ChatMessageLocationPayload extends Equatable {
  const ChatMessageLocationPayload({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  final String? placeId;

  String get displayTitle {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    final trimmedAddress = address?.trim();
    if (trimmedAddress != null && trimmedAddress.isNotEmpty) return trimmedAddress;
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String? get displaySubtitle {
    final trimmedName = name?.trim();
    final trimmedAddress = address?.trim();
    if (trimmedName != null &&
        trimmedName.isNotEmpty &&
        trimmedAddress != null &&
        trimmedAddress.isNotEmpty &&
        trimmedAddress != trimmedName) {
      return trimmedAddress;
    }
    return null;
  }

  String get mapsQueryUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  @override
  List<Object?> get props =>
      [latitude, longitude, name, address, placeId];
}

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.sharedPostId,
    this.sharedPost,
    this.locationPayload,
    this.replyToId,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.reactions = const [],
    this.readReceipts = const [],
    this.replyTo,
  });

  final String id;
  final String chatId;
  final String senderId;
  final ChatMessageType type;
  final String? content;
  final String? mediaUrl;
  final String? sharedPostId;
  final ChatSharedPostSummary? sharedPost;
  final ChatMessageLocationPayload? locationPayload;
  final String? replyToId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatUserSummary? sender;
  final List<ChatMessageReaction> reactions;
  final List<ChatReadReceipt> readReceipts;
  final ChatMessageEntity? replyTo;

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        type,
        content,
        mediaUrl,
        sharedPostId,
        sharedPost,
        locationPayload,
        replyToId,
        isDeleted,
        createdAt,
        updatedAt,
        sender,
        reactions,
        readReceipts,
        replyTo,
      ];
}

class ChatListPageEntity extends Equatable {
  const ChatListPageEntity({required this.chats, required this.meta});

  final List<ChatEntity> chats;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [chats, meta];
}

class ChatMessagesPageEntity extends Equatable {
  const ChatMessagesPageEntity({required this.messages, required this.meta});

  final List<ChatMessageEntity> messages;
  final PaginationMeta meta;

  @override
  List<Object?> get props => [messages, meta];
}

class ChatBulkResultEntity extends Equatable {
  const ChatBulkResultEntity({
    required this.action,
    required this.successCount,
    this.failedCount = 0,
    required this.notFoundCount,
    this.chatIds = const [],
    this.messageIds = const [],
    this.notFoundIds = const [],
  });

  final ChatBulkAction action;
  final int successCount;
  final int failedCount;
  final int notFoundCount;
  final List<String> chatIds;
  final List<String> messageIds;
  final List<String> notFoundIds;

  @override
  List<Object?> get props =>
      [action, successCount, failedCount, notFoundCount, chatIds, messageIds, notFoundIds];
}

class ChatMessageAnalytics extends Equatable {
  const ChatMessageAnalytics({
    this.text = 0,
    this.image = 0,
    this.video = 0,
    this.audio = 0,
    this.postShare = 0,
    this.deleted = 0,
  });

  final int text;
  final int image;
  final int video;
  final int audio;
  final int postShare;
  final int deleted;

  int get total => text + image + video + audio + postShare;

  factory ChatMessageAnalytics.fromMessages(List<ChatMessageEntity> messages) {
    var text = 0, image = 0, video = 0, audio = 0, postShare = 0, deleted = 0;
    for (final m in messages) {
      if (m.isDeleted) {
        deleted++;
        continue;
      }
      switch (m.type) {
        case ChatMessageType.text:
          text++;
        case ChatMessageType.image:
          image++;
        case ChatMessageType.video:
          video++;
        case ChatMessageType.audio:
          audio++;
        case ChatMessageType.postShare:
          postShare++;
        case ChatMessageType.location:
          break;
        case ChatMessageType.unknown:
          text++;
      }
    }
    return ChatMessageAnalytics(
      text: text,
      image: image,
      video: video,
      audio: audio,
      postShare: postShare,
      deleted: deleted,
    );
  }

  @override
  List<Object?> get props => [text, image, video, audio, postShare, deleted];
}
