import 'package:flutter/material.dart';

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? subtitle;
  final bool highlight;

  static _AnalyticsCardSizing _sizingOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) {
      return const _AnalyticsCardSizing(
        padding: 8,
        radius: 11,
        iconBox: 28,
        iconSize: 15,
        labelSize: 10.5,
        valueSize: 13.5,
        subtitleSize: 10,
        gap: 8,
      );
    }
    if (width < 700) {
      return const _AnalyticsCardSizing(
        padding: 9,
        radius: 11,
        iconBox: 30,
        iconSize: 16,
        labelSize: 11,
        valueSize: 14.5,
        subtitleSize: 10.5,
        gap: 8,
      );
    }
    if (width < 1200) {
      return const _AnalyticsCardSizing(
        padding: 10,
        radius: 12,
        iconBox: 32,
        iconSize: 17,
        labelSize: 11.5,
        valueSize: 15.5,
        subtitleSize: 11,
        gap: 9,
      );
    }
    return const _AnalyticsCardSizing(
      padding: 12,
      radius: 12,
      iconBox: 34,
      iconSize: 18,
      labelSize: 12,
      valueSize: 16.5,
      subtitleSize: 11,
      gap: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizing = _sizingOf(context);
    final bg = highlight ? scheme.primaryContainer : scheme.surface;
    final fg = highlight ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizing.radius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizing.padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: sizing.iconBox,
                height: sizing.iconBox,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlight
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(sizing.radius - 2),
                ),
                child: Icon(
                  icon,
                  size: sizing.iconSize,
                  color: highlight ? scheme.primary : scheme.primary,
                ),
              ),
              SizedBox(width: sizing.gap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: sizing.labelSize,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: fg,
                            fontSize: sizing.valueSize,
                            height: 1.15,
                          ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: sizing.subtitleSize,
                            height: 1.2,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCardSizing {
  const _AnalyticsCardSizing({
    required this.padding,
    required this.radius,
    required this.iconBox,
    required this.iconSize,
    required this.labelSize,
    required this.valueSize,
    required this.subtitleSize,
    required this.gap,
  });

  final double padding;
  final double radius;
  final double iconBox;
  final double iconSize;
  final double labelSize;
  final double valueSize;
  final double subtitleSize;
  final double gap;
}
