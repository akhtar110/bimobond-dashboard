enum GiftType {
  image('IMAGE'),
  audio('AUDIO');

  const GiftType(this.apiValue);
  final String apiValue;

  static GiftType fromApi(String? value) {
    final raw = value?.trim().toUpperCase();
    if (raw == null || raw.isEmpty) return GiftType.image;
    for (final type in GiftType.values) {
      if (type.apiValue == raw || type.name.toUpperCase() == raw) {
        return type;
      }
    }
    return GiftType.image;
  }
}
