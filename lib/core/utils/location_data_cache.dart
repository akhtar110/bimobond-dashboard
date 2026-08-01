import '../../features/create_post/domain/entities/create_post_location_entity.dart';
import '../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../features/post_management/domain/entities/managed_post_location_entity.dart';
import '../../features/users/domain/entities/user_entity.dart';

/// In-memory cache for location search, geocoding, and post location hydration.
class LocationDataCache {
  LocationDataCache._();
  static final LocationDataCache instance = LocationDataCache._();

  static const _maxPlaceSearchEntries = 80;
  static const _maxReverseGeocodeEntries = 200;
  static const _maxLocationIdEntries = 300;
  static const _maxPostLocationEntries = 400;
  static const _maxUserEntries = 200;
  static const _maxHydratedPostEntries = 600;

  final Map<String, List<CreatePostLocationEntity>> _placeSearch = {};
  final Map<String, CreatePostLocationEntity?> _reverseGeocode = {};
  final Map<String, ManagedPostLocationEntity?> _locationById = {};
  final Map<String, ManagedPostLocationEntity?> _locationByPostId = {};
  final Map<String, UserEntity> _usersById = {};
  final Map<String, ManagedPostEntity> _hydratedPostsById = {};

  static String normalizeQuery(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String coordKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';

  List<CreatePostLocationEntity>? getPlaceSearch(String query) {
    return _placeSearch[normalizeQuery(query)];
  }

  void putPlaceSearch(String query, List<CreatePostLocationEntity> results) {
    final key = normalizeQuery(query);
    if (key.isEmpty) return;
    _placeSearch[key] = List<CreatePostLocationEntity>.from(results);
    _trimMap(_placeSearch, _maxPlaceSearchEntries);
  }

  /// Instant matches from prior searches — filters cached places locally.
  List<CreatePostLocationEntity> matchPlaces(String query, {int limit = 10}) {
    final normalized = normalizeQuery(query);
    if (normalized.length < 2) return const [];

    final exact = _placeSearch[normalized];
    if (exact != null && exact.isNotEmpty) {
      return exact.take(limit).toList(growable: false);
    }

    final merged = <CreatePostLocationEntity>[];
    final seen = <String>{};

    for (final bucket in _placeSearch.values) {
      for (final place in bucket) {
        if (!_matchesPlaceQuery(place, normalized)) continue;
        final key = coordKey(place.latitude, place.longitude);
        if (!seen.add(key)) continue;
        merged.add(place);
        if (merged.length >= limit) return merged;
      }
    }

    return merged;
  }

  bool _matchesPlaceQuery(CreatePostLocationEntity place, String query) {
    for (final part in [place.name, place.city, place.address]) {
      final text = part?.trim().toLowerCase();
      if (text != null && text.contains(query)) return true;
    }
    return false;
  }

  CreatePostLocationEntity? getReverseGeocode(double latitude, double longitude) {
    return _reverseGeocode[coordKey(latitude, longitude)];
  }

  bool hasReverseGeocodeEntry(double latitude, double longitude) =>
      _reverseGeocode.containsKey(coordKey(latitude, longitude));

  void putReverseGeocode(
    double latitude,
    double longitude,
    CreatePostLocationEntity? value,
  ) {
    _reverseGeocode[coordKey(latitude, longitude)] = value;
    _trimMap(_reverseGeocode, _maxReverseGeocodeEntries);
  }

  ManagedPostLocationEntity? getLocationById(String id) =>
      _locationById[id.trim()];

  bool hasLocationByIdEntry(String id) => _locationById.containsKey(id.trim());

  void putLocationById(String id, ManagedPostLocationEntity? value) {
    final key = id.trim();
    if (key.isEmpty) return;
    _locationById[key] = value;
    _trimMap(_locationById, _maxLocationIdEntries);
  }

  ManagedPostLocationEntity? getLocationByPostId(String postId) =>
      _locationByPostId[postId.trim()];

  bool hasLocationByPostIdEntry(String postId) =>
      _locationByPostId.containsKey(postId.trim());

  void putLocationByPostId(String postId, ManagedPostLocationEntity? value) {
    final key = postId.trim();
    if (key.isEmpty) return;
    _locationByPostId[key] = value;
    _trimMap(_locationByPostId, _maxPostLocationEntries);
  }

  UserEntity? getUser(String userId) => _usersById[userId.trim()];

  void putUser(UserEntity user) {
    final key = user.id.trim();
    if (key.isEmpty) return;
    _usersById[key] = user;
    _trimMap(_usersById, _maxUserEntries);
  }

  ManagedPostEntity? getHydratedPost(String postId) =>
      _hydratedPostsById[postId.trim()];

  void putHydratedPost(ManagedPostEntity post) {
    final key = post.id.trim();
    if (key.isEmpty) return;
    _hydratedPostsById[key] = post;
    _trimMap(_hydratedPostsById, _maxHydratedPostEntries);
  }

  void putHydratedPosts(Iterable<ManagedPostEntity> posts) {
    for (final post in posts) {
      putHydratedPost(post);
    }
  }

  void _trimMap<K, V>(Map<K, V> map, int maxEntries) {
    while (map.length > maxEntries) {
      map.remove(map.keys.first);
    }
  }
}
