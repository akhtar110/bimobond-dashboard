import 'package:flutter/material.dart';

class UserActivityShimmerBox extends StatefulWidget {
  const UserActivityShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
    this.isDark = false,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isDark;

  @override
  State<UserActivityShimmerBox> createState() => _UserActivityShimmerBoxState();
}

class _UserActivityShimmerBoxState extends State<UserActivityShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.lerp(base, highlight, _controller.value)!,
                Color.lerp(highlight, base, _controller.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserActivityListShimmer extends StatelessWidget {
  const UserActivityListShimmer({super.key, required this.isDark, this.count = 4});

  final bool isDark;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserActivityShimmerBox(
                  width: 56,
                  height: 56,
                  borderRadius: 14,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserActivityShimmerBox(
                        height: 14,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      UserActivityShimmerBox(
                        width: 120,
                        height: 12,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            UserActivityShimmerBox(height: 8, isDark: isDark),
            const SizedBox(height: 8),
            UserActivityShimmerBox(width: 180, height: 8, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class UserActivityPostsGridShimmer extends StatelessWidget {
  const UserActivityPostsGridShimmer({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => UserActivityShimmerBox(
        height: 160,
        borderRadius: 16,
        isDark: isDark,
      ),
    );
  }
}
