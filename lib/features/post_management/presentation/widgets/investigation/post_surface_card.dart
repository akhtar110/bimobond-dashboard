import 'package:flutter/material.dart';

import 'investigation_theme.dart';

class PostSurfaceCard extends StatelessWidget {
  const PostSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.dense = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < InvestigationTheme.compact;
    final resolvedPadding = padding ??
        EdgeInsets.all(
          dense || isCompact ? InvestigationTheme.s12 : InvestigationTheme.s16,
        );

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          isCompact ? InvestigationTheme.radiusSm : 16,
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dense ? 0.4 : 0.55),
        ),
        boxShadow: dense
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
