import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.content,
    required super.postId,
    required super.userId,
    super.parentId,
    required super.likeCount,
    required super.replyCount,
    required super.createdAt,
    super.username,
    super.avatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      parentId: json['parentId'] as String?,
      likeCount: _int(json['likeCount']),
      replyCount: _int(json['replyCount']),
      createdAt: _date(json['createdAt']),
      username: user?['username'] as String? ?? user?['name'] as String?,
      avatarUrl: user?['avatarUrl'] as String?,
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _date(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

class PostCommentsPageModel extends PostCommentsPageEntity {
  const PostCommentsPageModel({
    required super.comments,
    required super.page,
    required super.hasMore,
  });

  factory PostCommentsPageModel.fromJson(
    Map<String, dynamic> json, {
    required int limit,
  }) {
    final raw = json['data'];
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List;
    } else {
      items = [];
    }

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final page = _int(meta['page']) ?? 1;
    final lastPage = _int(meta['lastPage']);
    final totalPages = _int(meta['totalPages']);

    final hasMore = lastPage != null
        ? page < lastPage
        : totalPages != null
            ? page < totalPages
            : items.length >= limit;

    return PostCommentsPageModel(
      comments: items
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: page,
      hasMore: hasMore,
    );
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
