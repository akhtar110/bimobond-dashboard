import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/chat_entities.dart';

String formatChatTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 24) return DateFormat.jm().format(dateTime);
  if (diff.inDays < 7) return DateFormat.E().add_jm().format(dateTime);
  return DateFormat.yMMMd().add_jm().format(dateTime);
}

String formatChatListTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return DateFormat.jm().format(dateTime);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.E().format(dateTime);
  return DateFormat.MMMd().format(dateTime);
}

/// Date chip label for in-conversation separators (Today / Yesterday / date).
String formatChatDateSeparator(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (now.year == dateTime.year) return DateFormat.MMMMd().format(dateTime);
  return DateFormat.yMMMMd().format(dateTime);
}

DateTime chatMessageDay(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

sealed class ChatTimelineItem {
  const ChatTimelineItem();
}

class ChatTimelineDateDivider extends ChatTimelineItem {
  const ChatTimelineDateDivider(this.date);
  final DateTime date;
}

class ChatTimelineMessage extends ChatTimelineItem {
  const ChatTimelineMessage(this.message);
  final ChatMessageEntity message;
}

/// Builds a WhatsApp-style timeline: oldest → newest with date separators.
List<ChatTimelineItem> buildChatTimeline(List<ChatMessageEntity> messages) {
  if (messages.isEmpty) return const [];

  final sorted = List<ChatMessageEntity>.of(messages)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final items = <ChatTimelineItem>[];
  DateTime? lastDay;
  for (final message in sorted) {
    final day = chatMessageDay(message.createdAt);
    if (lastDay == null || day != lastDay) {
      items.add(ChatTimelineDateDivider(day));
      lastDay = day;
    }
    items.add(ChatTimelineMessage(message));
  }
  return items;
}

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = formatChatDateSeparator(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

String messageTypeLabel(AppLocalizations l10n, ChatMessageType type) {
  return switch (type) {
    ChatMessageType.text => l10n.t('chatMessageText'),
    ChatMessageType.image => l10n.t('chatMessageImage'),
    ChatMessageType.video => l10n.t('chatMessageVideo'),
    ChatMessageType.audio => l10n.t('chatMessageAudio'),
    ChatMessageType.postShare => l10n.t('chatMessagePostShare'),
    ChatMessageType.location => l10n.t('chatMessageLocation'),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
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
        height: 68,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
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
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (_, index) {
        final align = index.isEven
            ? Alignment.centerLeft
            : Alignment.centerRight;
        return Align(
          alignment: align,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: 180 + (index % 3) * 60.0,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
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

/// Shows [child] only when the user has `chat.admin.moderate`.
class ChatModerationGate extends StatelessWidget {
  const ChatModerationGate({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (PermissionManager.canModerateChatAdmin(context)) {
      return child;
    }
    return fallback;
  }
}
