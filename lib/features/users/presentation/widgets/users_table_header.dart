import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'users_table_config.dart';

const double kUsersTableHeaderHeight = 36;

class UsersTableHeader extends StatelessWidget {
  const UsersTableHeader({super.key, required this.config});

  final UsersTableConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 0.2,
        );

    return Container(
      height: kUsersTableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: config.checkboxWidth,
            child: Text('', style: labelStyle),
          ),
          Expanded(
            flex: config.showAccount ? 28 : 36,
            child: Text(l10n.t('userColumn'), style: labelStyle),
          ),
          if (config.showAccount)
            Expanded(
              flex: 22,
              child: Text(l10n.t('accountColumn'), style: labelStyle),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 14,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.t('status'), style: labelStyle),
            ),
          ),
          if (config.showEngagement) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 16,
              child: Text(l10n.t('engagement'), style: labelStyle),
            ),
          ],
          Expanded(
            flex: config.showAccount ? 28 : 34,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(l10n.t('actions'), style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}
