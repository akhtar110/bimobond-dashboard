import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class UsersLoadMoreIndicator extends StatelessWidget {
  const UsersLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class UsersEndOfListLabel extends StatelessWidget {
  const UsersEndOfListLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 28, height: 1, color: dividerColor),
          const SizedBox(width: 10),
          Text(
            l10n.tOr('allUsersLoaded', 'All users loaded'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 10),
          Container(width: 28, height: 1, color: dividerColor),
        ],
      ),
    );
  }
}
