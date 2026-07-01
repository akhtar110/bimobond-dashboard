import 'package:equatable/equatable.dart';

import '../../../post_management/domain/entities/managed_post_entity.dart';
import 'active_story_author.dart';

class ActiveStoryEntity extends Equatable {
  const ActiveStoryEntity({
    required this.id,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.isVideo,
    required this.title,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.author,
    required this.postData,
  });

  final String id;
  final String mediaUrl;
  final String thumbnailUrl;
  final bool isVideo;
  final String title;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ActiveStoryAuthor author;
  final ManagedPostEntity postData;

  @override
  List<Object?> get props => [
        id,
        mediaUrl,
        thumbnailUrl,
        isVideo,
        title,
        caption,
        createdAt,
        expiresAt,
        author,
        postData,
      ];
}
