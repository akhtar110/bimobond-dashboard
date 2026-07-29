class UserLastLocationEntity {
  const UserLastLocationEntity({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.city,
    this.region,
    this.country,
    this.source,
    this.updatedAt,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final String? city;
  final String? region;
  final String? country;
  final String? source;
  final DateTime? updatedAt;

  static UserLastLocationEntity? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);

    double? readDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
      return null;
    }

    return UserLastLocationEntity(
      latitude: readDouble(json['latitude']),
      longitude: readDouble(json['longitude']),
      accuracy: readDouble(json['accuracy']),
      altitude: readDouble(json['altitude']),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      source: json['source']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
