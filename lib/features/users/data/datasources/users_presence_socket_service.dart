import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/api_config.dart';
import '../../../security_logs/data/datasources/user_audit_log_socket_service.dart';

/// Represents a single presence change event from the backend.
class UserPresenceChange {
  const UserPresenceChange({
    required this.userId,
    required this.isOnline,
    this.lastSeenAt,
    this.deviceInfo,
  });

  final String userId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final String? deviceInfo;

  /// Parses the payload from presence events (e.g. `admin:user_online`, `admin:user_offline`, `user_status_changed`).
  factory UserPresenceChange.fromJson(
    Map<String, dynamic> json, {
    required bool forceOnline,
  }) {
    final userId = json['id']?.toString() ??
        json['userId']?.toString() ??
        json['user_id']?.toString() ??
        json['targetUserId']?.toString() ??
        (json['user'] is Map
            ? (json['user']['id'] ?? json['user']['userId'])?.toString()
            : null) ??
        '';

    DateTime? lastSeen;
    final rawLastSeen = json['lastSeenAt'] ??
        json['lastSeen'] ??
        json['last_seen'] ??
        json['lastActiveAt'] ??
        json['timestamp'];
    if (rawLastSeen != null) {
      lastSeen = DateTime.tryParse(rawLastSeen.toString());
    }

    final eventStr =
        (json['event'] ?? json['action'] ?? '').toString().toLowerCase();
    bool isOnline = forceOnline;
    if (json['isOnline'] is bool) {
      isOnline = json['isOnline'] as bool;
    } else if (json['online'] is bool) {
      isOnline = json['online'] as bool;
    } else if (json['status'] == 'online' ||
        eventStr == 'connected' ||
        eventStr == 'online') {
      isOnline = true;
    } else if (json['status'] == 'offline' ||
        eventStr == 'disconnected' ||
        eventStr == 'offline') {
      isOnline = false;
    }

    return UserPresenceChange(
      userId: userId,
      isOnline: isOnline,
      lastSeenAt: lastSeen ?? (isOnline ? null : DateTime.now().toUtc()),
      deviceInfo: json['device']?.toString() ?? json['deviceInfo']?.toString(),
    );
  }
}

/// Manages the WebSocket connection for real-time user presence in the admin dashboard.
class UsersPresenceSocketService {
  UsersPresenceSocketService({String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.resolveSocketBaseUrl();

  final String _baseUrl;
  io.Socket? _socket;

  final StreamController<UserPresenceChange> _presenceController =
      StreamController<UserPresenceChange>.broadcast();
  final StreamController<RealtimeSocketStatus> _statusController =
      StreamController<RealtimeSocketStatus>.broadcast();

  RealtimeSocketStatus _currentStatus = RealtimeSocketStatus.disconnected;

  Stream<UserPresenceChange> get onUserPresenceChanged =>
      _presenceController.stream;
  Stream<RealtimeSocketStatus> get statusStream => _statusController.stream;
  RealtimeSocketStatus get currentStatus => _currentStatus;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      _subscribePresence();
      return;
    }

    _updateStatus(RealtimeSocketStatus.connecting);
    _socket?.dispose();

    String? token;
    try {
      final user = FirebaseAuth.instance.currentUser;
      token = await user?.getIdToken();
    } catch (_) {}

    final optionBuilder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(999999)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(3000);

    if (token != null && token.isNotEmpty) {
      optionBuilder.setAuth({'token': token});
      optionBuilder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }

    _socket = io.io(_baseUrl, optionBuilder.build());

    _socket!.onConnect((_) {
      _updateStatus(RealtimeSocketStatus.connected);
      _subscribePresence();
    });

    _socket!.on('reconnect', (_) {
      _updateStatus(RealtimeSocketStatus.connected);
      _subscribePresence();
    });

    _socket!.on('reconnect_attempt',
        (_) => _updateStatus(RealtimeSocketStatus.reconnecting));
    _socket!.on('connect_error',
        (_) => _updateStatus(RealtimeSocketStatus.error));
    _socket!.on('disconnect',
        (_) => _updateStatus(RealtimeSocketStatus.disconnected));

    // Primary backend presence events
    _socket!.on('admin:user_online', (data) {
      _handlePresenceEvent(data, isOnline: true);
    });

    _socket!.on('admin:user_offline', (data) {
      _handlePresenceEvent(data, isOnline: false);
    });

    // Comprehensive fallback event listeners
    for (final eventName in const [
      'user_status_changed',
      'userStatusChanged',
      'user_presence',
      'presence_update',
      'user_connected',
      'userConnected',
      'user_online',
      'userOnline',
    ]) {
      _socket!.on(eventName, (data) {
        _handlePresenceEvent(data, isOnline: true);
      });
    }

    for (final eventName in const [
      'user_disconnected',
      'userDisconnected',
      'user_offline',
      'userOffline',
    ]) {
      _socket!.on(eventName, (data) {
        _handlePresenceEvent(data, isOnline: false);
      });
    }

    _socket!.connect();
  }

  /// Emit admin presence subscription after connect / reconnect.
  void _subscribePresence() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('admin:subscribe_presence');
      _socket!.emit('joinUsersPresence', {'role': 'ADMIN'});
      _socket!.emit('joinAdmins');
      _socket!.emit('subscribe_presence');
    }
  }

  void _handlePresenceEvent(dynamic rawData, {required bool isOnline}) {
    try {
      if (rawData == null) return;

      final Map<String, dynamic> map;
      if (rawData is Map) {
        map = Map<String, dynamic>.from(rawData);
      } else if (rawData is String) {
        map = {'userId': rawData};
      } else {
        return;
      }

      final presence = UserPresenceChange.fromJson(map, forceOnline: isOnline);
      if (presence.userId.isNotEmpty && !_presenceController.isClosed) {
        _presenceController.add(presence);
      }
    } catch (_) {
      // Ignore malformed payloads
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(RealtimeSocketStatus.disconnected);
  }

  void reconnect() {
    disconnect();
    connect();
  }

  void dispose() {
    disconnect();
    _presenceController.close();
    _statusController.close();
  }

  void _updateStatus(RealtimeSocketStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
