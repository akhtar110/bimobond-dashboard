import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';

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
    final theme = Theme.of(context);

    final labels = <UsersUiFilter, String>{
      UsersUiFilter.all: l10n.t('all'),
      UsersUiFilter.verified: l10n.t('verified'),
      UsersUiFilter.banned: l10n.t('banned'),
    };

    return BlocSelector<UsersBloc, UsersState, UsersUiFilter?>(
      selector: (state) => state is UsersLoaded ? state.filter : null,
      builder: (context, loadedFilter) {
        final current = loadedFilter ?? context.read<UsersBloc>().activeFilter;
        final chips = labels.entries.map((entry) {
          final selected = current == entry.key;
          return _FilterChip(
            label: entry.value,
            selected: selected,
            metrics: metrics,
            onTap: () => onChanged(entry.key),
          );
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final useWrap = metrics.isMobile || constraints.maxWidth < 520;

            if (useWrap) {
              return Wrap(
                spacing: metrics.chipSpacing,
                runSpacing: metrics.chipSpacing,
                children: chips,
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(children: chips),
            );
          },
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.chipHorizontalPadding,
            vertical: metrics.chipVerticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.75),
                    ],
                  )
                : null,
            color: selected ? null : scheme.surface,
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: compact ? 8 : 12,
                      offset: Offset(0, compact ? 2 : 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: compact ? 12.5 : null,
              fontWeight: FontWeight.w600,
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
