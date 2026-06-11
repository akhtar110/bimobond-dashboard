import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gift_reports_bloc.dart';

class GiftReportsPaginationBar extends StatelessWidget {
  const GiftReportsPaginationBar({
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
    final bloc = context.read<GiftReportsBloc>();

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
            '$total gifts · Page $currentPage of $lastPage',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _NavButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            onTap: () => bloc.add(GoToGiftReportsPageEvent(currentPage - 1)),
          ),
          const SizedBox(width: 6),
          for (final page in visiblePages)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: _PageChip(
                page: page,
                active: page == currentPage,
                onTap: () => bloc.add(GoToGiftReportsPageEvent(page)),
              ),
            ),
          const SizedBox(width: 2),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < lastPage,
            onTap: () => bloc.add(GoToGiftReportsPageEvent(currentPage + 1)),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: enabled ? scheme.primary : scheme.outline),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.page,
    required this.active,
    required this.onTap,
  });

  final int page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
