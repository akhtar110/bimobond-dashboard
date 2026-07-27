import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Compact Sound Management top bar — no subtitle or card chrome.
/// Optional [toolbar] (search + filters) sits on the same row on wide screens.
class SoundManagementHeader extends StatelessWidget {
  const SoundManagementHeader({
    super.key,
    required this.isLoading,
    required this.onAdd,
    required this.onRefresh,
    this.toolbar,
    this.compact = false,
  });

  final bool isLoading;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;
  final Widget? toolbar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = Text(
      l10n.tOr('soundManagementTitle', 'Sound Management'),
      style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
          ?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
        color: scheme.onSurface,
        height: 1.05,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final controlHeight = compact ? 34.0 : 36.0;

    final refreshBtn = IconButton.filledTonal(
      onPressed: isLoading ? null : onRefresh,
      tooltip: l10n.t('retry'),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurfaceVariant,
              ),
            )
          : Icon(Icons.refresh_rounded, size: compact ? 18 : 20),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: Size(controlHeight, controlHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    final addBtn = compact
        ? FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: Size(controlHeight, controlHeight),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              minimumSize: Size(0, controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        addBtn,
        SizedBox(width: compact ? 6 : 8),
        refreshBtn,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inlineAll = toolbar != null && width >= 960;
        final titleAbove = width < 640;
        final gap = compact ? 6.0 : 8.0;

        if (inlineAll) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: title),
                SizedBox(width: gap + 4),
                Expanded(child: toolbar!),
                SizedBox(width: gap),
                actions,
              ],
            ),
          );
        }

        if (toolbar == null) {
          if (titleAbove && compact) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  SizedBox(height: gap),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actions,
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Row(
              children: [
                Expanded(child: title),
                SizedBox(width: gap),
                actions,
              ],
            ),
          );
        }

        if (titleAbove) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                ),
                SizedBox(height: gap),
                toolbar!,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(child: title),
                  SizedBox(width: gap),
                  actions,
                ],
              ),
              SizedBox(height: gap),
              toolbar!,
            ],
          ),
        );
      },
    );
  }
}
