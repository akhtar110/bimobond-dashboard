import 'package:equatable/equatable.dart';

class PostModerationActor extends Equatable {
  const PostModerationActor({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    return username;
  }

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl];
}

class PostModerationTimelineEntry extends Equatable {
  const PostModerationTimelineEntry({
    required this.id,
    required this.status,
    required this.createdAt,
    this.reason,
    this.note,
    this.moderator,
    this.changedFields = const [],
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String? reason;
  final String? note;
  final PostModerationActor? moderator;
  final List<String> changedFields;

  @override
  List<Object?> get props =>
      [id, status, createdAt, reason, note, moderator, changedFields];
}

class PostModerationTimelinePage extends Equatable {
  const PostModerationTimelinePage({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
  });

  final List<PostModerationTimelineEntry> items;
  final int page;
  final bool hasMore;
  final int? total;

  @override
  List<Object?> get props => [items, page, hasMore, total];
}

class UpdatePostStatusRequest extends Equatable {
  const UpdatePostStatusRequest({
    required this.status,
    this.reason,
    this.note,
  });

  final String status;
  final String? reason;
  final String? note;

  @override
  List<Object?> get props => [status, reason, note];
}
