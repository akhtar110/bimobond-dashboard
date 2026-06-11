import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/category_reports_bloc.dart';

class CategoryReportsPaginationBar extends StatelessWidget {
  const CategoryReportsPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<CategoryReportsBloc>();

    final visiblePages = <int>{
      for (var i = currentPage - 2; i <= currentPage + 2; i++)
        if (i >= 1 && i <= lastPage) i,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            '$total categories · Page $currentPage of $lastPage',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: currentPage > 1
                ? () => bloc.add(GoToCategoryReportsPageEvent(currentPage - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          for (final page in visiblePages)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ActionChip(
                label: Text('$page'),
                onPressed: () =>
                    bloc.add(GoToCategoryReportsPageEvent(page)),
                backgroundColor: page == currentPage
                    ? scheme.primaryContainer
                    : scheme.surface,
              ),
            ),
          IconButton(
            onPressed: currentPage < lastPage
                ? () => bloc.add(GoToCategoryReportsPageEvent(currentPage + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
