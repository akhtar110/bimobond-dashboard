import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/wallet_entities.dart';

class WalletUserModel extends WalletUserEntity {
  const WalletUserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.avatarUrl,
    super.isVerified,
    super.isBanned,
  });

  factory WalletUserModel.fromJson(Map<String, dynamic> json) {
    return WalletUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] == true,
      isBanned: json['isBanned'] == true,
    );
  }
}

class WalletCountsModel extends WalletCountsEntity {
  const WalletCountsModel({
    super.accountings,
    super.withdrawals,
  });

  factory WalletCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WalletCountsModel();
    return WalletCountsModel(
      accountings: _toInt(json['accountings']),
      withdrawals: _toInt(json['withdrawals']),
    );
  }
}

class WalletListItemModel extends WalletListItemEntity {
  const WalletListItemModel({
    required super.id,
    required super.userId,
    required super.balanceCoins,
    required super.createdAt,
    required super.updatedAt,
    super.user,
    super.counts,
  });

  factory WalletListItemModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final countsJson = json['_count'];
    return WalletListItemModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balanceCoins: _toDouble(json['balanceCoins']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      user: userJson is Map<String, dynamic>
          ? WalletUserModel.fromJson(userJson)
          : null,
      counts: countsJson is Map<String, dynamic>
          ? WalletCountsModel.fromJson(countsJson)
          : null,
    );
  }
}

class LedgerByTypeModel extends LedgerByTypeEntity {
  const LedgerByTypeModel({
    required super.type,
    required super.count,
    required super.amountCoins,
  });

  factory LedgerByTypeModel.fromJson(Map<String, dynamic> json) {
    return LedgerByTypeModel(
      type: json['type']?.toString() ?? '',
      count: _toInt(json['count']),
      amountCoins: _toDouble(json['amountCoins']),
    );
  }
}

class WalletOverviewModel extends WalletOverviewEntity {
  const WalletOverviewModel({
    required super.walletsTotal,
    required super.totalBalanceCoins,
    required super.fiatPurchasesTotal,
    required super.completedPurchaseVolume,
    required super.withdrawalsPending,
    required super.ledgerEntriesLast24Hours,
    required super.ledgerByType,
    required super.packagesTotal,
    required super.packagesActive,
  });

  factory WalletOverviewModel.fromJson(Map<String, dynamic> json) {
    final wallets = json['wallets'] as Map<String, dynamic>? ?? const {};
    final fiat = json['fiatPurchases'] as Map<String, dynamic>? ?? const {};
    final withdrawals =
        json['withdrawals'] as Map<String, dynamic>? ?? const {};
    final ledger = json['ledger'] as Map<String, dynamic>? ?? const {};
    final packages = json['packages'] as Map<String, dynamic>? ?? const {};
    final byType = ledger['byType'];
    return WalletOverviewModel(
      walletsTotal: _toInt(wallets['total']),
      totalBalanceCoins: _toDouble(wallets['totalBalanceCoins']),
      fiatPurchasesTotal: _toInt(fiat['total']),
      completedPurchaseVolume: _toDouble(
        fiat['completedPurchaseVolume'] ?? fiat['completedFiatVolumeUsd'],
      ),
      withdrawalsPending: _toInt(withdrawals['pending']),
      ledgerEntriesLast24Hours: _toInt(ledger['entriesLast24Hours']),
      ledgerByType: byType is List
          ? byType
              .whereType<Map<String, dynamic>>()
              .map(LedgerByTypeModel.fromJson)
              .toList()
          : const [],
      packagesTotal: _toInt(packages['total']),
      packagesActive: _toInt(packages['active']),
    );
  }
}

class CoinPackageModel extends CoinPackageEntity {
  const CoinPackageModel({
    required super.id,
    required super.name,
    required super.coinAmount,
    required super.price,
    required super.currencyCode,
    required super.isActive,
  });

  factory CoinPackageModel.fromJson(Map<String, dynamic> json) {
    return CoinPackageModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      coinAmount: _toDouble(json['coinAmount']),
      price: _toDouble(json['price'] ?? json['fiatPriceUsd'] ?? json['priceUsd']),
      currencyCode:
          json['currencyCode']?.toString() ?? 'USD',
      isActive: json['isActive'] != false,
    );
  }
}

