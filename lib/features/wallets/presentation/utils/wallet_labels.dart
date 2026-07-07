import 'package:flutter/widgets.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/wallet_enums.dart';

/// English copy comes from the EN ARB bundle; Arabic from the AR ARB bundle.
String walletL10nOr(BuildContext context, String key, String english) {
  return context.l10n.tOr(key, english);
}

String walletL10nArgs(
  BuildContext context,
  String key,
  Map<String, String> args,
  String english,
) {
  final template = context.l10n.tOr(key, english);
  var value = template;
  for (final entry in args.entries) {
    value = value.replaceAll('{${entry.key}}', entry.value);
  }
  return value;
}

String ledgerTypeLabel(BuildContext context, String type) {
  return switch (type) {
    'PURCHASE' =>
      walletL10nOr(context, 'walletLedgerTypePurchase', 'Bought coins'),
    'GIFT_PURCHASE' =>
      walletL10nOr(context, 'walletLedgerTypeGiftPurchase', 'Bought gift'),
    'GIFT_RECEIVED' =>
      walletL10nOr(context, 'walletLedgerTypeGiftReceived', 'Received gift'),
    'AD_PROMOTION_PURCHASE' => walletL10nOr(
        context, 'walletLedgerTypeAdPromotion', 'Promotion purchase'),
    'ADMIN_ADJUSTMENT' => walletL10nOr(
        context, 'walletLedgerTypeAdminAdjustment', 'Admin adjustment'),
    _ => type.replaceAll('_', ' ').toLowerCase(),
  };
}

String ledgerActionLabel(BuildContext context, String action) {
  return switch (action) {
    'CREDIT' => walletL10nOr(context, 'walletLedgerActionCredit', 'Credit'),
    'DEBIT' => walletL10nOr(context, 'walletLedgerActionDebit', 'Debit'),
    _ => action,
  };
}

String fiatPurchaseStatusLabel(BuildContext context, String status) {
  return switch (status) {
    'PENDING' => walletL10nOr(context, 'walletFiatStatusPending', 'Pending'),
    'COMPLETED' =>
      walletL10nOr(context, 'walletFiatStatusCompleted', 'Completed'),
    'REFUNDED' =>
      walletL10nOr(context, 'walletFiatStatusRefunded', 'Refunded'),
    'FAILED' => walletL10nOr(context, 'walletFiatStatusFailed', 'Failed'),
    _ => status,
  };
}

String withdrawalStatusLabel(BuildContext context, String status) {
  return switch (status) {
    'PENDING' =>
      walletL10nOr(context, 'walletWithdrawalStatusPending', 'Pending'),
    'APPROVED' =>
      walletL10nOr(context, 'walletWithdrawalStatusApproved', 'Approved'),
    'REJECTED' =>
      walletL10nOr(context, 'walletWithdrawalStatusRejected', 'Rejected'),
    'COMPLETED' =>
      walletL10nOr(context, 'walletWithdrawalStatusCompleted', 'Completed'),
    _ => status,
  };
}

String fiatProviderLabel(BuildContext context, String provider) {
  return switch (provider) {
    'APPLE' => walletL10nOr(context, 'walletProviderApple', 'Apple'),
    'GOOGLE' => walletL10nOr(context, 'walletProviderGoogle', 'Google'),
    'STRIPE' => walletL10nOr(context, 'walletProviderStripe', 'Stripe'),
    _ => provider,
  };
}

String walletSortLabel(BuildContext context, WalletSort sort) {
  return switch (sort) {
    WalletSort.balanceDesc =>
      walletL10nOr(context, 'walletSortBalanceDesc', 'Highest balance'),
    WalletSort.balanceAsc =>
      walletL10nOr(context, 'walletSortBalanceAsc', 'Lowest balance'),
    WalletSort.newest =>
      walletL10nOr(context, 'walletSortNewest', 'Newest first'),
    WalletSort.oldest =>
      walletL10nOr(context, 'walletSortOldest', 'Oldest first'),
  };
}

String resolveWalletMessage(BuildContext context, String message) {
  if (message.contains('|')) {
    final i = message.indexOf('|');
    final key = message.substring(0, i);
    final arg = message.substring(i + 1);
    if (key == 'walletSnackBalanceUpdated') {
      return walletL10nArgs(
        context,
        key,
        {'balance': arg},
        'Balance updated to $arg coins',
      );
    }
    return walletL10nArgs(context, key, {'balance': arg}, message);
  }
  if (message.startsWith('wallet')) {
    return walletL10nOr(context, message, message);
  }
  return message;
}
