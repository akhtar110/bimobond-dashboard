import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_last_location_entity.dart';

/// Primary label for the users table (city + country when available).
String userListLocationLabel(UserEntity user) {
  final loc = user.lastLocation;
  final city = _nonEmpty(loc?.city) ?? _nonEmpty(user.city);
  final region = _nonEmpty(loc?.region) ?? _nonEmpty(user.region);
  final country = _nonEmpty(loc?.country) ?? _nonEmpty(user.country);

  if (city != null && country != null) return '$city, $country';
  if (city != null && region != null) return '$city, $region';
  if (city != null) return city;
  if (region != null && country != null) return '$region, $country';
  if (region != null) return region;
  if (country != null) return country;
  return '';
}

String userLocationSortKey(UserEntity user) {
  final loc = user.lastLocation;
  return [
    _nonEmpty(loc?.country) ?? _nonEmpty(user.country),
    _nonEmpty(loc?.region) ?? _nonEmpty(user.region),
    _nonEmpty(loc?.city) ?? _nonEmpty(user.city),
  ].whereType<String>().join('\u0000').toLowerCase();
}

String formatUserLocation(BuildContext context, UserEntity user) {
  final label = userListLocationLabel(user);
  return label.isEmpty ? context.l10n.t('notProvided') : label;
}

String? userLocationTooltip(BuildContext context, UserEntity user) {
  final loc = user.lastLocation;
  if (loc == null &&
      user.city == null &&
      user.region == null &&
      user.country == null) {
    return null;
  }

  final l10n = context.l10n;
  final lines = <String>[];

  final resolved = loc ?? UserLastLocationEntity(
    city: user.city,
    region: user.region,
    country: user.country,
  );

  final placeParts = [
    resolved.city,
    resolved.region,
    resolved.country,
  ].whereType<String>().where((p) => p.isNotEmpty).toList();
  if (placeParts.isNotEmpty) {
    lines.add(placeParts.join(', '));
  }

  if (loc?.updatedAt != null) {
    final formatted = DateFormat.yMMMd().add_jm().format(loc!.updatedAt!.toLocal());
    lines.add('${l10n.t('lastUpdated')}: $formatted');
  }

  if (loc?.latitude != null && loc?.longitude != null) {
    lines.add(
      '${loc!.latitude!.toStringAsFixed(5)}, ${loc.longitude!.toStringAsFixed(5)}',
    );
  }

  if (loc?.source != null && loc!.source!.isNotEmpty) {
    lines.add('${l10n.tOr('locationSource', 'Source')}: ${loc.source}');
  }

  return lines.isEmpty ? null : lines.join('\n');
}

String? _nonEmpty(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
