import 'package:latlong2/latlong.dart';

import '../../domain/entities/promotion_entities.dart';

/// Normalizes GPS values for map rendering.
///
/// Some backends store western-hemisphere longitudes as positive numbers, or
/// swap latitude/longitude. City/country metadata is used to correct US points.
abstract final class LocationCoordinateHelper {
  static const _defaultCenter = LatLng(39.8283, -98.5795);

  static LatLng get defaultCenter => _defaultCenter;

  static LatLng toLatLng(LocationPointEntity point) {
    final resolved = resolve(point.latitude, point.longitude, point.country);
    return LatLng(resolved.lat, resolved.lng);
  }

  static ({double lat, double lng}) resolve(
    double latitude,
    double longitude,
    String? country,
  ) {
    var lat = latitude;
    var lng = longitude;

    if (lat == 0 && lng == 0) {
      return (lat: lat, lng: lng);
    }

    // Hard swap when latitude field clearly holds a longitude value.
    if (lat.abs() > 90 && lng.abs() <= 90) {
      final temp = lat;
      lat = lng;
      lng = temp;
    }

    // Common swap pattern for US locations stored reversed (e.g. lat=74, lng=40).
    if (lat.abs() >= 60 &&
        lat.abs() <= 130 &&
        lng.abs() >= 15 &&
        lng.abs() <= 55) {
      final temp = lat;
      lat = lng;
      lng = temp;
    }

    // Western hemisphere countries sometimes store positive longitude.
    if (_isWesternHemisphereCountry(country) &&
        lat >= 15 &&
        lat <= 72 &&
        lng > 0 &&
        lng <= 180) {
      lng = -lng;
    }

    return (lat: lat, lng: lng);
  }

  static bool isPlottable(
    LocationPointEntity point, {
    String? countryHint,
  }) {
    final country = point.country ?? countryHint;
    final resolved = resolve(point.latitude, point.longitude, country);
    if (resolved.lat == 0 && resolved.lng == 0) return false;
    return resolved.lat >= -90 &&
        resolved.lat <= 90 &&
        resolved.lng >= -180 &&
        resolved.lng <= 180;
  }

  static bool _isWesternHemisphereCountry(String? country) {
    if (country == null || country.trim().isEmpty) return false;
    final value = country.trim().toLowerCase();
    const matches = {
      'united states',
      'united states of america',
      'usa',
      'us',
      'u.s.',
      'u.s.a.',
      'canada',
      'mexico',
      'brazil',
      'argentina',
      'chile',
      'colombia',
      'peru',
      'puerto rico',
    };
    if (matches.contains(value)) return true;
    return value.contains('united states') || value.endsWith(', us');
  }
}
