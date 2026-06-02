import 'package:dio/dio.dart';

import '../models/auction_model.dart';

abstract class AuctionsRemoteDataSource {
  Future<List<AuctionModel>> getAllAuctions();
  Future<AuctionModel> getAuctionDetails(String auctionId);
  Future<void> adminCancelAuction(String auctionId);
  Future<AuctionModel> adminResolveAuction(String auctionId, String winnerId);
}

class AuctionsRemoteDataSourceImpl implements AuctionsRemoteDataSource {
  const AuctionsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<AuctionModel>> getAllAuctions() async {
    final response = await _dio.get('/auctions/admin/all');
    final data = response.data;
    final list = data is List ? data : (data['auctions'] ?? data['data'] ?? []) as List;
    return list.map((e) => AuctionModel.fromJson(e as Map<String, dynamic>)).toList();
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
