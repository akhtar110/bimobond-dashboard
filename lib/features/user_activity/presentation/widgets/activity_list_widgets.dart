import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class ActivityListCard extends StatelessWidget {
  const ActivityListCard({
    super.key,
    required this.isDark,
    required this.child,
    this.onTap,
  });

  final bool isDark;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outlineBorder = scheme.outlineVariant.withValues(alpha: 0.5);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outlineBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ActivityErrorState extends StatelessWidget {
  const ActivityErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.isDark = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: scheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.t('tryAgain')),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityAuthorRow extends StatelessWidget {
  const ActivityAuthorRow({
    super.key,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.isDark,
  });

  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = (fullName != null && fullName!.isNotEmpty)
        ? fullName!
        : username;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Icon(Icons.person, size: 16, color: scheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
