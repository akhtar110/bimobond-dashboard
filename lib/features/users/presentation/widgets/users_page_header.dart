import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/responsive.dart';

/// Compact users top bar — title + search + filters on one responsive row.
/// No subtitle; filter state stays on [UsersBloc] via the provided widgets.
class UsersPageHeader extends StatelessWidget {
  const UsersPageHeader({
    super.key,
    required this.onRefresh,
    required this.metrics,
    required this.searchBar,
    required this.locationFilter,
    required this.filters,
  });

  final VoidCallback onRefresh;
  final UsersLayoutMetrics metrics;
  final Widget searchBar;
  final Widget locationFilter;
  final Widget filters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = metrics.isMobile;

    final title = Text(
      l10n.t('users'),
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

    final refreshBtn = IconButton.filledTonal(
      onPressed: onRefresh,
      tooltip: l10n.t('retry'),
      icon: Icon(Icons.refresh_rounded, size: compact ? 18 : 20),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: Size(compact ? 34 : 36, compact ? 34 : 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Keep search + filters on one horizontal line whenever possible.
        final inlineAll = width >= 1100;
        final titleAbove = width < 640;

        final searchFilters = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: searchBar),
            SizedBox(width: metrics.chipSpacing),
            Expanded(flex: 3, child: locationFilter),
            SizedBox(width: metrics.chipSpacing + 2),
            Flexible(
              flex: 3,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: filters,
              ),
            ),
          ],
        );

        if (inlineAll) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                SizedBox(width: metrics.headerTitleGap),
                Expanded(child: searchFilters),
                SizedBox(width: metrics.chipSpacing),
                refreshBtn,
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
                    refreshBtn,
                  ],
                ),
                SizedBox(height: metrics.chipSpacing),
                searchBar,
                SizedBox(height: metrics.chipSpacing),
                locationFilter,
                SizedBox(height: metrics.chipSpacing),
                filters,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              title,
              SizedBox(width: metrics.headerTitleGap),
              Expanded(child: searchFilters),
              SizedBox(width: metrics.chipSpacing),
              refreshBtn,
            ],
          ),
        );
      },
    );
  }
}
