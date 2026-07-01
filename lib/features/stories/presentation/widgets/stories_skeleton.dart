import 'package:flutter/material.dart';

class StoriesSkeleton extends StatefulWidget {
  const StoriesSkeleton({super.key});

  @override
  State<StoriesSkeleton> createState() => _StoriesSkeletonState();
}

class _StoriesSkeletonState extends State<StoriesSkeleton>
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
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final bubbleSize = compact ? 68.0 : 84.0;
        final count = compact ? 4 : 6;

        return AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            final base = scheme.surfaceContainerLow;
            final highlight = Color.lerp(
              base,
              scheme.surfaceContainerHighest,
              _shimmer.value,
            )!;

            return SizedBox(
              height: bubbleSize + 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: count,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  return Column(
                    children: [
                      Container(
                        width: bubbleSize,
                        height: bubbleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: highlight,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: bubbleSize * 0.65,
                        height: 9,
                        decoration: BoxDecoration(
                          color: highlight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
