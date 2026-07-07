import 'package:equatable/equatable.dart';

import '../enums/wallet_enums.dart';

class WalletUserEntity extends Equatable {
  const WalletUserEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  @override
  List<Object?> get props =>
      [id, username, fullName, email, avatarUrl, isVerified, isBanned];
}

class WalletCountsEntity extends Equatable {
  const WalletCountsEntity({
    this.accountings = 0,
    this.withdrawals = 0,
  });

  final int accountings;
  final int withdrawals;

  @override
  List<Object?> get props => [accountings, withdrawals];
}

class WalletListItemEntity extends Equatable {
  const WalletListItemEntity({
    required this.id,
    required this.userId,
    required this.balanceCoins,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.counts,
  });

  final String id;
  final String userId;
  final double balanceCoins;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WalletUserEntity? user;
  final WalletCountsEntity? counts;

  @override
  List<Object?> get props =>
      [id, userId, balanceCoins, createdAt, updatedAt, user, counts];
}

class LedgerByTypeEntity extends Equatable {
  const LedgerByTypeEntity({
    required this.type,
    required this.count,
    required this.amountCoins,
  });

  final String type;
  final int count;
  final double amountCoins;

  @override
  List<Object?> get props => [type, count, amountCoins];
}

class WalletOverviewEntity extends Equatable {
  const WalletOverviewEntity({
    required this.walletsTotal,
    required this.totalBalanceCoins,
    required this.fiatPurchasesTotal,
    required this.completedPurchaseVolume,
    required this.withdrawalsPending,
    required this.ledgerEntriesLast24Hours,
    required this.ledgerByType,
    required this.packagesTotal,
    required this.packagesActive,
  });

  final int walletsTotal;
  final double totalBalanceCoins;
  final int fiatPurchasesTotal;
  final double completedPurchaseVolume;
  final int withdrawalsPending;
  final int ledgerEntriesLast24Hours;
  final List<LedgerByTypeEntity> ledgerByType;
  final int packagesTotal;
  final int packagesActive;

  @override
  List<Object?> get props => [
        walletsTotal,
        totalBalanceCoins,
        fiatPurchasesTotal,
        completedPurchaseVolume,
        withdrawalsPending,
        ledgerEntriesLast24Hours,
        ledgerByType,
        packagesTotal,
        packagesActive,
      ];
}

class EconomyGiftCatalogItem extends Equatable {
  const EconomyGiftCatalogItem({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.isActive,
  });

  final String id;
  final String name;
  final double priceCoins;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, priceCoins, isActive];
}

class EconomyPromotionPackageItem extends Equatable {
  const EconomyPromotionPackageItem({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.impressionCount,
    required this.isActive,
  });

  final String id;
  final String name;
  final double priceCoins;
  final int impressionCount;
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, name, priceCoins, impressionCount, isActive];
}

class EconomyEntity extends Equatable {
  const EconomyEntity({
    required this.overview,
    required this.coinPackages,
    required this.giftCatalog,
    required this.promotionPackages,
  });

  final WalletOverviewEntity overview;
  final List<CoinPackageEntity> coinPackages;
  final List<EconomyGiftCatalogItem> giftCatalog;
  final List<EconomyPromotionPackageItem> promotionPackages;

  @override
  List<Object?> get props =>
      [overview, coinPackages, giftCatalog, promotionPackages];
}

class CoinPackageEntity extends Equatable {
  const CoinPackageEntity({
    required this.id,
    required this.name,
    required this.coinAmount,
    required this.price,
    required this.currencyCode,
    required this.isActive,
  });

  final String id;
  final String name;
  final double coinAmount;
  final double price;
  final String currencyCode;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, coinAmount, price, currencyCode, isActive];
}

class LedgerEntryEntity extends Equatable {
  const LedgerEntryEntity({
    required this.id,
    required this.walletId,
    required this.amountCoins,
    required this.action,
    required this.balanceAfterCoins,
    required this.type,
    required this.createdAt,
    this.referenceId,
    this.fiatPurchaseId,
    this.reason,
    this.wallet,
    this.fiatPurchase,
  });

