enum WalletSort {
  balanceDesc('BALANCE_DESC'),
  balanceAsc('BALANCE_ASC'),
  newest('NEWEST'),
  oldest('OLDEST');

  const WalletSort(this.apiValue);
  final String apiValue;
}

enum LedgerAction {
  credit('CREDIT'),
  debit('DEBIT');

  const LedgerAction(this.apiValue);
  final String apiValue;
}

enum LedgerType {
  purchase('PURCHASE'),
  giftPurchase('GIFT_PURCHASE'),
  giftReceived('GIFT_RECEIVED'),
  adPromotionPurchase('AD_PROMOTION_PURCHASE'),
  adminAdjustment('ADMIN_ADJUSTMENT');

  const LedgerType(this.apiValue);
  final String apiValue;
}

enum FiatPurchaseStatus {
  pending('PENDING'),
  completed('COMPLETED'),
  refunded('REFUNDED'),
  failed('FAILED');

  const FiatPurchaseStatus(this.apiValue);
  final String apiValue;
}

enum FiatProvider {
  apple('APPLE'),
  google('GOOGLE'),
  stripe('STRIPE');

  const FiatProvider(this.apiValue);
  final String apiValue;
}

enum WithdrawalStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  completed('COMPLETED');

  const WithdrawalStatus(this.apiValue);
  final String apiValue;
}
