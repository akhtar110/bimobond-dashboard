import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../domain/entities/auction_update_entity.dart';

class AuctionSocketService {
  AuctionSocketService(this._baseUrl);

  final String _baseUrl;
  io.Socket? _socket;
  final _updateController =
      StreamController<AuctionUpdateEntity>.broadcast();

  Stream<AuctionUpdateEntity> get updates => _updateController.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      // Connected successfully
    });

    _socket!.on('auctionUpdated', (data) {
      try {
        final map = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        final update = AuctionUpdateEntity.fromJson(map);
        if (!_updateController.isClosed) {
          _updateController.add(update);
        }
      } catch (_) {
        // Ignore malformed events
      }
    });

    _socket!.connect();
  }

  void joinAuction(String auctionId) {
    connect();
    _socket?.emit('joinAuction', {'auctionId': auctionId});
  }

  void leaveAuction(String auctionId) {
    _socket?.emit('leaveAuction', {'auctionId': auctionId});
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateController.close();
  }
}