class EconomyGiftCatalogItemModel extends EconomyGiftCatalogItem {
  const EconomyGiftCatalogItemModel({
    required super.id,
    required super.name,
    required super.priceCoins,
    required super.isActive,
  });

  factory EconomyGiftCatalogItemModel.fromJson(Map<String, dynamic> json) {
    return EconomyGiftCatalogItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCoins: _toDouble(json['priceCoins']),
      isActive: json['isActive'] != false,
    );
  }
}

class EconomyPromotionPackageItemModel extends EconomyPromotionPackageItem {
  const EconomyPromotionPackageItemModel({
    required super.id,
    required super.name,
    required super.priceCoins,
    required super.impressionCount,
    required super.isActive,
  });

  factory EconomyPromotionPackageItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EconomyPromotionPackageItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCoins: _toDouble(json['priceCoins']),
      impressionCount: _toInt(json['impressionCount']),
      isActive: json['isActive'] != false,
    );
  }
}

class EconomyModel extends EconomyEntity {
  const EconomyModel({
    required super.overview,
    required super.coinPackages,
    required super.giftCatalog,
    required super.promotionPackages,
  });

  factory EconomyModel.fromJson(Map<String, dynamic> json) {
    return EconomyModel(
      overview: WalletOverviewModel.fromJson(json),
      coinPackages: _parsePackageList(json['coinPackages']),
      giftCatalog: _parseGiftList(json['giftCatalog']),
      promotionPackages: _parsePromoList(json['promotionPackages']),
    );
  }

  static List<CoinPackageModel> _parsePackageList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CoinPackageModel.fromJson)
        .toList();
  }

  static List<EconomyGiftCatalogItemModel> _parseGiftList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(EconomyGiftCatalogItemModel.fromJson)
        .toList();
  }

  static List<EconomyPromotionPackageItemModel> _parsePromoList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(EconomyPromotionPackageItemModel.fromJson)
        .toList();
  }
}

class LedgerEntryModel extends LedgerEntryEntity {
  const LedgerEntryModel({
    required super.id,
    required super.walletId,
    required super.amountCoins,
    required super.action,
    required super.balanceAfterCoins,
    required super.type,
    required super.createdAt,
    super.referenceId,
    super.fiatPurchaseId,
    super.reason,
    super.wallet,
    super.fiatPurchase,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final walletJson = json['wallet'];
    final purchaseJson = json['fiatPurchase'];
    return LedgerEntryModel(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      amountCoins: _toDouble(json['amountCoins']),
      action: json['action']?.toString() ?? '',
      balanceAfterCoins: _toDouble(json['balanceAfterCoins']),
      type: json['type']?.toString() ?? '',
      referenceId: json['referenceId']?.toString(),
      fiatPurchaseId: json['fiatPurchaseId']?.toString(),
      reason: json['reason']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      wallet: walletJson is Map<String, dynamic>
          ? WalletListItemModel.fromJson(walletJson)
          : null,
      fiatPurchase: purchaseJson is Map<String, dynamic>
          ? FiatPurchaseModel.fromJson(purchaseJson)
          : null,
    );
  }
}

class FiatPurchaseModel extends FiatPurchaseEntity {
  const FiatPurchaseModel({
    required super.id,
    required super.userId,
    required super.provider,
    required super.providerTxId,
    required super.paidPrice,
    required super.currencyCode,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.packageId,
    super.user,
    super.package,
  });

  factory FiatPurchaseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final packageJson = json['package'];
    return FiatPurchaseModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      packageId: json['packageId']?.toString(),
      provider: json['provider']?.toString() ?? '',
      providerTxId: json['providerTxId']?.toString() ?? '',
      paidPrice: _toDouble(json['paidPrice'] ?? json['fiatAmountUsd']),
      currencyCode: json['currencyCode']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      user: userJson is Map<String, dynamic>
          ? WalletUserModel.fromJson(userJson)
          : null,
      package: packageJson is Map<String, dynamic>
          ? CoinPackageModel.fromJson(packageJson)
          : null,
    );
  }
}

