import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../entities/create_post_location_entity.dart';

/// Geocoding + place search for create-post location picking.
class CreatePostGeocodingService {
  CreatePostGeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {
                  'User-Agent': 'BimoBondDashboard/1.0 (create-post-location)',
                },
              ),
            );

  final Dio _dio;

  Future<CreatePostLocationEntity?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
        },
      );
      final data = response.data;
      if (data == null) return null;
      return _fromNominatimReverse(data, latitude, longitude);
    } on Object {
      return _fallbackLocation(latitude, longitude);
    }
  }

  Future<List<CreatePostLocationEntity>> searchPlaces({
    required String query,
    LatLng? near,
    int limit = 15,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty && near == null) return const [];

    try {
      final params = <String, dynamic>{
        'q': trimmed.isEmpty ? 'place' : trimmed,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': limit,
      };
      if (near != null) {
        params['lat'] = near.latitude;
        params['lon'] = near.longitude;
      }

      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: params,
      );
      final data = response.data;
      if (data == null) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(_fromNominatimSearch)
          .where((place) => place.isComplete)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<List<CreatePostLocationEntity>> nearbyPlaces(LatLng point) async {
    final current = await reverseGeocode(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    final seed = _firstNonEmpty([
      current?.city,
      current?.name,
      current?.address,
    ]);

    final searches = <Future<List<CreatePostLocationEntity>>>[
      searchPlaces(query: seed ?? 'city', near: point, limit: 12),
      if (seed != null &&
          current?.city != null &&
          seed != current!.city)
        searchPlaces(query: current.city!, near: point, limit: 8),
    ];

    final merged = <CreatePostLocationEntity>[];
    if (current != null && current.isComplete) {
      merged.add(current);
    }

    for (final batch in await Future.wait(searches)) {
      merged.addAll(batch);
    }

    return _dedupe(merged);
  }

  CreatePostLocationEntity _fromNominatimReverse(
    Map<String, dynamic> json,
    double latitude,
    double longitude,
  ) {
    final address = json['address'];
    final addressMap =
        address is Map<String, dynamic> ? address : const <String, dynamic>{};

    final name = _firstNonEmpty([
      json['name']?.toString(),
      addressMap['amenity']?.toString(),
      addressMap['building']?.toString(),
      addressMap['road']?.toString(),
      addressMap['suburb']?.toString(),
      addressMap['neighbourhood']?.toString(),
      addressMap['city']?.toString(),
      addressMap['town']?.toString(),
      addressMap['village']?.toString(),
      json['display_name']?.toString(),
    ]);

    final city = _firstNonEmpty([
      addressMap['city']?.toString(),
      addressMap['town']?.toString(),
      addressMap['village']?.toString(),
      addressMap['municipality']?.toString(),
      addressMap['state']?.toString(),
    ]);

    final street = _firstNonEmpty([
      addressMap['road']?.toString(),
      addressMap['pedestrian']?.toString(),
      addressMap['footway']?.toString(),
    ]);

    final houseNumber = addressMap['house_number']?.toString();
    final fullAddress = [
      if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
      if (street != null) street,
    ].join(' ').trim();

    return CreatePostLocationEntity(
      name: name ?? _fallbackLocation(latitude, longitude).name,
      latitude: latitude,
      longitude: longitude,
      address: fullAddress.isNotEmpty
          ? fullAddress
          : json['display_name']?.toString(),
      city: city,
      countryCode: addressMap['country_code']?.toString().toUpperCase(),
      placeId: json['place_id']?.toString(),
    );
  }

  CreatePostLocationEntity _fromNominatimSearch(Map<String, dynamic> json) {
    final latitude = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final longitude = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    return _fromNominatimReverse(json, latitude, longitude);
  }

  CreatePostLocationEntity _fallbackLocation(double latitude, double longitude) {
    return CreatePostLocationEntity(
      name: '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  List<CreatePostLocationEntity> _dedupe(
    List<CreatePostLocationEntity> places,
  ) {
    final seen = <String>{};
    final output = <CreatePostLocationEntity>[];
    for (final place in places) {
      if (!place.isComplete) continue;
      final key = place.placeId ??
          '${place.latitude.toStringAsFixed(4)}:'
          '${place.longitude.toStringAsFixed(4)}';
      if (seen.add(key)) output.add(place);
    }
    return output;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
