import 'package:flutter/material.dart';

import '../utils/reports_center_theme.dart';

/// Compact card shell for report detail header panes.
class ReportDetailHeaderCard extends StatelessWidget {
  const ReportDetailHeaderCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: ReportsCenterTheme.detailSection(scheme),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ] else if (subtitle != null) ...[
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Two header cards side-by-side on wide screens, stacked on narrow.
class ReportDetailHeaderSplit extends StatelessWidget {
  const ReportDetailHeaderSplit({
    super.key,
    required this.start,
    required this.end,
    this.spacing = 12,
    this.breakpoint = 720,
  });

  final Widget start;
  final Widget end;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= breakpoint;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: start),
              SizedBox(width: spacing),
              Expanded(child: end),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            start,
            SizedBox(height: spacing),
            end,
          ],
        );
      },
    );
  }
}
