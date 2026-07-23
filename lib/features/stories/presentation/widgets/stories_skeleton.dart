import 'package:flutter/material.dart';

import '../../../posts/presentation/utils/posts_page_layout.dart';
import '../../../posts/presentation/widgets/post_card.dart';

class StoriesSkeletonGrid extends StatelessWidget {
  const StoriesSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 520 ? 8.0 : 12.0;
        final columns = postsGridColumnCount(constraints.maxWidth);

        return Column(
          children: [
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    Expanded(
                      child: _StorySkeletonCard(color: scheme.surfaceContainerHighest),
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

class _StorySkeletonCard extends StatelessWidget {
  const _StorySkeletonCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: kPostCardThumbnailAspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 12, width: 120, color: color),
        const SizedBox(height: 6),
        Container(height: 10, color: color),
        const SizedBox(height: 6),
        Container(height: 10, width: 180, color: color),
      ],
    );
  }
}
