/// Human-readable labels for ledger [type] values.
String ledgerTypeLabel(String type) {
  return switch (type) {
    'PURCHASE' => 'Bought coins',
    'GIFT_PURCHASE' => 'Bought gift',
    'GIFT_RECEIVED' => 'Received gift',
    'AD_PROMOTION_PURCHASE' => 'Promotion purchase',
    'ADMIN_ADJUSTMENT' => 'Admin adjustment',
    _ => type.replaceAll('_', ' ').toLowerCase(),
  };
}

String ledgerActionLabel(String action) {
  return switch (action) {
    'CREDIT' => 'Credit',
    'DEBIT' => 'Debit',
    _ => action,
  };
}
