import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Reusable empty / permission-denied state for list panels.
class PermissionDeniedState extends StatelessWidget {
  const PermissionDeniedState({
    super.key,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(l10n.t('tryAgain')),
            ),
          ],
        ],
      ),
    );
  }
}
