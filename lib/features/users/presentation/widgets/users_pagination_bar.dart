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
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<UsersBloc>();
    final l10n = context.l10n;

    final visiblePages = <int>{
      for (var i = currentPage - 2; i <= currentPage + 2; i++)
        if (i >= 1 && i <= lastPage) i,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF1),
          ),
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
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
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
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${context.tr('pageRange', {
                  'current': '$currentPage',
                  'last': '$lastPage',
                })}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
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
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: primary.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isActive
                ? LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.8)],
                  )
                : null,
            color: isActive
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0)),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
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
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : const Color(0xFF64748B)),
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

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
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? primary
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
