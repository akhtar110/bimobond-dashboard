import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';

class UsersPaginationBar extends StatelessWidget {
  const UsersPaginationBar({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<UsersBloc>();

    final visiblePages = <int>{
      for (var i = currentPage - 2; i <= currentPage + 2; i++)
        if (i >= 1 && i <= lastPage) i,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final pageControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIconButton(
                icon: Icons.chevron_left_rounded,
                enabled: currentPage > 1,
                onTap: () => bloc.add(GoToUsersPageEvent(currentPage - 1)),
              ),
              const SizedBox(width: 6),
              for (final page in visiblePages)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _PageNumberButton(
                    page: page,
                    isActive: page == currentPage,
                    onTap: () => bloc.add(GoToUsersPageEvent(page)),
                  ),
                ),
              const SizedBox(width: 2),
              _PageIconButton(
                icon: Icons.chevron_right_rounded,
                enabled: currentPage < lastPage,
                onTap: () => bloc.add(GoToUsersPageEvent(currentPage + 1)),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                Text(
                  '${context.tr('usersCountSummary', {'count': '$total'})} · '
                  '${context.tr('pageRange', {
                    'current': '$currentPage',
                    'last': '$lastPage',
                  })}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                pageControls,
              ],
            );
          }

          return Row(
            children: [
              Text(
                context.tr('usersCountSummary', {'count': '$total'}),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${context.tr('pageRange', {
                  'current': '$currentPage',
                  'last': '$lastPage',
                })}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              pageControls,
            ],
          );
        },
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: scheme.primary.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isActive
                ? LinearGradient(
                    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
                  )
                : null,
            color: isActive ? null : scheme.surface,
            border: Border.all(
              color: isActive ? Colors.transparent : scheme.outlineVariant,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$page',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? scheme.outlineVariant
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
