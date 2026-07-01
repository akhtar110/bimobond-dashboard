import 'package:flutter/material.dart';

class PromotionDetailSheetFrame extends StatelessWidget {
  const PromotionDetailSheetFrame({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
              Expanded(
                child: ColoredBox(
                  color: scheme.surfaceContainerLowest,
                  child: PrimaryScrollController(
                    controller: scrollController,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
