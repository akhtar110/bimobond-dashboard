import '../../domain/entities/active_story_author.dart';
import '../../domain/entities/active_story_entity.dart';

/// One user's active stories shown as a single strip bubble.
class ActiveStoryUserGroup {
  const ActiveStoryUserGroup({
    required this.author,
    required this.stories,
  });

  final ActiveStoryAuthor author;
  final List<ActiveStoryEntity> stories;

  /// Newest story — used for the strip thumbnail and label.
  ActiveStoryEntity get previewStory => stories.last;
}

String activeStoryAuthorKey(ActiveStoryEntity story) {
  final authorId = story.author.id.trim();
  if (authorId.isNotEmpty) return authorId;

  final postUserId = story.postData.userId.trim();
  if (postUserId.isNotEmpty) return postUserId;

  final username = story.author.username.trim();
  if (username.isNotEmpty) return username;

  return story.author.name.trim().toLowerCase();
}

List<ActiveStoryUserGroup> groupActiveStoriesByUser(
  List<ActiveStoryEntity> stories,
) {
  if (stories.isEmpty) return const [];

  final grouped = <String, List<ActiveStoryEntity>>{};
  for (final story in stories) {
    final key = activeStoryAuthorKey(story);
    (grouped[key] ??= []).add(story);
  }

  final groups = grouped.values.map((userStories) {
    final sorted = List<ActiveStoryEntity>.from(userStories)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ActiveStoryUserGroup(
      author: sorted.last.author,
      stories: sorted,
    );
  }).toList();

  groups.sort(
    (a, b) => b.previewStory.createdAt.compareTo(a.previewStory.createdAt),
  );

  return groups;
}

List<ActiveStoryEntity> storiesForAuthor(
  List<ActiveStoryEntity> stories,
  ActiveStoryEntity tappedStory,
) {
  final key = activeStoryAuthorKey(tappedStory);
  final userStories = stories
      .where((story) => activeStoryAuthorKey(story) == key)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  return userStories;
}

int globalStoryIndex(List<ActiveStoryEntity> allStories, ActiveStoryEntity story) {
  return allStories.indexWhere((item) => item.id == story.id);
}
