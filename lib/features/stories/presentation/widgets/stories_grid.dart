import 'package:flutter/material.dart';

import '../../../posts/presentation/utils/posts_page_layout.dart';
import '../../domain/entities/story_entity.dart';
import 'story_card.dart';

class StoriesGrid extends StatelessWidget {
  const StoriesGrid({
    super.key,
    required this.stories,
    required this.onStoryTap,
    required this.onStoryAction,
  });

  final List<StoryEntity> stories;
  final ValueChanged<StoryEntity> onStoryTap;
  final void Function(StoryEntity story, StoryCardActionType action) onStoryAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 520 ? 8.0 : 12.0;
        final columns = postsGridColumnCount(constraints.maxWidth);
        final rowCount = (stories.length / columns).ceil();

        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              if (rowIndex > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    Expanded(
                      child: () {
                        final index = rowIndex * columns + col;
                        if (index >= stories.length) {
                          return const SizedBox.shrink();
                        }
                        final story = stories[index];
                        return StoryCard(
                          story: story,
                          onTap: () => onStoryTap(story),
                          onAction: (action) => onStoryAction(story, action),
                        );
                      }(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
