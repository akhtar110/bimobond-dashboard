import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../entities/post_filters.dart';
import 'post_author_display.dart';

List<ManagedPostEntity> sortPosts(
  List<ManagedPostEntity> posts,
  String? sort,
) {
  if (PostFilters.isAuthorSort(sort)) {
    final sorted = List<ManagedPostEntity>.of(posts);
    sorted.sort((a, b) {
      final cmp = postAuthorSortKey(a).compareTo(postAuthorSortKey(b));
      return sort == PostFilters.sortAuthorDesc ? -cmp : cmp;
    });
    return sorted;
  }

  if (sort == PostFilters.sortCreatedAsc) {
    final sorted = List<ManagedPostEntity>.of(posts);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  return posts;
}
