import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'users_table_config.dart';

class UsersTableHeader extends StatelessWidget {
  const UsersTableHeader({super.key, required this.config});

  final UsersTableConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: config.showAccount ? 28 : 36,
            child: Text(l10n.t('userColumn').toUpperCase(), style: labelStyle),
          ),
          if (config.showAccount)
            Expanded(
              flex: 22,
              child: Text(
                l10n.t('accountColumn').toUpperCase(),
                style: labelStyle,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 14,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.t('status').toUpperCase(), style: labelStyle),
            ),
          ),
          if (config.showEngagement) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 16,
              child: Text(
                l10n.t('engagement').toUpperCase(),
                style: labelStyle,
              ),
            ),
          ],
          Expanded(
            flex: config.showAccount ? 28 : 34,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                l10n.t('actions').toUpperCase(),
                style: labelStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
