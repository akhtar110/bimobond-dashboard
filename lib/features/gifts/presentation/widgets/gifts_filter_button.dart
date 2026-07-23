import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Modern filter trigger with optional active-count badge.
class GiftsFilterButton extends StatefulWidget {
  const GiftsFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
    this.height = 48,
  });

  final int activeCount;
  final VoidCallback onPressed;
  final double height;

  @override
  State<GiftsFilterButton> createState() => _GiftsFilterButtonState();
}

class _GiftsFilterButtonState extends State<GiftsFilterButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasActive = widget.activeCount > 0;
    final label = hasActive
        ? l10n.tOr(
            'giftFiltersWithCount',
            'Filters ({count})',
          ).replaceAll('{count}', '${widget.activeCount}')
        : l10n.tOr('filters', 'Filters');

    final bg = hasActive
        ? scheme.primaryContainer
        : _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLow;
    final fg = hasActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final border = hasActive
        ? scheme.primary
        : scheme.outline.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.18,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: l10n.tOr('giftOpenFiltersTooltip', 'Open filters'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.activeCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
