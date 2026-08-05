import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Sticky footer: Reset · Close.
class GiftsFilterFooter extends StatelessWidget {
  const GiftsFilterFooter({
    super.key,
    required this.onReset,
    required this.onCancel,
    this.onApply,
  });

  final VoidCallback onReset;
  final VoidCallback onCancel;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.1,
        );

    ButtonStyle outlinedStyle() => OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: labelStyle,
        );

    return Material(
      color: scheme.surface,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: outlinedStyle(),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.tOr('resetFilters', 'Reset'),
                      maxLines: 1,
                      softWrap: false,
                      style: labelStyle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onCancel,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: labelStyle?.copyWith(color: scheme.onPrimary),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.tOr('close', 'Close'),
                      maxLines: 1,
                      softWrap: false,
                      style: labelStyle?.copyWith(color: scheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
