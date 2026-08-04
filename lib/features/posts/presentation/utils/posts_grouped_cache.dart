import '../../../post_management/domain/entities/managed_post_entity.dart';
import 'posts_date_grouping.dart';

/// Memoizes date groups for the current posts list to avoid recomputing on rebuilds.
class PostsGroupedCache {
  List<ManagedPostEntity>? _source;
  int _fingerprint = -1;
  List<PostsDateGroup>? _groups;

  List<PostsDateGroup> resolve(List<ManagedPostEntity> posts) {
    final fingerprint = _fingerprintFor(posts);
    if (_groups != null &&
        identical(_source, posts) &&
        fingerprint == _fingerprint) {
      return _groups!;
    }

    if (_groups != null &&
        !identical(_source, posts) &&
        fingerprint == _fingerprint &&
        _source != null &&
        _source!.length == posts.length) {
      var same = true;
      for (var i = 0; i < posts.length; i++) {
        final prev = _source![i];
        final next = posts[i];
        if (prev.id != next.id ||
            prev.createdAt.millisecondsSinceEpoch !=
                next.createdAt.millisecondsSinceEpoch) {
          same = false;
          break;
        }
      }
      if (same) {
        _source = posts;
        return _groups!;
      }
    }

    _source = posts;
    _fingerprint = fingerprint;
    _groups = groupPostsByDate(posts);
    return _groups!;
  }

  int _fingerprintFor(List<ManagedPostEntity> posts) {
    if (posts.isEmpty) return 0;
    return Object.hash(
      posts.length,
      Object.hashAll(
        posts.map(
          (post) => Object.hash(post.id, post.createdAt.millisecondsSinceEpoch),
        ),
      ),
    );
  }
}
