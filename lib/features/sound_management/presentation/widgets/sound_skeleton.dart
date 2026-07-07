import 'package:flutter/material.dart';

import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import 'sounds_table.dart';

class SoundKpiSkeletonGrid extends StatefulWidget {
  const SoundKpiSkeletonGrid({super.key, this.count = 6});

  final int count;

  @override
  State<SoundKpiSkeletonGrid> createState() => _SoundKpiSkeletonGridState();
}

class _SoundKpiSkeletonGridState extends State<SoundKpiSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = promotionsMetricColumns(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: PromotionsSpace.lg,
            mainAxisSpacing: PromotionsSpace.lg,
            childAspectRatio: promotionsMetricAspectRatio(cols),
          ),
          itemBuilder: (_, __) => _ShimmerBox(animation: _controller),
        );
      },
    );
  }
}

class SoundTableSkeleton extends StatefulWidget {
  const SoundTableSkeleton({super.key, this.rowCount = 8});

  final int rowCount;

  @override
  State<SoundTableSkeleton> createState() => _SoundTableSkeletonState();
}

class _SoundTableSkeletonState extends State<SoundTableSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              height: kSoundsTableHeaderHeight,
              color: scheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _ShimmerBox(
                    animation: _controller,
                    width: 18,
                    height: 18,
                    radius: 4,
                  ),
                  const SizedBox(width: 16),
                  _ShimmerBox(
                    animation: _controller,
                    width: 42,
                    height: 42,
                    radius: 6,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShimmerBox(
                      animation: _controller,
                      height: 12,
                      radius: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ShimmerBox(
                    animation: _controller,
                    width: 56,
                    height: 12,
                    radius: 6,
                  ),
                  const SizedBox(width: 16),
                  _ShimmerBox(
                    animation: _controller,
                    width: 40,
                    height: 12,
                    radius: 6,
                  ),
                  const SizedBox(width: 16),
                  _ShimmerBox(
                    animation: _controller,
                    width: 64,
                    height: 22,
                    radius: 999,
                  ),
                ],
              ),
            ),
            for (var i = 0; i < widget.rowCount; i++)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: i == widget.rowCount - 1
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _ShimmerBox(
                        animation: _controller,
                        width: 18,
                        height: 18,
                        radius: 4,
                      ),
                      const SizedBox(width: 16),
                      _ShimmerBox(
                        animation: _controller,
                        width: 42,
                        height: 42,
                        radius: 6,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ShimmerBox(
                              animation: _controller,
                              height: 12,
                              radius: 6,
                            ),
                            const SizedBox(height: 8),
                            _ShimmerBox(
                              animation: _controller,
                              height: 8,
                              radius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ShimmerBox(
                        animation: _controller,
                        width: 56,
                        height: 12,
                        radius: 6,
                      ),
                      const SizedBox(width: 16),
                      _ShimmerBox(
                        animation: _controller,
                        width: 40,
                        height: 12,
                        radius: 6,
                      ),
                      const SizedBox(width: 16),
                      _ShimmerBox(
                        animation: _controller,
                        width: 64,
                        height: 22,
                        radius: 999,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.animation,
    this.width,
    this.height = 80,
    this.radius = 20,
  });

  final Animation<double> animation;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value * 2) % 1.0;
        final base = scheme.surfaceContainerHighest;
        final highlight = scheme.surfaceContainerHigh;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
