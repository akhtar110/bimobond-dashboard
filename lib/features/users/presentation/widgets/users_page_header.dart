import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/responsive.dart';
import 'users_page_toolbar.dart';

/// Fully responsive Users top bar — title, subtitle, refresh button, and filter toolbar.
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
        final isDesktopWide = width >= 1150;
        final controlHeight = metrics.filterControlHeight;
        final gap = metrics.filterGap + 2;
        final compact = metrics.isMobile;

        if (isDesktopWide) {
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
                width: width,
              ),
              const UsersActiveFilterChips(),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: _UsersHeaderTitle()),
                const SizedBox(width: 8),
                _UsersRefreshButton(
                  onRefresh: onRefresh,
                  size: controlHeight,
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: gap),
            UsersPageToolbar(metrics: metrics),
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
    required this.width,
  });

  final UsersLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final bool showTitle;
  final bool inlineActions;
  final VoidCallback onRefresh;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final refreshBtn = _UsersRefreshButton(
      onRefresh: onRefresh,
      size: controlHeight,
      compact: compact,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Flexible(
          flex: 2,
          child: _UsersHeaderTitle(),
        ),
        SizedBox(width: gap + 4),
        Expanded(
          flex: 3,
          child: UsersPageToolbar(metrics: metrics),
        ),
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
    final fontSize = width < 480 ? 18.0 : width < 900 ? 21.0 : 24.0;
    final subFontSize = width < 480 ? 11.5 : 12.5;

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
        const SizedBox(height: 2),
        Text(
          l10n.tOr(
            'usersPageSubtitle',
            'Manage platform users, permissions, account verification, and moderation history.',
          ),
          maxLines: width < 600 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: subFontSize,
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
