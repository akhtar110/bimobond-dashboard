import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';

/// Compact filter chips — always a single horizontal row (scrolls if needed).
class UsersFilterChips extends StatelessWidget {
  const UsersFilterChips({
    super.key,
    required this.onChanged,
    required this.metrics,
  });

  final ValueChanged<UsersUiFilter> onChanged;
  final UsersLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final isRtl = context.isRtl;
    final labels = <UsersUiFilter, String>{
      UsersUiFilter.all: l10n.t('all'),
      UsersUiFilter.online: '🟢 ${l10n.tOr('online', isRtl ? 'متصل' : 'Online')}',
      UsersUiFilter.offline: '⚪ ${l10n.tOr('offline', isRtl ? 'غير متصل' : 'Offline')}',
      UsersUiFilter.verified: l10n.t('verified'),
      UsersUiFilter.banned: l10n.t('banned'),
    };

    return BlocSelector<UsersBloc, UsersState, UsersUiFilter?>(
      selector: (state) => state is UsersLoaded ? state.filter : null,
      builder: (context, loadedFilter) {
        final current = loadedFilter ?? context.read<UsersBloc>().activeFilter;
        final chips = <Widget>[];
        for (final entry in labels.entries) {
          if (chips.isNotEmpty) {
            chips.add(SizedBox(width: metrics.chipSpacing));
          }
          chips.add(
            _FilterChip(
              label: entry.value,
              selected: current == entry.key,
              metrics: metrics,
              onTap: () => onChanged(entry.key),
            ),
          );
        }

        return SizedBox(
          height: metrics.searchFieldHeight,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: chips,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final UsersLayoutMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = metrics.isMobile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.chipHorizontalPadding,
            vertical: metrics.chipVerticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? scheme.primary : scheme.surfaceContainerLow,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : scheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: compact ? 12 : 12.5,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kept for backward compatibility with existing imports.
typedef UsersFilterWidget = UsersFilterChips;
