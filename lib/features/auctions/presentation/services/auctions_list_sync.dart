import 'dart:async';

import '../../domain/entities/auction_entity.dart';

/// Broadcasts auction mutations so the list bloc can patch rows without being
/// in the detail route's widget tree.
class AuctionsListSync {
  final _controller = StreamController<AuctionEntity>.broadcast();

  Stream<AuctionEntity> get updates => _controller.stream;

  void publish(AuctionEntity auction) {
    if (_controller.isClosed) return;
    _controller.add(auction);
  }

  Future<void> dispose() => _controller.close();
}