  final String id;
  final String walletId;
  final double amountCoins;
  final String action;
  final double balanceAfterCoins;
  final String type;
  final String? referenceId;
  final String? fiatPurchaseId;
  final String? reason;
  final DateTime createdAt;
  final WalletListItemEntity? wallet;
  final FiatPurchaseEntity? fiatPurchase;

  @override
  List<Object?> get props => [
        id,
        walletId,
        amountCoins,
        action,
        balanceAfterCoins,
        type,
        referenceId,
        fiatPurchaseId,
        reason,
        createdAt,
        wallet,
        fiatPurchase,
      ];
}

class FiatPurchaseEntity extends Equatable {
  const FiatPurchaseEntity({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerTxId,
    required this.paidPrice,
    required this.currencyCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.packageId,
    this.user,
    this.package,
  });

  final String id;
  final String userId;
  final String? packageId;
  final String provider;
  final String providerTxId;
  final double paidPrice;
  final String currencyCode;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WalletUserEntity? user;
  final CoinPackageEntity? package;

  @override
  List<Object?> get props => [
        id,
        userId,
        packageId,
        provider,
        providerTxId,
        paidPrice,
        currencyCode,
        status,
        createdAt,
        updatedAt,
        user,
        package,
      ];
}

class WithdrawalEntity extends Equatable {
  const WithdrawalEntity({
    required this.id,
    required this.walletId,
    required this.amountCoins,
    required this.payoutMethod,
    required this.payoutDetails,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
  });

  final String id;
  final String walletId;
  final double amountCoins;
  final String payoutMethod;
  final String payoutDetails;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WalletListItemEntity? wallet;

  @override
  List<Object?> get props => [
        id,
        walletId,
        amountCoins,
        payoutMethod,
        payoutDetails,
        status,
        createdAt,
        updatedAt,
        wallet,
      ];
}

class WalletDetailEntity extends Equatable {
  const WalletDetailEntity({
    required this.id,
    required this.userId,
    required this.balanceCoins,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.accountings = const [],
    this.withdrawals = const [],
    this.fiatPurchases = const [],
  });

  final String id;
  final String userId;
  final double balanceCoins;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WalletUserEntity? user;
  final List<LedgerEntryEntity> accountings;
  final List<WithdrawalEntity> withdrawals;
  final List<FiatPurchaseEntity> fiatPurchases;

  @override
  List<Object?> get props => [
        id,
        userId,
        balanceCoins,
        createdAt,
        updatedAt,
        user,
        accountings,
        withdrawals,
        fiatPurchases,
      ];
}

class AdjustBalanceResultEntity extends Equatable {
  const AdjustBalanceResultEntity({
    required this.success,
    required this.newBalanceCoins,
    required this.accounting,
  });

  final bool success;
  final double newBalanceCoins;
  final LedgerEntryEntity accounting;

  @override
  List<Object?> get props => [success, newBalanceCoins, accounting];
}

class WalletsListQuery extends Equatable {
  const WalletsListQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.minBalance,
    this.maxBalance,
    this.sort = WalletSort.balanceDesc,
  });

  final int page;
  final int limit;
  final String? search;
  final double? minBalance;
  final double? maxBalance;
  final WalletSort sort;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort.apiValue,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (minBalance != null) params['minBalance'] = minBalance;
    if (maxBalance != null) params['maxBalance'] = maxBalance;
    return params;
  }

  WalletsListQuery copyWith({
    int? page,
    int? limit,
    String? search,
    double? minBalance,
    double? maxBalance,
    WalletSort? sort,
    bool clearSearch = false,
    bool clearMinBalance = false,
    bool clearMaxBalance = false,
  }) {
    return WalletsListQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      minBalance: clearMinBalance ? null : (minBalance ?? this.minBalance),
      maxBalance: clearMaxBalance ? null : (maxBalance ?? this.maxBalance),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props =>
      [page, limit, search, minBalance, maxBalance, sort];
}

class LedgerQuery extends Equatable {
  const LedgerQuery({
    this.page = 1,
    this.limit = 50,
    this.userId,
    this.walletId,
    this.type,
    this.action,
    this.from,
    this.to,
  });

