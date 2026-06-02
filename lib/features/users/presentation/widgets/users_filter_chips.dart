import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';

class UsersFilterChips extends StatelessWidget {
  const UsersFilterChips({super.key, required this.onChanged});

  final ValueChanged<UsersUiFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<UsersBloc>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final current = state is UsersLoaded ? state.filter : UsersUiFilter.all;

    final labels = <UsersUiFilter, String>{
      UsersUiFilter.all: l10n.t('all'),
      UsersUiFilter.verified: l10n.t('verified'),
      UsersUiFilter.banned: l10n.t('banned'),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.entries.map((entry) {
          final selected = current == entry.key;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              primary,
                              primary.withValues(alpha: 0.75),
                            ],
                          )
                        : null,
                    color: selected
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0)),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    entry.value,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Kept for backward compatibility with existing imports.
typedef UsersFilterWidget = UsersFilterChips;
