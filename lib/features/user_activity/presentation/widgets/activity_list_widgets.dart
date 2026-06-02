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
    final outlineBorder =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
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
    final display = (fullName != null && fullName!.isNotEmpty)
        ? fullName!
        : username;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Icon(Icons.person, size: 16, color: Colors.grey.shade500)
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
              color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
