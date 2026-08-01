import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../users_location_sort.dart';

/// Compact sort control for the users toolbar (location column).
class UsersSortDropdown extends StatelessWidget {
  const UsersSortDropdown({super.key, required this.height});

  final double height;

  static const defaultSort = UsersLocationSortOrder.none;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<UsersBloc, UsersState, UsersLocationSortOrder>(
      selector: (state) => switch (state) {
        UsersLoaded(:final locationSort) => locationSort,
        _ => context.read<UsersBloc>().activeLocationSort,
      },
      builder: (context, sort) {
        final isActive = sort != defaultSort;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('sortBy'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<UsersLocationSortOrder>(
              tooltip: l10n.t('sortBy'),
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                context.read<UsersBloc>().add(SetUsersLocationSortEvent(value));
              },
              itemBuilder: (context) => [
                _sortItem(
                  context,
                  sort: sort,
                  value: UsersLocationSortOrder.none,
                  label: l10n.tOr('sortDefault', 'Default'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: UsersLocationSortOrder.ascending,
                  label: l10n.tOr('locationSortAsc', 'Location A–Z'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: UsersLocationSortOrder.descending,
                  label: l10n.tOr('locationSortDesc', 'Location Z–A'),
                ),
              ],
              child: Container(
                height: height,
                width: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.swap_vert_rounded, size: 18, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<UsersLocationSortOrder> _sortItem(
    BuildContext context, {
    required UsersLocationSortOrder sort,
    required UsersLocationSortOrder value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = sort == value;
    return PopupMenuItem<UsersLocationSortOrder>(
      value: value,
      height: 36,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? scheme.primary : null,
        ),
      ),
    );
  }
}

String usersLocationSortLabel(
  AppLocalizations l10n,
  UsersLocationSortOrder sort,
) {
  return switch (sort) {
    UsersLocationSortOrder.none => l10n.tOr('sortDefault', 'Default'),
    UsersLocationSortOrder.ascending =>
      l10n.tOr('locationSortAsc', 'Location A–Z'),
    UsersLocationSortOrder.descending =>
      l10n.tOr('locationSortDesc', 'Location Z–A'),
  };
}
