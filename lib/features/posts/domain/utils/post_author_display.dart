import '../../../post_management/domain/entities/managed_post_entity.dart';

/// Display name for a post author (full name, then username, then user id).
String postAuthorDisplayName(ManagedPostEntity post) =>
    post.userFullName?.trim().isNotEmpty == true
        ? post.userFullName!
        : (post.userName ?? post.userId);

/// Case-insensitive key used when sorting posts by author name.
String postAuthorSortKey(ManagedPostEntity post) =>
    postAuthorDisplayName(post).toLowerCase();
