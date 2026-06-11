import 'package:dio/dio.dart';

import '../../domain/entities/admin_auctions_query.dart';
import '../models/auction_model.dart';
import '../models/auctions_page_model.dart';

abstract class AuctionsRemoteDataSource {
  Future<AuctionsPageModel> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  });
  Future<AuctionModel> getAuctionDetails(String auctionId);
  Future<void> adminCancelAuction(String auctionId);
  Future<AuctionModel> adminResolveAuction(String auctionId, String winnerId);
}

class AuctionsRemoteDataSourceImpl implements AuctionsRemoteDataSource {
  const AuctionsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<AuctionsPageModel> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  }) async {
    final response = await _dio.get(
      '/auctions/admin/all',
      queryParameters: query.toQueryParameters(page: page, limit: limit),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AuctionsPageModel.fromJson(data);
    }
    if (data is List) {
      final auctions = data
          .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return AuctionsPageModel(
        auctions: auctions,
        currentPage: page,
        lastPage: 1,
        total: auctions.length,
      );
    }
    throw Exception('Invalid auctions response format');
  }

  @override
  Future<AuctionModel> getAuctionDetails(String auctionId) async {
    final response = await _dio.get('/auctions/$auctionId');
    return _parse(response.data);
  }

  @override
  Future<void> adminCancelAuction(String auctionId) async {
    await _dio.patch('/auctions/admin/$auctionId/cancel');
  }

  @override
  Future<AuctionModel> adminResolveAuction(
    String auctionId,
    String winnerId,
  ) async {
    final response = await _dio.patch(
      '/auctions/admin/$auctionId/resolve',
      data: {'winnerId': winnerId},
    );
    return _parse(response.data);
  }

  AuctionModel _parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['auction'] is Map<String, dynamic>
              ? data['auction'] as Map<String, dynamic>
              : data;
      return AuctionModel.fromJson(payload);
    }
    throw Exception('Invalid auction response format');
  }
}
