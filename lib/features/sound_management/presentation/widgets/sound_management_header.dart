import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Page header for Sound Management (Gifts-style).
class SoundManagementHeader extends StatelessWidget {
  const SoundManagementHeader({
    super.key,
    required this.isLoading,
    required this.onAdd,
    required this.onRefresh,
    this.compact = false,
  });

  final bool isLoading;
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
            onPressed: onAdd,
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
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.tOr('soundAddTitle', 'Add sound')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

    final actionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        addBtn,
        const SizedBox(width: 8),
        refreshBtn,
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tOr('soundManagementTitle', 'Sound Management'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.onSurface,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tOr(
            'soundManagementSubtitle',
            'Manage library sounds, shelves, and bulk actions',
          ),
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
