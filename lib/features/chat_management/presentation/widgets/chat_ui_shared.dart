import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/chat_entities.dart';

String formatChatTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 24) return DateFormat.Hm().format(dateTime);
  if (diff.inDays < 7) return DateFormat.E().add_Hm().format(dateTime);
  return DateFormat.yMMMd().add_Hm().format(dateTime);
}

String messageTypeLabel(AppLocalizations l10n, ChatMessageType type) {
  return switch (type) {
    ChatMessageType.text => l10n.t('chatMessageText'),
    ChatMessageType.image => l10n.t('chatMessageImage'),
    ChatMessageType.video => l10n.t('chatMessageVideo'),
    ChatMessageType.audio => l10n.t('chatMessageAudio'),
    ChatMessageType.postShare => l10n.t('chatMessagePostShare'),
    ChatMessageType.unknown => l10n.t('chatMessageText'),
  };
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, index) {
        final align = index.isEven ? Alignment.centerLeft : Alignment.centerRight;
        return Align(
          alignment: align,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 220 + (index % 3) * 40.0,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}

Future<bool> confirmChatModerationAction(
  BuildContext context, {
  required String title,
  required String message,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: destructive ? scheme.error : scheme.primary,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.t('confirmAction')),
        ),
      ],
    ),
  );
  return result == true;
}
