import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'gifts_view_toggle.dart';

/// Page header matching [CategoriesPageHeader] spacing/structure.
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

    final refreshBtn = Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onRefresh,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 20,
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
              minimumSize: const Size(44, 40),
              padding: EdgeInsets.zero,
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
              minimumSize: const Size(120, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

    final viewToggle = showViewToggle ? const GiftsViewToggle() : null;

    final actionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewToggle != null && !compact) ...[
          viewToggle,
          const SizedBox(width: 8),
        ],
        addBtn,
        const SizedBox(width: 8),
        refreshBtn,
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('gifts'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.onSurface,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('giftsSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inline = constraints.maxWidth >= 720;
            if (inline) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actionRow,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    if (!compact) actionRow,
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ?viewToggle,
                      const Spacer(),
                      addBtn,
                      const SizedBox(width: 8),
                      refreshBtn,
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
