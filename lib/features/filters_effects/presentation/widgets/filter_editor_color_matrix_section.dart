import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class FilterEditorColorMatrixSection extends StatelessWidget {
  const FilterEditorColorMatrixSection({
    super.key,
    required this.colorMatrix,
  });

  final List<double> colorMatrix;

  @override
  Widget build(BuildContext context) {
    if (colorMatrix.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final values = colorMatrix.length >= 20
        ? colorMatrix.take(20).toList()
        : [
            ...colorMatrix,
            ...List<double>.filled(20 - colorMatrix.length, 0),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          l10n.tOr('feFilterColorMatrix', 'Color matrix'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          l10n.tOr('feFilterColorMatrixReadOnly', 'Read-only values from API'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        children: [
          Table(
            defaultColumnWidth: const FlexColumnWidth(),
            children: [
              for (var row = 0; row < 4; row++)
                TableRow(
                  children: [
                    for (var col = 0; col < 5; col++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Text(
                              _formatValue(values[row * 5 + col]),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(3);
  }
}
