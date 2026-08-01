import '../../../../core/utils/location_data_cache.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../../create_post/domain/services/create_post_geocoding_service.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/repositories/users_repository.dart';
import '../../domain/entities/managed_post_author_enrichment.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/managed_post_location_entity.dart';
import '../datasources/managed_post_location_remote_data_source.dart';

bool _postLocationMissing(ManagedPostEntity post) =>
    post.location == null || !post.location!.hasDisplayData;

bool _locationNeedsGeocoding(ManagedPostLocationEntity location) {
  if (location.latitude == null || location.longitude == null) return false;
  return location.city == null &&
      location.region == null &&
      location.country == null &&
      location.countryCode == null;
}

ManagedPostLocationEntity _fromCreatePostLocation(
  CreatePostLocationEntity source,
) {
  return ManagedPostLocationEntity(
    name: source.name,
    city: source.city,
    countryCode: source.countryCode,
    address: source.address,
    latitude: source.latitude,
    longitude: source.longitude,
  ).withResolvedAddress();
}

/// Resolves post locations for list/feed views.
///
/// Order: location id → author profile → reverse geocode.
/// Per-post detail fetches are skipped by default (feed rows already include user
/// data; detail endpoints add N+1 calls without locationId).
Future<List<ManagedPostEntity>> hydrateManagedPostLocations(
  List<ManagedPostEntity> posts,
  ManagedPostLocationRemoteDataSource locationDataSource, {
  UsersRepository? usersRepository,
  CreatePostGeocodingService? geocodingService,
  LocationDataCache? locationCache,
  bool fetchPostDetail = false,
}) async {
  if (posts.isEmpty) return posts;

  final cache = locationCache ?? LocationDataCache.instance;

  final locationIds = <String>{};
  for (final post in posts) {
    if (!_postLocationMissing(post)) continue;
    final id = post.locationId?.trim();
    if (id != null && id.isNotEmpty) locationIds.add(id);
  }

  final byLocationId = <String, ManagedPostLocationEntity>{};
  if (locationIds.isNotEmpty) {
    await Future.wait(
      locationIds.map((id) async {
        final location = await locationDataSource.fetchById(id);
        if (location != null) byLocationId[id] = location;
      }),
    );
  }

  var hydrated = _applyLocationMap(
    posts,
    (post) {
      final locationId = post.locationId?.trim();
      if (locationId == null) return null;
      return byLocationId[locationId];
    },
  );

  if (fetchPostDetail) {
    final postsNeedingDetail = hydrated
        .where(
          (post) =>
              _postLocationMissing(post) &&
              post.id.isNotEmpty &&
              !cache.hasLocationByPostIdEntry(post.id),
        )
        .toList(growable: false);

    if (postsNeedingDetail.isNotEmpty) {
      final byPostId = <String, ManagedPostLocationEntity>{};
      await Future.wait(
        postsNeedingDetail.map((post) async {
          final location = await locationDataSource.fetchFromPostDetail(post.id);
          if (location != null) byPostId[post.id] = location;
        }),
      );
      hydrated = _applyLocationMap(
        hydrated,
        (post) => byPostId[post.id],
      );
    }
  }

  if (usersRepository != null) {
    final userIds = <String>{};
    for (final post in hydrated) {
      if (!_postLocationMissing(post)) continue;
      if (post.userId.isNotEmpty) userIds.add(post.userId);
    }

    if (userIds.isNotEmpty) {
      final usersById = <String, UserEntity>{};
      await Future.wait(
        userIds.map((userId) async {
          final cached = cache.getUser(userId);
          if (cached != null) {
            usersById[userId] = cached;
            return;
          }
          try {
            final detail = await usersRepository.getUserById(userId);
            usersById[userId] = detail.user;
            cache.putUser(detail.user);
          } on Object {
            // Keep feed usable when a profile lookup fails.
          }
        }),
      );

      hydrated = hydrated
          .map((post) {
            if (!_postLocationMissing(post)) return post;
            final user = usersById[post.userId];
            if (user == null) return post;
            return enrichManagedPostLocationFromAuthor(post, author: user);
          })
          .toList(growable: false);
    }
  }

  hydrated = await _geocodeCoordinateLocations(
    hydrated,
    geocodingService ?? CreatePostGeocodingService(),
    cache,
  );

  cache.putHydratedPosts(hydrated);
  return hydrated;
}

List<ManagedPostEntity> _applyLocationMap(
  List<ManagedPostEntity> posts,
  ManagedPostLocationEntity? Function(ManagedPostEntity post) resolve,
) {
  return posts
      .map((post) {
        if (!_postLocationMissing(post)) return post;
        final location = resolve(post);
        if (location == null) return post;
        return post.copyWith(location: location);
      })
      .toList(growable: false);
}

Future<List<ManagedPostEntity>> _geocodeCoordinateLocations(
  List<ManagedPostEntity> posts,
  CreatePostGeocodingService geocoding,
  LocationDataCache cache,
) async {
  Future<ManagedPostLocationEntity?> resolveCoords(
    ManagedPostLocationEntity location,
  ) async {
    if (!_locationNeedsGeocoding(location)) return location;
    final lat = location.latitude!;
    final lng = location.longitude!;

    if (cache.hasReverseGeocodeEntry(lat, lng)) {
      final cachedReverse = cache.getReverseGeocode(lat, lng);
      return cachedReverse == null
          ? location
          : _fromCreatePostLocation(cachedReverse);
    }

    final resolved = await geocoding.reverseGeocode(
      latitude: lat,
      longitude: lng,
    );
    cache.putReverseGeocode(lat, lng, resolved);
    if (resolved == null) return location;

    return _fromCreatePostLocation(resolved);
  }

  final coordJobs = <String, Future<ManagedPostLocationEntity?>>{};
  for (final post in posts) {
    final loc = post.location;
    if (loc == null || !_locationNeedsGeocoding(loc)) continue;
    final key = LocationDataCache.coordKey(loc.latitude!, loc.longitude!);
    coordJobs.putIfAbsent(key, () => resolveCoords(loc));
  }

  if (coordJobs.isNotEmpty) {
    await Future.wait(coordJobs.values);
  }

  final enrichedByCoord = <String, ManagedPostLocationEntity?>{};
  for (final entry in coordJobs.entries) {
    enrichedByCoord[entry.key] = await entry.value;
  }

  return posts
      .map((post) {
        final loc = post.location;
        if (loc == null || !_locationNeedsGeocoding(loc)) return post;
        final key = LocationDataCache.coordKey(loc.latitude!, loc.longitude!);
        final enriched = enrichedByCoord[key];
        return enriched == null ? post : post.copyWith(location: enriched);
      })
      .toList(growable: false);
}

String? managedPostListLocationLabel(ManagedPostEntity post) =>
    managedPostLocationLabel(post.location);

bool managedPostHasListLocation(ManagedPostEntity post) {
  final label = managedPostListLocationLabel(post);
  return label != null && label.isNotEmpty;
}
