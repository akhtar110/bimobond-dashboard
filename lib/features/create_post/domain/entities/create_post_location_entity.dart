import 'package:equatable/equatable.dart';

/// Inline location object for `POST /posts` (`location` field).
class CreatePostLocationEntity extends Equatable {
  const CreatePostLocationEntity({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.countryCode,
    this.placeId,
    this.id,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? countryCode;
  final String? placeId;

  /// Present when reusing an existing server location (`locationId`).
  final String? id;

  bool get isComplete =>
      name.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  CreatePostLocationEntity copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? countryCode,
    String? placeId,
    String? id,
  }) {
    return CreatePostLocationEntity(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      placeId: placeId ?? this.placeId,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'latitude': latitude,
      'longitude': longitude,
      if (address != null && address!.trim().isNotEmpty)
        'address': address!.trim(),
      if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
      if (countryCode != null && countryCode!.trim().isNotEmpty)
        'countryCode': countryCode!.trim(),
      if (placeId != null && placeId!.trim().isNotEmpty)
        'placeId': placeId!.trim(),
    };
  }

  @override
  List<Object?> get props => [
        name,
        latitude,
        longitude,
        address,
        city,
        countryCode,
        placeId,
        id,
      ];
}
