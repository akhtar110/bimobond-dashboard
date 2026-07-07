import '../entities/pagination_meta.dart';
import '../entities/wallet_entities.dart';

abstract class WalletsRepository {
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
