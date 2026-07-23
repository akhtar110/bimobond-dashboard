enum GiftSize {
  small('SMALL'),
  medium('MEDIUM'),
  large('LARGE');

  const GiftSize(this.apiValue);
  final String apiValue;

  static GiftSize fromApi(String? value) {
    return GiftSize.values.firstWhere(
      (s) => s.apiValue == value?.toUpperCase(),
      orElse: () => GiftSize.medium,
    );
  }
}
