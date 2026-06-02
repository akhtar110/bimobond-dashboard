class UserActivityItemEntity {
  const UserActivityItemEntity({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.details,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  final Map<String, dynamic> details;

  String? detailString(String key) {
    final value = details[key];
    if (value == null) return null;
    return value.toString();
  }

  double? detailDouble(String key) {
    final value = details[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
