import '../../../../core/utils/location_data_cache.dart';
import '../../../create_post/data/datasources/create_post_auxiliary_remote_data_source.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../../create_post/domain/services/create_post_geocoding_service.dart';
import '../../../../injection_container.dart' as di;

/// Cached place search for posts location filters — instant prefix hits + network.
class PostsLocationSearchService {
  PostsLocationSearchService({
    CreatePostAuxiliaryRemoteDataSource? auxiliaryDataSource,
    CreatePostGeocodingService? geocodingService,
    LocationDataCache? cache,
  })  : _auxiliary =
            auxiliaryDataSource ?? di.sl<CreatePostAuxiliaryRemoteDataSource>(),
        _geocoding = geocodingService ?? CreatePostGeocodingService(),
        _cache = cache ?? LocationDataCache.instance;

  final CreatePostAuxiliaryRemoteDataSource _auxiliary;
  final CreatePostGeocodingService _geocoding;
  final LocationDataCache _cache;

  List<CreatePostLocationEntity> instantMatches(String query, {int limit = 10}) {
    return _cache.matchPlaces(query, limit: limit);
  }

  Future<List<CreatePostLocationEntity>> search(
    String query, {
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final cached = _cache.getPlaceSearch(trimmed);
    if (cached != null) return cached.take(limit).toList(growable: false);

    final results = await _fetchPlaces(trimmed, limit: limit);
    _cache.putPlaceSearch(trimmed, results);
    return results;
  }

  Future<CreatePostLocationEntity?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (_cache.hasReverseGeocodeEntry(latitude, longitude)) {
      return _cache.getReverseGeocode(latitude, longitude);
    }

    final resolved = await _geocoding.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
    );
    _cache.putReverseGeocode(latitude, longitude, resolved);
    return resolved;
  }

  Future<List<CreatePostLocationEntity>> _fetchPlaces(
    String query, {
    required int limit,
  }) async {
    try {
      final apiResults = await _auxiliary.searchLocations(
        query: query,
        page: 1,
        limit: limit,
      );
      final complete = apiResults.where((place) => place.isComplete).toList();
      if (complete.isNotEmpty) return complete;
    } on Object {
      // Fall back to open geocoding when the locations API is unavailable.
    }

    return _geocoding.searchPlaces(query: query, limit: limit);
  }
}

/// Shared cached search service for posts location filters.
final postsLocationSearchService = PostsLocationSearchService();
