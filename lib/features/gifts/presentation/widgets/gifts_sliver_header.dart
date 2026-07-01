import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/gifts_page_layout.dart';
import 'gifts_view_toggle.dart';

class GiftsSliverHeader extends StatelessWidget {
  const GiftsSliverHeader({
    required this.theme,
    required this.isLoading,
    required this.showViewToggle,
    required this.canAdd,
    required this.onAdd,
    required this.onRefresh,
  });

  final ThemeData theme;
  final bool isLoading;
  final bool showViewToggle;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (_, box) {
          final width = box.maxWidth;
          final pad = giftsPageHorizontalPadding(width);
          final narrow = width < 560;
          final toolbarNarrow = width < 720;

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

          final addBtn = narrow
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
              if (viewToggle != null && !toolbarNarrow) ...[
                viewToggle,
                const SizedBox(width: 8),
              ],
              addBtn,
              const SizedBox(width: 8),
              refreshBtn,
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1680),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('gifts'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.35,
                                    color: scheme.onSurface,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.t('giftsSubtitle'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!toolbarNarrow) actionRow,
                        ],
                      ),
                      if (toolbarNarrow) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (viewToggle != null) viewToggle,
                            const Spacer(),
                            addBtn,
                            const SizedBox(width: 8),
                            refreshBtn,
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
