import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';

/// Shows removable chips for active search / location / status filters.
class UsersListActiveFilters extends StatelessWidget {
  const UsersListActiveFilters({
    super.key,
    required this.metrics,
    required this.onClearSearch,
    required this.onClearLocation,
    required this.onClearStatus,
    required this.onClearAll,
  });

  final UsersLayoutMetrics metrics;
  final VoidCallback onClearSearch;
  final VoidCallback onClearLocation;
  final VoidCallback onClearStatus;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocSelector<UsersBloc, UsersState, _UsersActiveFilterSnapshot>(
      selector: (state) {
        if (state is UsersLoaded) {
          return _UsersActiveFilterSnapshot(
            query: state.query,
            locationQuery: state.locationQuery,
            filter: state.filter,
          );
        }
        return const _UsersActiveFilterSnapshot(
          query: '',
          locationQuery: '',
          filter: UsersUiFilter.all,
        );
      },
      builder: (context, snapshot) {
        if (!snapshot.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final chips = <Widget>[];

        void addChip(Widget chip) {
          if (chips.isNotEmpty) {
            chips.add(SizedBox(width: metrics.chipSpacing));
          }
          chips.add(chip);
        }

        if (snapshot.query.isNotEmpty) {
          addChip(
            _RemovableFilterChip(
              label: l10n.tOr('search', 'Search'),
              value: snapshot.query,
              onRemove: onClearSearch,
              metrics: metrics,
            ),
          );
        }

        if (snapshot.locationQuery.isNotEmpty) {
          addChip(
            _RemovableFilterChip(
              label: l10n.t('location'),
              value: snapshot.locationQuery,
              onRemove: onClearLocation,
              metrics: metrics,
            ),
          );
        }

        if (snapshot.filter != UsersUiFilter.all) {
          final statusLabel = switch (snapshot.filter) {
            UsersUiFilter.verified => l10n.t('verified'),
            UsersUiFilter.banned => l10n.t('banned'),
            UsersUiFilter.all => l10n.t('all'),
          };
          addChip(
            _RemovableFilterChip(
              label: l10n.t('status'),
              value: statusLabel,
              onRemove: onClearStatus,
              metrics: metrics,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: metrics.isMobile ? 4 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(children: chips),
                ),
              ),
              TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: metrics.isMobile ? 16 : 18,
                  color: scheme.primary,
                ),
                label: Text(l10n.t('clearAllFilters')),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.isMobile ? 8 : 12,
                    vertical: 4,
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: metrics.isMobile ? 12 : 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UsersActiveFilterSnapshot {
  const _UsersActiveFilterSnapshot({
    required this.query,
    required this.locationQuery,
    required this.filter,
  });

  final String query;
  final String locationQuery;
  final UsersUiFilter filter;

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      locationQuery.isNotEmpty ||
      filter != UsersUiFilter.all;

  @override
  bool operator ==(Object other) {
    return other is _UsersActiveFilterSnapshot &&
        other.query == query &&
        other.locationQuery == locationQuery &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(query, locationQuery, filter);
}

class _RemovableFilterChip extends StatelessWidget {
  const _RemovableFilterChip({
    required this.label,
    required this.value,
    required this.onRemove,
    required this.metrics,
  });

  final String label;
  final String value;
  final VoidCallback onRemove;
  final UsersLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = metrics.isMobile;

    return InputChip(
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSecondaryContainer,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: compact ? 11.5 : 12,
        ),
      ),
      onDeleted: onRemove,
      deleteIcon: Icon(Icons.close_rounded, size: compact ? 16 : 18),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.65),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 0 : 2,
      ),
    );
  }
}
