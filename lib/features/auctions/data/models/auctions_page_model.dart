import '../../domain/entities/auctions_page_entity.dart';
import 'auction_model.dart';

class AuctionsPageModel extends AuctionsPageEntity {
  const AuctionsPageModel({
    required super.auctions,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  factory AuctionsPageModel.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['data'] ?? json['auctions'] ?? json['items']) as List?;

    final auctions = (rawList ?? [])
        .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;
    final lastPage = (meta['totalPages'] as num?)?.toInt() ??
        (meta['lastPage'] as num?)?.toInt() ??
        1;
    final total = (meta['total'] as num?)?.toInt() ?? auctions.length;

    return AuctionsPageModel(
      auctions: auctions,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }
}
