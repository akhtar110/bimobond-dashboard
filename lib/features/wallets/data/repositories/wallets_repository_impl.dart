import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/repositories/wallets_repository.dart';
import '../datasources/wallets_remote_datasource.dart';

class WalletsRepositoryImpl implements WalletsRepository {
  const WalletsRepositoryImpl(this._remote);
  final WalletsRemoteDataSource _remote;

  @override
  Future<EconomyEntity> getEconomy() => _remote.getEconomy();

  @override
  Future<WalletOverviewEntity> getOverview() => _remote.getOverview();

  @override
  Future<PaginatedResult<WalletListItemEntity>> getWallets(
    WalletsListQuery query,
  ) =>
      _remote.getWallets(query);

  @override
  Future<WalletDetailEntity> getWalletDetail(String userId) =>
      _remote.getWalletDetail(userId);

  @override
  Future<AdjustBalanceResultEntity> adjustBalance(
    String userId,
    AdjustBalanceData data,
  ) =>
      _remote.adjustBalance(userId, data);

  @override
  Future<PaginatedResult<LedgerEntryEntity>> getLedger(LedgerQuery query) =>
      _remote.getLedger(query);

  @override
  Future<PaginatedResult<FiatPurchaseEntity>> getFiatPurchases(
    FiatPurchasesQuery query,
  ) =>
      _remote.getFiatPurchases(query);

  @override
  Future<PaginatedResult<WithdrawalEntity>> getWithdrawals(
    WithdrawalsQuery query,
  ) =>
      _remote.getWithdrawals(query);

  @override
  Future<List<CoinPackageEntity>> getCoinPackages() =>
      _remote.getCoinPackages();

  @override
  Future<CoinPackageEntity> createCoinPackage(CreateCoinPackageData data) =>
      _remote.createCoinPackage(data);

  @override
  Future<CoinPackageEntity> updateCoinPackage(
    String packageId,
    UpdateCoinPackageData data,
  ) =>
      _remote.updateCoinPackage(packageId, data);

  @override
  Future<CoinPackageEntity> deleteCoinPackage(String packageId) =>
      _remote.deleteCoinPackage(packageId);
}
