import 'package:flutter/material.dart';

/// Lightweight shimmer block used for skeleton loading states.
class UsersShimmerBox extends StatefulWidget {
  const UsersShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<UsersShimmerBox> createState() => _UsersShimmerBoxState();
}

class _UsersShimmerBoxState extends State<UsersShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Full-table skeleton shown while [UsersLoading] is active.
class UsersTableSkeleton extends StatelessWidget {
  const UsersTableSkeleton({super.key, this.rowCount = 10});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              const Expanded(flex: 3, child: UsersShimmerBox(height: 12)),
              const SizedBox(width: 16),
              const Expanded(flex: 2, child: UsersShimmerBox(height: 12)),
              const SizedBox(width: 16),
              const Expanded(child: UsersShimmerBox(height: 12)),
              const SizedBox(width: 16),
              const Expanded(child: UsersShimmerBox(height: 12)),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: UsersShimmerBox(height: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount,
            separatorBuilder: (_, index) => Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const UsersShimmerBox(width: 36, height: 36, borderRadius: 18),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UsersShimmerBox(height: 12),
                        SizedBox(height: 6),
                        UsersShimmerBox(width: 80, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UsersShimmerBox(height: 10),
                        SizedBox(height: 6),
                        UsersShimmerBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: UsersShimmerBox(height: 22, borderRadius: 12)),
                  const SizedBox(width: 16),
                  const Expanded(child: UsersShimmerBox(height: 8)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        Expanded(child: UsersShimmerBox(height: 28, borderRadius: 8)),
                        SizedBox(width: 6),
                        Expanded(child: UsersShimmerBox(height: 28, borderRadius: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
