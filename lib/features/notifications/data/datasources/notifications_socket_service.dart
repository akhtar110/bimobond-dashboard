import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../domain/entities/admin_notification_event_entity.dart';
import '../models/admin_notification_event_model.dart';

class NotificationsSocketService {
  NotificationsSocketService(this._baseUrl);

  final String _baseUrl;
  io.Socket? _socket;

  final _eventController =
      StreamController<AdminNotificationEventEntity>.broadcast();

  Stream<AdminNotificationEventEntity> get adminNotifications =>
      _eventController.stream;

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
      _socket!.emit('joinAdmins');
    });

    _socket!.on('adminNotification', (data) {
      try {
        final event = AdminNotificationEventModel.fromSocketData(data);
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
      } catch (_) {
        // Ignore malformed events
      }
    });

    _socket!.onDisconnect((_) {
      // Auto-reconnect is handled by socket_io_client reconnection settings
    });

    _socket!.onError((err) {
      // Silently handle connection errors
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
