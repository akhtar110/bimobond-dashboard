import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';
import 'users_page_toolbar.dart';

/// Modern top board header for the Users management page.
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
        final controlHeight = metrics.filterControlHeight;
        final gap = metrics.filterGap + 2;
        final compact = metrics.isMobile;

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
            SizedBox(height: gap + 2),
            UsersPageToolbar(metrics: metrics),
            const UsersActiveFilterChips(),
          ],
        );
      },
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

    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (prev, curr) {
        if (prev is UsersLoaded && curr is UsersLoaded) {
          return prev.total != curr.total;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        final totalCount = state is UsersLoaded ? state.total : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                if (totalCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
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
      },
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
