import 'package:flutter/material.dart';

import '../utils/posts_page_layout.dart';

class PostsSkeletonGrid extends StatefulWidget {
  const PostsSkeletonGrid({required this.width});

  final double width;

  @override
  State<PostsSkeletonGrid> createState() => PostsSkeletonGridState();
}

class PostsSkeletonGridState extends State<PostsSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = postsGridColumnCount(widget.width);
    const gap = 12.0;
    const rows = 2;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows,
          separatorBuilder: (context, idx) => const SizedBox(height: gap),
          itemBuilder: (_, rowIndex) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: PostsShimmerCard(shimmerValue: _shimmer.value),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PostsShimmerCard extends StatelessWidget {
  const PostsShimmerCard({required this.shimmerValue});

  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerLow;
    final highlight = scheme.surfaceContainerHighest;
    final shimmerColor = Color.lerp(base, highlight, shimmerValue)!;
    final strongerBase = scheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(shimmerColor, height: 13, width: double.infinity),
                const SizedBox(height: 7),
                _bar(shimmerColor, height: 11, width: 160),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _bar(strongerBase, height: 9, width: 48),
                    const SizedBox(width: 8),
                    _bar(strongerBase, height: 9, width: 40),
                    const SizedBox(width: 8),
                    _bar(strongerBase, height: 9, width: 36),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
