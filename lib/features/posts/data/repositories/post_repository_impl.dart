import 'dart:math' as math;

import '../../../../core/utils/location_data_cache.dart';
import '../../domain/entities/post_filters.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/utils/post_list_sort.dart';
import '../../domain/utils/post_location_filter.dart';
import '../../presentation/utils/post_time_format.dart';
import '../../../post_management/data/datasources/managed_post_location_remote_data_source.dart';
import '../../../post_management/data/utils/managed_post_location_hydration.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../users/domain/repositories/users_repository.dart';
import '../datasources/posts_remote_data_source.dart';

class PostListRepositoryImpl implements PostListRepository {
  PostListRepositoryImpl(
    this._dataSource,
    this._locationDataSource,
    this._usersRepository, {
    LocationDataCache? locationCache,
  }) : _locationCache = locationCache ?? LocationDataCache.instance;

  final PostsRemoteDataSource _dataSource;
  final ManagedPostLocationRemoteDataSource _locationDataSource;
  final UsersRepository _usersRepository;
  final LocationDataCache _locationCache;

  static const _maxApiPagesScan = 40;

  @override
  Future<PostsPage> getAllPosts({
    required int page,
    required int limit,
    required PostFilters filters,
  }) async {
    if (filters.hasLocationFilter) {
      return _getAllPostsWithLocationFilter(
        page: page,
        limit: limit,
        filters: filters,
      );
    }

    return _getAllPostsPage(
      page: page,
      limit: limit,
      filters: filters,
    );
  }

  Future<PostsPage> _getAllPostsPage({
    required int page,
    required int limit,
    required PostFilters filters,
  }) async {
    final model = await _dataSource.getAllPosts(
      page: page,
      limit: limit,
      filters: filters,
    );

    var posts = await _hydratePosts(model.posts);
    posts = _applyNonLocationClientFilters(posts, filters);

    final filteredCountChanged = posts.length != model.posts.length;
    final total = _adjustedTotal(
      modelTotal: model.total,
      filteredCount: posts.length,
      originalCount: model.posts.length,
      filters: filters,
      filteredCountChanged: filteredCountChanged,
    );

    posts = sortPosts(posts, filters.sort);

    return PostsPage(
      posts: posts,
      currentPage: model.currentPage,
      lastPage: model.lastPage,
      total: total,
    );
  }

  /// Location is resolved on the client (author profile + geocoding) — same as cards.
  Future<PostsPage> _getAllPostsWithLocationFilter({
    required int page,
    required int limit,
    required PostFilters filters,
  }) async {
    final apiFilters = filters.copyWith(clearLocation: true);
    final skip = (page - 1) * limit;
    final collected = <ManagedPostEntity>[];
    var totalMatches = 0;
    var apiPage = 1;
    var lastApiPage = 1;

    while (collected.length < limit && apiPage <= _maxApiPagesScan) {
      final model = await _dataSource.getAllPosts(
        page: apiPage,
        limit: limit,
        filters: apiFilters,
      );
      lastApiPage = model.lastPage;

      var posts = await _hydratePosts(model.posts);
      posts = _applyNonLocationClientFilters(posts, filters);

      for (final post in posts) {
        if (!postMatchesLocationFilter(post, filters)) continue;
        if (totalMatches >= skip && collected.length < limit) {
          collected.add(post);
        }
        totalMatches++;
      }

      if (apiPage >= lastApiPage) break;
      apiPage++;
    }

    final reachedEnd = apiPage >= lastApiPage;
    final sorted = sortPosts(collected, filters.sort);
    final lastPage = reachedEnd
        ? (totalMatches == 0 ? 1 : (totalMatches / limit).ceil())
        : math.max(page + 1, (totalMatches / limit).ceil());

    return PostsPage(
      posts: sorted,
      currentPage: page,
      lastPage: lastPage,
      total: totalMatches,
    );
  }

  Future<List<ManagedPostEntity>> _hydratePosts(
    List<ManagedPostEntity> posts,
  ) async {
    if (posts.isEmpty) return posts;

    final needsWork = <ManagedPostEntity>[];
    for (final post in posts) {
      if (_locationCache.getHydratedPost(post.id) != null) continue;
      needsWork.add(post);
    }

    if (needsWork.isNotEmpty) {
      final hydrated = await hydrateManagedPostLocations(
        needsWork,
        _locationDataSource,
        usersRepository: _usersRepository,
        locationCache: _locationCache,
      );
      _locationCache.putHydratedPosts(hydrated);
    }

    return posts
        .map((post) => _locationCache.getHydratedPost(post.id) ?? post)
        .toList(growable: false);
  }

  List<ManagedPostEntity> _applyNonLocationClientFilters(
    List<ManagedPostEntity> posts,
    PostFilters filters,
  ) {
    var output = posts;

    final userId = filters.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      output = output
          .where((post) => post.userId.trim() == userId)
          .toList(growable: false);
    }

    if (filters.hasDateRange || filters.hasTimeRange) {
      output = output
          .where((post) => postMatchesCreatedDateTimeFilters(
                post.createdAt,
                from: filters.createdFrom,
                to: filters.createdTo,
                timeFromMinutes: filters.createdTimeFromMinutes,
                timeToMinutes: filters.createdTimeToMinutes,
              ))
          .toList(growable: false);
    }

    return output;
  }

  int _adjustedTotal({
    required int modelTotal,
    required int filteredCount,
    required int originalCount,
    required PostFilters filters,
    required bool filteredCountChanged,
  }) {
    final userId = filters.userId?.trim();
    if ((userId != null && userId.isNotEmpty && filteredCountChanged) ||
        ((filters.hasDateRange || filters.hasTimeRange) &&
            filteredCountChanged)) {
      return filteredCount;
    }
    return modelTotal;
  }
}
