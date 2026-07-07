import 'package:dio/dio.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../models/wallet_models.dart';

abstract class WalletsRemoteDataSource {
  Future<EconomyEntity> getEconomy();
  Future<WalletOverviewEntity> getOverview();
  Future<PaginatedResult<WalletListItemEntity>> getWallets(WalletsListQuery query);
  Future<WalletDetailEntity> getWalletDetail(String userId);
  Future<AdjustBalanceResultEntity> adjustBalance(
    String userId,
    AdjustBalanceData data,
  );
  Future<PaginatedResult<LedgerEntryEntity>> getLedger(LedgerQuery query);
  Future<PaginatedResult<FiatPurchaseEntity>> getFiatPurchases(
    FiatPurchasesQuery query,
  );
  Future<PaginatedResult<WithdrawalEntity>> getWithdrawals(
    WithdrawalsQuery query,
  );
  Future<List<CoinPackageEntity>> getCoinPackages();
  Future<CoinPackageEntity> createCoinPackage(CreateCoinPackageData data);
  Future<CoinPackageEntity> updateCoinPackage(
    String packageId,
    UpdateCoinPackageData data,
  );
  Future<CoinPackageEntity> deleteCoinPackage(String packageId);
}

class WalletsRemoteDataSourceImpl implements WalletsRemoteDataSource {
  const WalletsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<EconomyEntity> getEconomy() async {
    final response = await _dio.get('/wallets/admin/coins/economy');
    return EconomyModel.fromJson(_map(response.data));
  }

  @override
  Future<WalletOverviewEntity> getOverview() async {
    final response = await _dio.get('/wallets/admin/overview');
    return WalletOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedResult<WalletListItemEntity>> getWallets(
    WalletsListQuery query,
  ) async {
    final response = await _dio.get(
      '/wallets/admin/wallets',
      queryParameters: query.toQueryParameters(),
    );
    return WalletPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<WalletDetailEntity> getWalletDetail(String userId) async {
    final response = await _dio.get('/wallets/admin/wallets/$userId');
    return WalletDetailModel.fromJson(_map(response.data));
  }

  @override
  Future<AdjustBalanceResultEntity> adjustBalance(
    String userId,
    AdjustBalanceData data,
  ) async {
    final response = await _dio.post(
      '/wallets/admin/wallets/$userId/adjust',
      data: data.toJson(),
    );
    return AdjustBalanceResultModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedResult<LedgerEntryEntity>> getLedger(
    LedgerQuery query,
  ) async {
    final response = await _dio.get(
      '/wallets/admin/ledger',
      queryParameters: query.toQueryParameters(),
    );
    return LedgerPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<PaginatedResult<FiatPurchaseEntity>> getFiatPurchases(
    FiatPurchasesQuery query,
  ) async {
    final response = await _dio.get(
      '/wallets/admin/fiat-purchases',
      queryParameters: query.toQueryParameters(),
    );
    return FiatPurchasePageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<PaginatedResult<WithdrawalEntity>> getWithdrawals(
    WithdrawalsQuery query,
  ) async {
    final response = await _dio.get(
      '/wallets/admin/withdrawals',
      queryParameters: query.toQueryParameters(),
    );
    return WithdrawalPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<List<CoinPackageEntity>> getCoinPackages() async {
    final response = await _dio.get('/wallets/admin/packages');
    final data = response.data;
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['data'] ?? data['packages'] ?? [])
            : [];
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(CoinPackageModel.fromJson)
        .toList();
  }

  @override
  Future<CoinPackageEntity> createCoinPackage(CreateCoinPackageData data) async {
    final response = await _dio.post(
      '/wallets/admin/packages',
      data: data.toJson(),
    );
    return CoinPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<CoinPackageEntity> updateCoinPackage(
    String packageId,
    UpdateCoinPackageData data,
  ) async {
    final response = await _dio.patch(
      '/wallets/admin/packages/$packageId',
      data: data.toJson(),
    );
    return CoinPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<CoinPackageEntity> deleteCoinPackage(String packageId) async {
    final response = await _dio.delete('/wallets/admin/packages/$packageId');
    return CoinPackageModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    throw Exception('Invalid wallets API response');
  }

  Map<String, dynamic> _unwrapPaginated(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid paginated wallets response');
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic> && nested['data'] is List) {
      return nested;
    }

    if (data['data'] is List) {
      return data;
    }

    throw Exception('Invalid paginated wallets response');
  }
}
