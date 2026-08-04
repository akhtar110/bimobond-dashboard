import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/config/api_config.dart';
import '../../domain/entities/log_entity.dart';
import '../models/log_models.dart';

enum RealtimeSocketStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

class UserAuditLogSocketService {
  UserAuditLogSocketService({String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.resolveSocketBaseUrl();

  final String _baseUrl;
  io.Socket? _socket;
  String? _targetUserId;

  final _logController = StreamController<LogEntity>.broadcast();
  final _statusController = StreamController<RealtimeSocketStatus>.broadcast();

  Stream<LogEntity> get onModerationLog => _logController.stream;
  Stream<RealtimeSocketStatus> get statusStream => _statusController.stream;

  RealtimeSocketStatus _currentStatus = RealtimeSocketStatus.disconnected;
  RealtimeSocketStatus get currentStatus => _currentStatus;

  void connect({required String targetUserId}) {
    _targetUserId = targetUserId;
    if (_socket != null && _socket!.connected) {
      _emitJoinRoom();
      return;
    }

    _updateStatus(RealtimeSocketStatus.connecting);

    _socket?.dispose();
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      _updateStatus(RealtimeSocketStatus.connected);
      _emitJoinRoom();
    });

    _socket!.on('connecting', (_) {
      _updateStatus(RealtimeSocketStatus.connecting);
    });

    _socket!.on('reconnect_attempt', (_) {
      _updateStatus(RealtimeSocketStatus.reconnecting);
    });

    _socket!.on('reconnecting', (_) {
      _updateStatus(RealtimeSocketStatus.reconnecting);
    });

    _socket!.onConnectError((err) {
      _updateStatus(RealtimeSocketStatus.error);
    });

    _socket!.onError((err) {
      _updateStatus(RealtimeSocketStatus.error);
    });

    _socket!.onDisconnect((_) {
      _updateStatus(RealtimeSocketStatus.disconnected);
    });

    // Listen for moderation audit log events
    for (final eventName in const [
      'userModerationLog',
      'moderationLog',
      'userAuditLog',
      'auditLog',
      'user_audit_log',
      'adminAuditLog',
    ]) {
      _socket!.on(eventName, (data) {
        _handleIncomingLog(data);
      });
    }

    _socket!.connect();
  }

  void _emitJoinRoom() {
    if (_socket != null && _socket!.connected && _targetUserId != null) {
      _socket!.emit('joinUserAuditLog', {'targetUserId': _targetUserId});
      _socket!.emit('joinUserModeration', {'targetUserId': _targetUserId});
    }
  }

  void _handleIncomingLog(dynamic rawData) {
    try {
      if (rawData is Map) {
        final map = Map<String, dynamic>.from(rawData);
        // Filter out events meant for other target users if targetUserId is specified
        final eventTargetUser = map['targetUserId'] ?? map['targetId'];
        if (_targetUserId != null &&
            eventTargetUser != null &&
            eventTargetUser.toString() != _targetUserId) {
          return;
        }

        final moderator = map['moderator'] is Map
            ? Map<String, dynamic>.from(map['moderator'] as Map)
            : null;

        final logEntity = LogModel.fromJson({
          'id': map['id'],
          'createdAt': map['createdAt'] ?? DateTime.now().toIso8601String(),
          'category': map['category'] ?? 'MODERATION',
          'action': map['action'] ?? 'UPDATE',
          'actorId': map['moderatorId'] ?? moderator?['id'] ?? map['actorId'],
          'actorRole': map['actorRole'] ?? 'MODERATOR',
          'userFullName': moderator?['fullName'] ?? map['userFullName'],
          'userName': moderator?['username'] ?? map['userName'],
          'userEmail': moderator?['email'] ?? map['userEmail'],
          'avatarUrl': moderator?['avatarUrl'] ?? map['avatarUrl'],
          'targetType': 'USER',
          'targetId': map['targetUserId'] ?? _targetUserId,
          'description': map['note'] ?? map['reason'] ?? map['description'],
          'meta': {
            if (map['reason'] != null) 'reason': map['reason'],
            if (map['note'] != null) 'note': map['note'],
            if (map['oldValue'] != null) 'oldValue': map['oldValue'],
            if (map['newValue'] != null) 'newValue': map['newValue'],
          },
          'raw': map,
        });

        if (!_logController.isClosed) {
          _logController.add(logEntity);
        }
      }
    } catch (_) {
      // Ignore malformed socket messages
    }
  }

  void reconnect() {
    if (_targetUserId != null) {
      disconnect();
      connect(targetUserId: _targetUserId!);
    }
  }

  void _updateStatus(RealtimeSocketStatus newStatus) {
    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(RealtimeSocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _logController.close();
    _statusController.close();
  }
}