class WithdrawalModel extends WithdrawalEntity {
  const WithdrawalModel({
    required super.id,
    required super.walletId,
    required super.amountCoins,
    required super.payoutMethod,
    required super.payoutDetails,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.wallet,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    final walletJson = json['wallet'];
    return WithdrawalModel(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      amountCoins: _toDouble(json['amountCoins']),
      payoutMethod: json['payoutMethod']?.toString() ?? '',
      payoutDetails: json['payoutDetails']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      wallet: walletJson is Map<String, dynamic>
          ? WalletListItemModel.fromJson(walletJson)
          : null,
    );
  }
}

class WalletDetailModel extends WalletDetailEntity {
  const WalletDetailModel({
    required super.id,
    required super.userId,
    required super.balanceCoins,
    required super.createdAt,
    required super.updatedAt,
    super.user,
    super.accountings,
    super.withdrawals,
    super.fiatPurchases,
  });

  factory WalletDetailModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final accountings = json['accountings'];
    final withdrawals = json['withdrawals'];
    final purchases = json['fiatPurchases'];
    return WalletDetailModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balanceCoins: _toDouble(json['balanceCoins']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      user: userJson is Map<String, dynamic>
          ? WalletUserModel.fromJson(userJson)
          : null,
      accountings: accountings is List
          ? accountings
              .whereType<Map<String, dynamic>>()
              .map(LedgerEntryModel.fromJson)
              .toList()
          : const [],
      withdrawals: withdrawals is List
          ? withdrawals
              .whereType<Map<String, dynamic>>()
              .map(WithdrawalModel.fromJson)
              .toList()
          : const [],
      fiatPurchases: purchases is List
          ? purchases
              .whereType<Map<String, dynamic>>()
              .map(FiatPurchaseModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class AdjustBalanceResultModel extends AdjustBalanceResultEntity {
  const AdjustBalanceResultModel({
    required super.success,
    required super.newBalanceCoins,
    required super.accounting,
  });

  factory AdjustBalanceResultModel.fromJson(Map<String, dynamic> json) {
    final accountingJson = json['accounting'] as Map<String, dynamic>? ?? {};
    return AdjustBalanceResultModel(
      success: json['success'] == true,
      newBalanceCoins: _toDouble(json['newBalanceCoins']),
      accounting: LedgerEntryModel.fromJson(accountingJson),
    );
  }
}

class WalletPageModel {
  static PaginatedResult<WalletListItemEntity> fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      data: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(WalletListItemModel.fromJson)
              .toList()
          : const [],
      meta: PaginationMeta(
        total: _toInt(meta['total']),
        page: _toInt(meta['page'], fallback: 1),
        limit: _toInt(meta['limit'], fallback: 20),
        totalPages: _toInt(meta['totalPages'], fallback: 1),
      ),
    );
  }
}

class LedgerPageModel {
  static PaginatedResult<LedgerEntryEntity> fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      data: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(LedgerEntryModel.fromJson)
              .toList()
          : const [],
      meta: PaginationMeta(
        total: _toInt(meta['total']),
        page: _toInt(meta['page'], fallback: 1),
        limit: _toInt(meta['limit'], fallback: 50),
        totalPages: _toInt(meta['totalPages'], fallback: 1),
      ),
    );
  }
}

class FiatPurchasePageModel {
  static PaginatedResult<FiatPurchaseEntity> fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      data: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(FiatPurchaseModel.fromJson)
              .toList()
          : const [],
      meta: PaginationMeta(
        total: _toInt(meta['total']),
        page: _toInt(meta['page'], fallback: 1),
        limit: _toInt(meta['limit'], fallback: 20),
        totalPages: _toInt(meta['totalPages'], fallback: 1),
      ),
    );
  }
}

class WithdrawalPageModel {
  static PaginatedResult<WithdrawalEntity> fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      data: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(WithdrawalModel.fromJson)
              .toList()
          : const [],
      meta: PaginationMeta(
        total: _toInt(meta['total']),
        page: _toInt(meta['page'], fallback: 1),
        limit: _toInt(meta['limit'], fallback: 20),
        totalPages: _toInt(meta['totalPages'], fallback: 1),
      ),
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
