import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/responsive.dart';
import 'users_page_toolbar.dart';

/// Users top bar — title, refresh, and posts-style filter toolbar.
class UsersPageHeader extends StatelessWidget {
  const UsersPageHeader({
    super.key,
    required this.onRefresh,
    required this.metrics,
  });

  final VoidCallback onRefresh;
  final UsersLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 900;
        final compact = metrics.isMobile;
        final controlHeight = metrics.filterControlHeight;
        final gap = metrics.filterGap + 2;

        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _UsersHeaderToolbarRow(
                metrics: metrics,
                controlHeight: controlHeight,
                gap: gap,
                showTitle: true,
                inlineActions: true,
                onRefresh: onRefresh,
                compact: compact,
              ),
              const UsersActiveFilterChips(),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _UsersHeaderToolbarRow(
              metrics: metrics,
              controlHeight: controlHeight,
              gap: gap,
              showTitle: true,
              inlineActions: false,
              onRefresh: onRefresh,
              compact: compact,
            ),
            SizedBox(height: gap),
            _UsersHeaderToolbarRow(
              metrics: metrics,
              controlHeight: controlHeight,
              gap: gap,
              showTitle: false,
              inlineActions: true,
              onRefresh: onRefresh,
              compact: compact,
            ),
            const UsersActiveFilterChips(),
          ],
        );
      },
    );
  }
}

class _UsersHeaderToolbarRow extends StatelessWidget {
  const _UsersHeaderToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.showTitle,
    required this.inlineActions,
    required this.onRefresh,
    required this.compact,
  });

  final UsersLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final bool showTitle;
  final bool inlineActions;
  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final refreshBtn = _UsersRefreshButton(
      onRefresh: onRefresh,
      size: controlHeight,
      compact: compact,
    );

    final toolbar = inlineActions
        ? (showTitle
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: UsersPageToolbar(metrics: metrics),
                  ),
                  SizedBox(width: gap),
                  refreshBtn,
                ],
              )
            : UsersPageToolbar(metrics: metrics))
        : null;

    if (!showTitle && inlineActions) {
      return toolbar!;
    }

    if (showTitle && !inlineActions) {
      return Row(
        children: [
          const Expanded(child: _UsersHeaderTitle()),
          refreshBtn,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _UsersHeaderTitle(),
        SizedBox(width: gap + 8),
        Expanded(child: UsersPageToolbar(metrics: metrics)),
        SizedBox(width: gap),
        refreshBtn,
      ],
    );
  }
}

class _UsersHeaderTitle extends StatelessWidget {
  const _UsersHeaderTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final scheme = theme.colorScheme;
    final fontSize = width < 480 ? 20.0 : width < 900 ? 22.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('users'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l10n.tOr(
            'usersPageSubtitle',
            'Manage platform users, permissions, account verification, and moderation history.',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _UsersRefreshButton extends StatelessWidget {
  const _UsersRefreshButton({
    required this.onRefresh,
    required this.size,
    required this.compact,
  });

  final VoidCallback onRefresh;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withValues(alpha: 0.22);

    return Tooltip(
      message: context.l10n.t('refresh'),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onRefresh,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.refresh_rounded,
              size: compact ? 18 : 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
