import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import 'users_pagination_bar.dart';
import 'users_shimmer.dart';
import 'users_table_config.dart';
import 'users_table_header.dart';
import 'users_table_row.dart';

class UsersTablePanel extends StatelessWidget {
  const UsersTablePanel({
    super.key,
    required this.horizontalScrollController,
  });

  final ScrollController horizontalScrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF12151C) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE6E8EC),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (state) {
                UsersLoading() => const SizedBox(
                    key: ValueKey('loading'),
                    height: double.infinity,
                    child: UsersTableSkeleton(),
                  ),
                UsersError(:final message) => _StatePanel(
                    key: const ValueKey('error'),
                    icon: Icons.cloud_off_rounded,
                    title: l10n.t('errorOccurred'),
                    message: message,
                    actionLabel: l10n.t('retry'),
                    onAction: () => context.read<UsersBloc>().add(
                          LoadUsersEvent(refresh: true),
                        ),
                    isDestructive: false,
                  ),
                UsersEmpty() => _StatePanel(
                    key: const ValueKey('empty'),
                    icon: Icons.people_outline_rounded,
                    title: l10n.t('noData'),
                    message: l10n.t('tryAdjustFilters'),
                    actionLabel: l10n.t('retry'),
                    onAction: () => context.read<UsersBloc>().add(
                          LoadUsersEvent(refresh: true),
                        ),
                    isDestructive: false,
                  ),
                UsersLoaded() => _LoadedTable(
                    key: ValueKey('loaded-${state.currentPage}-${state.filter}'),
                    state: state,
                    horizontalScrollController: horizontalScrollController,
                  ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadedTable extends StatelessWidget {
  const _LoadedTable({
    super.key,
    required this.state,
    required this.horizontalScrollController,
  });

  final UsersLoaded state;
  final ScrollController horizontalScrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final config =
                  UsersTableConfig.fromConstraints(constraints.maxWidth);
              final tableWidth = constraints.maxWidth < config.minWidth
                  ? config.minWidth
                  : constraints.maxWidth;
              final needsHorizontalScroll = constraints.maxWidth < tableWidth;

              return Scrollbar(
                controller: horizontalScrollController,
                thumbVisibility: needsHorizontalScroll,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        UsersTableHeader(config: config),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.users.length,
                            itemBuilder: (context, index) => UsersTableRow(
                              user: state.users[index],
                              config: config,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        UsersPaginationBar(
          currentPage: state.currentPage,
          lastPage: state.lastPage,
          total: state.total,
        ),
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.isDestructive,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
              child: Icon(icon, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
