import '../entities/pagination_meta.dart';
import '../entities/wallet_entities.dart';
import '../repositories/wallets_repository.dart';

class GetEconomyUseCase {
  const GetEconomyUseCase(this._repository);
  final WalletsRepository _repository;
  Future<EconomyEntity> call() => _repository.getEconomy();
}

class GetWalletOverviewUseCase {
  const GetWalletOverviewUseCase(this._repository);
  final WalletsRepository _repository;
  Future<WalletOverviewEntity> call() => _repository.getOverview();
}

class GetWalletsUseCase {
  const GetWalletsUseCase(this._repository);
  final WalletsRepository _repository;
  Future<PaginatedResult<WalletListItemEntity>> call(WalletsListQuery query) =>
      _repository.getWallets(query);
}

class GetWalletDetailUseCase {
  const GetWalletDetailUseCase(this._repository);
  final WalletsRepository _repository;
  Future<WalletDetailEntity> call(String userId) =>
      _repository.getWalletDetail(userId);
}

class AdjustWalletBalanceUseCase {
  const AdjustWalletBalanceUseCase(this._repository);
  final WalletsRepository _repository;
  Future<AdjustBalanceResultEntity> call(
    String userId,
    AdjustBalanceData data,
  ) =>
      _repository.adjustBalance(userId, data);
}

class GetLedgerUseCase {
  const GetLedgerUseCase(this._repository);
  final WalletsRepository _repository;
  Future<PaginatedResult<LedgerEntryEntity>> call(LedgerQuery query) =>
      _repository.getLedger(query);
}

class GetFiatPurchasesUseCase {
  const GetFiatPurchasesUseCase(this._repository);
  final WalletsRepository _repository;
  Future<PaginatedResult<FiatPurchaseEntity>> call(FiatPurchasesQuery query) =>
      _repository.getFiatPurchases(query);
}

class GetWithdrawalsUseCase {
  const GetWithdrawalsUseCase(this._repository);
  final WalletsRepository _repository;
  Future<PaginatedResult<WithdrawalEntity>> call(WithdrawalsQuery query) =>
      _repository.getWithdrawals(query);
}

class GetCoinPackagesUseCase {
  const GetCoinPackagesUseCase(this._repository);
  final WalletsRepository _repository;
  Future<List<CoinPackageEntity>> call() => _repository.getCoinPackages();
}

class CreateCoinPackageUseCase {
  const CreateCoinPackageUseCase(this._repository);
  final WalletsRepository _repository;
  Future<CoinPackageEntity> call(CreateCoinPackageData data) =>
      _repository.createCoinPackage(data);
}

class UpdateCoinPackageUseCase {
  const UpdateCoinPackageUseCase(this._repository);
  final WalletsRepository _repository;
  Future<CoinPackageEntity> call(
    String packageId,
    UpdateCoinPackageData data,
  ) =>
      _repository.updateCoinPackage(packageId, data);
}

class DeleteCoinPackageUseCase {
  const DeleteCoinPackageUseCase(this._repository);
  final WalletsRepository _repository;
  Future<CoinPackageEntity> call(String packageId) =>
      _repository.deleteCoinPackage(packageId);
}
