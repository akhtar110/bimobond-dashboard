import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/entities/user_last_location_entity.dart';

/// Location attached to a post (`location` relation, inline snapshot, or fetched by id).
class ManagedPostLocationEntity {
  const ManagedPostLocationEntity({
    this.name,
    this.city,
    this.region,
    this.country,
    this.countryCode,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String? name;
  final String? city;

  /// State / province / admin area.
  final String? region;
  final String? country;
  final String? countryCode;
  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasDisplayData =>
      _nonEmpty(name) != null ||
      _nonEmpty(city) != null ||
      _nonEmpty(region) != null ||
      _nonEmpty(country) != null ||
      _nonEmpty(countryCode) != null ||
      _nonEmpty(address) != null ||
      latitude != null ||
      longitude != null;

  /// Preferred label for cards/lists: city + country, or city + region.
  String? get displayLabel {
    final place = _nonEmpty(name);
    final cityName = _nonEmpty(city);
    final regionName = _nonEmpty(region);
    final countryName = _nonEmpty(country) ?? _nonEmpty(countryCode);

    if (cityName != null && countryName != null) {
      return '$cityName, $countryName';
    }
    if (cityName != null && regionName != null) {
      return '$cityName, $regionName';
    }
    if (place != null) return place;
    if (cityName != null) return cityName;
    if (regionName != null) return regionName;
    if (countryName != null) return countryName;
    return coordinateLabel ?? _nonEmpty(address);
  }

  String? get coordinateLabel {
    if (latitude == null || longitude == null) return null;
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  /// Parses nested `location` / `place` objects or denormalized post fields.
  static ManagedPostLocationEntity? fromPostJson(Map<String, dynamic> json) {
    return parseManagedPostLocationFields(json).location;
  }

  /// Reads [locationId] and display location from feed/detail post JSON.
  static ({String? locationId, ManagedPostLocationEntity? location})
      parseManagedPostLocationFields(Map<String, dynamic> json) {
    var locationId = _nonEmpty(json['locationId']?.toString());

    for (final key in ['location', 'place', 'postLocation']) {
      final raw = json[key];
      if (raw is! Map) continue;
      final map = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      locationId ??= _nonEmpty(map['id']?.toString()) ??
          _nonEmpty(map['locationId']?.toString());
      final parsed = fromJson(map);
      if (parsed != null) {
        return (locationId: locationId, location: parsed);
      }
    }

    final lat = _readDouble(json['latitude']);
    final lng = _readDouble(json['longitude']);

    final name = _firstNonEmpty([
      json['locationName']?.toString(),
      json['placeName']?.toString(),
    ]);
    final city = _firstNonEmpty([
      json['locationCity']?.toString(),
      json['city']?.toString(),
    ]);
    final region = _readRegion(json);
    final country = _firstNonEmpty([
      json['locationCountry']?.toString(),
      json['country']?.toString(),
      json['countryName']?.toString(),
    ]);
    final countryCode = _nonEmpty(json['locationCountryCode']?.toString()) ??
        _nonEmpty(json['countryCode']?.toString());
    final address = _firstNonEmpty([
      json['locationAddress']?.toString(),
      json['address']?.toString(),
      json['formattedAddress']?.toString(),
    ]);

    if (lat == null &&
        lng == null &&
        name == null &&
        city == null &&
        region == null &&
        country == null &&
        countryCode == null &&
        address == null) {
      return (locationId: locationId, location: null);
    }

    final entity = ManagedPostLocationEntity(
      name: name,
      city: city,
      region: region,
      country: country,
      countryCode: countryCode,
      address: address,
      latitude: lat,
      longitude: lng,
    );
    final resolved = entity.hasDisplayData ? entity.withResolvedAddress() : null;
    return (locationId: locationId, location: resolved);
  }

  /// Builds a display location from a user's profile / last-known GPS snapshot.
  static ManagedPostLocationEntity? fromUserEntity(UserEntity user) {
    final fromLast = fromUserLastLocation(
      user.lastLocation,
      city: user.city,
      region: user.region,
      country: user.country,
    );
    if (fromLast != null) return fromLast;

    final city = _nonEmpty(user.city);
    final region = _nonEmpty(user.region);
    final country = _nonEmpty(user.country);
    if (city == null && region == null && country == null) return null;

    final entity = ManagedPostLocationEntity(
      city: city,
      region: region,
      country: country ?? region,
    );
    return entity.hasDisplayData ? entity : null;
  }

  static ManagedPostLocationEntity? fromUserLastLocation(
    UserLastLocationEntity? lastLocation, {
    String? city,
    String? region,
    String? country,
  }) {
    if (lastLocation == null &&
        city == null &&
        region == null &&
        country == null) {
      return null;
    }

    final resolvedCity = _nonEmpty(lastLocation?.city) ?? _nonEmpty(city);
    final resolvedRegion = _nonEmpty(lastLocation?.region) ?? _nonEmpty(region);
    final resolvedCountry =
        _nonEmpty(lastLocation?.country) ?? _nonEmpty(country);

    final entity = ManagedPostLocationEntity(
      city: resolvedCity,
      region: resolvedRegion,
      country: resolvedCountry ?? resolvedRegion,
      latitude: lastLocation?.latitude,
      longitude: lastLocation?.longitude,
    );
    return entity.hasDisplayData ? entity.withResolvedAddress() : null;
  }

  static ManagedPostLocationEntity? fromUserJson(Map<String, dynamic>? user) {
    if (user == null) return null;
    final lastLocation = UserLastLocationEntity.tryParse(user['lastLocation']);
    return fromUserLastLocation(
      lastLocation,
      city: user['city']?.toString(),
      region: user['region']?.toString(),
      country: user['country']?.toString(),
    );
  }

  static ManagedPostLocationEntity? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final json =
        raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);

    final lat = _readDouble(json['latitude']) ?? _readDouble(json['lat']);
    final lng = _readDouble(json['longitude']) ?? _readDouble(json['lng']);

    final entity = ManagedPostLocationEntity(
      name: _firstNonEmpty([
        json['name']?.toString(),
        json['title']?.toString(),
        json['label']?.toString(),
      ]),
      city: _firstNonEmpty([
        json['city']?.toString(),
        json['locality']?.toString(),
        json['town']?.toString(),
      ]),
      region: _readRegion(json),
      country: _firstNonEmpty([
        json['country']?.toString(),
        json['countryName']?.toString(),
      ]),
      countryCode: _nonEmpty(json['countryCode']?.toString()),
      address: _firstNonEmpty([
        json['address']?.toString(),
        json['formattedAddress']?.toString(),
        json['displayName']?.toString(),
      ]),
      latitude: lat,
      longitude: lng,
    );
    return entity.hasDisplayData ? entity.withResolvedAddress() : null;
  }

  ManagedPostLocationEntity withResolvedAddress() {
    if (_nonEmpty(address) != null) return this;
    final coords = coordinateLabel;
    if (coords == null) return this;
    return ManagedPostLocationEntity(
      name: name,
      city: city,
      region: region,
      country: country,
      countryCode: countryCode,
      address: coords,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String? _readRegion(Map<String, dynamic> json) {
    return _firstNonEmpty([
      json['region']?.toString(),
      json['state']?.toString(),
      json['province']?.toString(),
      json['adminArea']?.toString(),
      json['stateProvince']?.toString(),
      json['locationRegion']?.toString(),
      json['locationState']?.toString(),
    ]);
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = _nonEmpty(value);
      if (trimmed != null) return trimmed;
    }
    return null;
  }
}

String? managedPostLocationLabel(ManagedPostLocationEntity? location) =>
    location?.displayLabel;

/// Structured rows for the post details location section.
List<({String labelKey, String fallbackLabel, String value})>
    managedPostLocationDetailRows(ManagedPostLocationEntity location) {
  final rows = <({String labelKey, String fallbackLabel, String value})>[];

  void add(String key, String fallback, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    rows.add((labelKey: key, fallbackLabel: fallback, value: trimmed));
  }

  add('city', 'City', location.city);
  add('stateProvince', 'State / Province', location.region);
  add('country', 'Country', location.country ?? location.countryCode);
  add('address', 'Address', location.address ?? location.coordinateLabel);

  return rows;
}
