import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';

/// Compact sort control for the posts toolbar.
class PostsSortDropdown extends StatelessWidget {
  const PostsSortDropdown({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PostsBloc, PostsState, String>(
      selector: (state) => switch (state) {
        PostsLoaded(:final filters) => filters.sort ?? PostFilters.defaultSort,
        PostsEmpty(:final filters) => filters.sort ?? PostFilters.defaultSort,
        _ => context.read<PostsBloc>().activeFilters.sort ??
            PostFilters.defaultSort,
      },
      builder: (context, sort) {
        final isActive = sort != PostFilters.defaultSort;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('postFilterSort'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<String>(
              tooltip: l10n.t('postFilterSort'),
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                final bloc = context.read<PostsBloc>();
                final filters = bloc.activeFilters;
                if (filters.sort == value) return;
                bloc.add(
                  UpdatePostFiltersEvent(filters.copyWith(sort: value)),
                );
              },
              itemBuilder: (context) => [
                _sectionHeader(context, l10n.t('postFilterSortCreatedAt')),
                _sortItem(
                  context,
                  sort: sort,
                  value: PostFilters.sortLatest,
                  label: l10n.t('postFilterSortCreatedDesc'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: PostFilters.sortCreatedAsc,
                  label: l10n.t('postFilterSortCreatedAsc'),
                ),
                const PopupMenuDivider(),
                _sectionHeader(context, l10n.t('postFilterSortOrderedByName')),
                _sortItem(
                  context,
                  sort: sort,
                  value: PostFilters.sortAuthorAsc,
                  label: l10n.t('postFilterSortAuthorAsc'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: PostFilters.sortAuthorDesc,
                  label: l10n.t('postFilterSortAuthorDesc'),
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

  PopupMenuItem<String> _sectionHeader(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      enabled: false,
      height: 32,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
    BuildContext context, {
    required String sort,
    required String value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = sort == value;
    return PopupMenuItem<String>(
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
