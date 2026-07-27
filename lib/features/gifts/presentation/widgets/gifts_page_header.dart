import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'gifts_view_toggle.dart';

/// Compact page header — title + actions in one row, no border chrome.
class GiftsPageHeader extends StatelessWidget {
  const GiftsPageHeader({
    super.key,
    required this.isLoading,
    required this.showViewToggle,
    required this.canAdd,
    required this.onAdd,
    required this.onRefresh,
    this.compact = false,
  });

  final bool isLoading;
  final bool showViewToggle;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controlSize = compact ? 36.0 : 40.0;

    final refreshBtn = Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isLoading ? null : onRefresh,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: controlSize,
          height: controlSize,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: compact ? 18 : 20,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );

    final addBtn = compact
        ? FilledButton(
            onPressed: canAdd ? onAdd : null,
            style: FilledButton.styleFrom(
              minimumSize: Size(controlSize, controlSize),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 18),
          )
        : FilledButton.icon(
            onPressed: canAdd ? onAdd : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.t('addGift')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

    final viewToggle = showViewToggle ? const GiftsViewToggle() : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              l10n.t('gifts'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          if (viewToggle != null) ...[
            viewToggle,
            SizedBox(width: compact ? 6 : 8),
          ],
          addBtn,
          SizedBox(width: compact ? 6 : 8),
          refreshBtn,
        ],
      ),
    );
  }
}
