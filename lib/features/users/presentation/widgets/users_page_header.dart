import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../utils/responsive.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = metrics.isMobile;

    return BlocSelector<UsersBloc, UsersState, int?>(
      selector: (state) => state is UsersLoaded ? state.total : null,
      builder: (context, total) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(metrics.headerIconPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.primary.withValues(alpha: 0.55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: compact ? 12 : 16,
                    offset: Offset(0, compact ? 4 : 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: scheme.onPrimary,
                size: metrics.headerIconSize,
              ),
            ),
            SizedBox(width: metrics.headerTitleGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('users'),
                    style: (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    total != null
                        ? '${l10n.t('users')} · $total ${l10n.t('users').toLowerCase()}'
                        : l10n.t('manageAccountsSubtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: compact ? 13 : null,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onRefresh,
              tooltip: l10n.t('retry'),
              icon: Icon(
                Icons.refresh_rounded,
                size: compact ? 20 : 24,
              ),
              style: IconButton.styleFrom(
                visualDensity:
                    compact ? VisualDensity.compact : VisualDensity.standard,
                minimumSize: Size(compact ? 36 : 40, compact ? 36 : 40),
                tapTargetSize: compact
                    ? MaterialTapTargetSize.shrinkWrap
                    : MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
