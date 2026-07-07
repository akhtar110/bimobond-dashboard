import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../domain/entities/chat_entities.dart';
import '../models/chat_models.dart';

class ChatSocketEvent {
  const ChatSocketEvent({
    required this.type,
    this.messageId,
    this.message,
    this.chatId,
    this.userId,
    this.isTyping,
    this.emoji,
  });

  final ChatSocketEventType type;
  final String? messageId;
  final ChatMessageEntity? message;
  final String? chatId;
  final String? userId;
  final bool? isTyping;
  final String? emoji;
}

enum ChatSocketEventType {
  connected,
  newMessage,
  messageDeleted,
  messageRead,
  messageReacted,
  userTyping,
}

class ChatSocketService {
  ChatSocketService(this._baseUrl);

  final String _baseUrl;
  io.Socket? _socket;
  String? _joinedChatId;

  final _eventController = StreamController<ChatSocketEvent>.broadcast();
  Stream<ChatSocketEvent> get events => _eventController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity.toInt())
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      if (!_eventController.isClosed) {
        _eventController.add(
          const ChatSocketEvent(type: ChatSocketEventType.connected),
        );
      }
      if (_joinedChatId != null) {
        _socket!.emit('joinChat', {'chatId': _joinedChatId});
      }
    });

    _socket!.on('newMessage', (data) {
      _emitParsed(data, ChatSocketEventType.newMessage);
    });
    _socket!.on('messageDeleted', (data) {
      if (data is Map) {
        _eventController.add(ChatSocketEvent(
          type: ChatSocketEventType.messageDeleted,
          messageId: data['messageId']?.toString(),
          chatId: data['chatId']?.toString(),
        ));
      }
    });
    _socket!.on('messageRead', (data) {
      if (data is Map) {
        _eventController.add(ChatSocketEvent(
          type: ChatSocketEventType.messageRead,
          messageId: data['messageId']?.toString(),
          userId: data['userId']?.toString(),
        ));
      }
    });
    _socket!.on('messageReacted', (data) {
      if (data is Map) {
        _eventController.add(ChatSocketEvent(
          type: ChatSocketEventType.messageReacted,
          messageId: data['messageId']?.toString(),
          userId: data['userId']?.toString(),
          emoji: data['emoji']?.toString(),
        ));
      }
    });
    _socket!.on('userTyping', (data) {
      if (data is Map) {
        _eventController.add(ChatSocketEvent(
          type: ChatSocketEventType.userTyping,
          chatId: data['chatId']?.toString(),
          userId: data['userId']?.toString(),
          isTyping: data['isTyping'] == true,
        ));
      }
    });

    _socket!.connect();
  }

  void _emitParsed(dynamic data, ChatSocketEventType type) {
    try {
      if (data is Map<String, dynamic>) {
        _eventController.add(ChatSocketEvent(
          type: type,
          message: ChatMessageModel.fromJson(data),
          chatId: data['chatId']?.toString(),
        ));
      } else if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _eventController.add(ChatSocketEvent(
          type: type,
          message: ChatMessageModel.fromJson(map),
          chatId: map['chatId']?.toString(),
        ));
      }
    } catch (_) {}
  }

  void joinChat(String chatId) {
    _joinedChatId = chatId;
    _socket?.emit('joinChat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _socket?.emit('leaveChat', {'chatId': chatId});
    if (_joinedChatId == chatId) _joinedChatId = null;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _joinedChatId = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
