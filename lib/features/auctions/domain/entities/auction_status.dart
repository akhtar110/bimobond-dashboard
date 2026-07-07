/// Backend auction lifecycle statuses.
enum AuctionStatus {
  active('ACTIVE'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  banned('BANNED');

  const AuctionStatus(this.apiValue);
  final String apiValue;

  static AuctionStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final upper = raw.toUpperCase();
    for (final value in AuctionStatus.values) {
      if (value.apiValue == upper) return value;
    }
    return null;
  }

  static AuctionStatus parse(String? raw) =>
      tryParse(raw) ?? AuctionStatus.active;
}
