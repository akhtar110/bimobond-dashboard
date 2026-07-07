import 'auction_entity.dart';

class AuctionsPageEntity {
  const AuctionsPageEntity({
    required this.auctions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AuctionEntity> auctions;
  final int currentPage;
  final int lastPage;
  final int total;
}
