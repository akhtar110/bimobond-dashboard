import 'package:dio/dio.dart';

import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_update_body.dart';
import '../models/auction_model.dart';
import '../models/auction_pricing_preview_model.dart';
import '../models/auctions_page_model.dart';

abstract class AuctionsRemoteDataSource {
  Future<List<AuctionModel>> getActiveAuctions();

  Future<AuctionsPageModel> getAdminAuctions({
    required int page,
    required int limit,
    required AdminAuctionsQuery query,
  });

  Future<AuctionModel> getAuctionDetails(String auctionId);

  Future<AuctionPricingPreviewModel> previewAuctionPricing({
    double? targetPrice,
    double? targetPriceCoins,
    String? currencyCode,
  });

  Future<AuctionModel> createAuction(Map<String, dynamic> body);

  Future<AuctionModel> hostUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  );

  Future<AuctionModel> hostCancelAuction(String auctionId);

  Future<AuctionModel> adminCancelAuction(String auctionId);

  Future<AuctionModel> adminBanAuction(String auctionId);

  Future<AuctionModel> adminUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  );

  Future<AuctionModel> adminResolveAuction(String auctionId, String winnerId);
}

class AuctionsRemoteDataSourceImpl implements AuctionsRemoteDataSource {
  const AuctionsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<AuctionModel>> getActiveAuctions() async {
    final response = await _dio.get('/auctions/active');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['auctions'] ?? data['items'];
      if (list is List) {
        return list
            .map((e) => AuctionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

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
  Future<AuctionPricingPreviewModel> previewAuctionPricing({
    double? targetPrice,
    double? targetPriceCoins,
    String? currencyCode,
  }) async {
    final params = <String, dynamic>{};
    if (targetPrice != null) params['targetPrice'] = targetPrice;
    if (targetPriceCoins != null) params['targetPriceCoins'] = targetPriceCoins;
    if (currencyCode != null && currencyCode.trim().isNotEmpty) {
      params['currencyCode'] = currencyCode.trim();
    }

    final response = await _dio.get(
      '/auctions/pricing/preview',
      queryParameters: params,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return AuctionPricingPreviewModel.fromJson(payload);
    }
    throw Exception('Invalid pricing preview response format');
  }

  @override
  Future<AuctionModel> createAuction(Map<String, dynamic> body) async {
    final response = await _dio.post('/auctions', data: body);
    return _parse(response.data);
  }

  @override
  Future<AuctionModel> hostUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  ) async {
    final response = await _dio.patch(
      '/auctions/$auctionId',
      data: body.toJson(),
    );
    return _parse(response.data);
  }

  @override
  Future<AuctionModel> hostCancelAuction(String auctionId) async {
    final response = await _dio.patch('/auctions/$auctionId/cancel');
    return _parse(response.data);
  }

  @override
  Future<AuctionModel> adminBanAuction(String auctionId) async {
    final response = await _dio.patch('/auctions/admin/$auctionId/ban');
    return _parse(response.data);
  }

  @override
  Future<AuctionModel> adminUpdateAuction(
    String auctionId,
    AuctionUpdateBody body,
  ) async {
    final response = await _dio.patch(
      '/auctions/admin/$auctionId',
      data: body.toJson(),
    );
    return _parse(response.data);
  }

  @override
  Future<AuctionModel> adminCancelAuction(String auctionId) async {
    final response = await _dio.patch('/auctions/admin/$auctionId/cancel');
    return _parse(response.data);
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