  final int page;
  final int limit;
  final String? userId;
  final String? walletId;
  final String? type;
  final String? action;
  final DateTime? from;
  final DateTime? to;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (userId != null && userId!.isNotEmpty) params['userId'] = userId;
    if (walletId != null && walletId!.isNotEmpty) params['walletId'] = walletId;
    if (type != null && type!.isNotEmpty) params['type'] = type;
    if (action != null && action!.isNotEmpty) params['action'] = action;
    if (from != null) params['from'] = from!.toUtc().toIso8601String();
    if (to != null) params['to'] = to!.toUtc().toIso8601String();
    return params;
  }

  LedgerQuery copyWith({
    int? page,
    int? limit,
    String? userId,
    String? walletId,
    String? type,
    String? action,
    DateTime? from,
    DateTime? to,
    bool clearUserId = false,
    bool clearWalletId = false,
    bool clearType = false,
    bool clearAction = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return LedgerQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      userId: clearUserId ? null : (userId ?? this.userId),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      type: clearType ? null : (type ?? this.type),
      action: clearAction ? null : (action ?? this.action),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }

  @override
  List<Object?> get props =>
      [page, limit, userId, walletId, type, action, from, to];
}

class FiatPurchasesQuery extends Equatable {
  const FiatPurchasesQuery({
    this.page = 1,
    this.limit = 20,
    this.userId,
    this.status,
    this.provider,
    this.search,
  });

  final int page;
  final int limit;
  final String? userId;
  final String? status;
  final String? provider;
  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (userId != null && userId!.isNotEmpty) params['userId'] = userId;
    if (status != null && status!.isNotEmpty) params['status'] = status;
    if (provider != null && provider!.isNotEmpty) params['provider'] = provider;
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    return params;
  }

  FiatPurchasesQuery copyWith({
    int? page,
    int? limit,
    String? userId,
    String? status,
    String? provider,
    String? search,
    bool clearUserId = false,
    bool clearStatus = false,
    bool clearProvider = false,
    bool clearSearch = false,
  }) {
    return FiatPurchasesQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      userId: clearUserId ? null : (userId ?? this.userId),
      status: clearStatus ? null : (status ?? this.status),
      provider: clearProvider ? null : (provider ?? this.provider),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  List<Object?> get props => [page, limit, userId, status, provider, search];
}

class WithdrawalsQuery extends Equatable {
  const WithdrawalsQuery({
    this.page = 1,
    this.limit = 20,
    this.status,
  });

  final int page;
  final int limit;
  final String? status;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status!.isNotEmpty) params['status'] = status;
    return params;
  }

  WithdrawalsQuery copyWith({
    int? page,
    int? limit,
    String? status,
    bool clearStatus = false,
  }) {
    return WithdrawalsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  List<Object?> get props => [page, limit, status];
}

class CreateCoinPackageData extends Equatable {
  const CreateCoinPackageData({
    required this.name,
    required this.coinAmount,
    required this.price,
    required this.currencyCode,
    this.isActive = true,
  });

  final String name;
  final double coinAmount;
  final double price;
  final String currencyCode;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'coinAmount': coinAmount,
        'price': price,
        'currencyCode': currencyCode,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [name, coinAmount, price, currencyCode, isActive];
}

class UpdateCoinPackageData extends Equatable {
  const UpdateCoinPackageData({
    this.name,
    this.coinAmount,
    this.price,
    this.currencyCode,
    this.isActive,
  });

  final String? name;
  final double? coinAmount;
  final double? price;
  final String? currencyCode;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (coinAmount != null) json['coinAmount'] = coinAmount;
    if (price != null) json['price'] = price;
    if (currencyCode != null) json['currencyCode'] = currencyCode;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [name, coinAmount, price, currencyCode, isActive];
}

class AdjustBalanceData extends Equatable {
  const AdjustBalanceData({
    required this.action,
    required this.amountCoins,
    this.reason,
  });

  final LedgerAction action;
  final double amountCoins;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'action': action.apiValue,
        'amountCoins': amountCoins,
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
      };

  @override
  List<Object?> get props => [action, amountCoins, reason];
}
