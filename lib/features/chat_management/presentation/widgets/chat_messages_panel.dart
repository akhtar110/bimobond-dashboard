import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_message_media.dart';
import 'chat_ui_shared.dart';
import 'messages_selection_header.dart';

class ChatMessagesPanel extends StatelessWidget {
  const ChatMessagesPanel({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onLoadMore,
  });

  final ChatManagementLoaded state;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final chat = state.selectedChat;

    if (chat == null) {
      return ChatEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: l10n.t('selectChatToModerate'),
        subtitle: l10n.t('selectChatToModerateHint'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChatDetailsHeader(chat: chat, state: state),
        const MessagesSelectionHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  key: ValueKey(
                    'msg-search-${chat.id}-${state.messagesFilterRevision}',
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.t('searchMessages'),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => context
                      .read<ChatManagementBloc>()
                      .add(MessagesSearchChanged(v)),
                ),
              ),
              for (final filter in ChatMessageTypeFilter.values)
                FilterChip(
                  label: Text(_msgTypeLabel(l10n, filter)),
                  selected: state.messagesQuery.typeFilter == filter,
                  onSelected: (selected) {
                    final bloc = context.read<ChatManagementBloc>();
                    if (filter == ChatMessageTypeFilter.all || selected) {
                      bloc.add(MessagesTypeFilterChanged(filter));
                    } else {
                      bloc.add(
                        const MessagesTypeFilterChanged(
                          ChatMessageTypeFilter.all,
                        ),
                      );
                    }
                  },
                ),
              FilterChip(
                label: Text(l10n.t('deletedMessagesOnly')),
                selected: state.messagesQuery.deletedFilter ==
                    ChatDeletedFilter.deletedOnly,
                onSelected: (selected) => context.read<ChatManagementBloc>().add(
                      MessagesDeletedFilterChanged(
                        selected
                            ? ChatDeletedFilter.deletedOnly
                            : ChatDeletedFilter.all,
                      ),
                    ),
              ),
            ],
          ),
        ),
        if (state.typingUserId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('userTyping'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.isLoadingMessages && state.messages.isEmpty
              ? const ChatMessagesSkeleton()
              : state.messages.isEmpty
                  ? ChatEmptyState(
                      icon: Icons.sms_outlined,
                      title: l10n.t('noMessagesFound'),
                      subtitle: l10n.t('noMessagesFoundHint'),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 120 &&
                            !state.isLoadingMoreMessages) {
                          onLoadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: state.messages.length +
                            (state.isLoadingMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.messages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final message = state.messages[index];
                          return MessageBubble(
                            message: message,
                            isChecked:
                                state.selectedMessageIds.contains(message.id),
                            onToggleSelect: () => context
                                .read<ChatManagementBloc>()
                                .add(MessageSelectionToggled(message.id)),
                            onDelete: () async {
                              final ok = await confirmChatModerationAction(
                                context,
                                title: l10n.t('deleteMessageTitle'),
                                message: l10n.t('deleteMessageConfirm'),
                                destructive: true,
                              );
                              if (ok && context.mounted) {
                                context.read<ChatManagementBloc>().add(
                                      MessageDeleteRequested(message.id),
                                    );
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _msgTypeLabel(AppLocalizations l10n, ChatMessageTypeFilter filter) {
    return switch (filter) {
      ChatMessageTypeFilter.all => l10n.t('filterAll'),
      ChatMessageTypeFilter.text => l10n.t('chatMessageText'),
      ChatMessageTypeFilter.image => l10n.t('chatMessageImage'),
      ChatMessageTypeFilter.video => l10n.t('chatMessageVideo'),
      ChatMessageTypeFilter.audio => l10n.t('chatMessageAudio'),
      ChatMessageTypeFilter.postShare => l10n.t('chatMessagePostShare'),
    };
  }
}

class ChatDetailsHeader extends StatelessWidget {
  const ChatDetailsHeader({
    super.key,
    required this.chat,
    required this.state,
  });

  final ChatEntity chat;
  final ChatManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatManagementBloc>();

    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Icon(
                chat.isGroup ? Icons.groups_rounded : Icons.person_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayTitle(directFallback: l10n.t('directChat')),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${chat.isGroup ? l10n.t('groupChat') : l10n.t('directChat')} · ${chat.participantCount} · ${formatChatTime(chat.createdAt)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (state.isSocketConnected)
              Tooltip(
                message: l10n.t('liveConnected'),
                child: Icon(Icons.circle, size: 10, color: scheme.tertiary),
              ),
            const SizedBox(width: 8),
            if (chat.isGroup)
              IconButton(
                tooltip: l10n.t('editChat'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditDialog(context, chat, bloc),
              ),
            IconButton(
              tooltip: l10n.t('exportLogs'),
              icon: const Icon(Icons.download_outlined),
              onPressed: () {
                final buffer = StringBuffer('chatId,messageId,sender,type,content,createdAt\n');
                for (final m in state.messages) {
                  buffer.writeln(
                    '"${m.chatId}","${m.id}","${m.senderId}","${m.type.name}","${(m.content ?? '').replaceAll('"', '""')}","${m.createdAt.toIso8601String()}"',
                  );
                }
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('chatExportCopied'))),
                );
              },
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
              ),
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final ok = await confirmChatModerationAction(
                        context,
                        title: l10n.t('deleteChatTitle'),
                        message: l10n.t('deleteChatConfirm'),
                        destructive: true,
                      );
                      if (ok && context.mounted) {
                        bloc.add(ChatDeleteRequested(chat.id));
                      }
                    },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(l10n.t('delete')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ChatEntity chat,
    ChatManagementBloc bloc,
  ) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: chat.name ?? '');
    final avatarCtrl = TextEditingController(text: chat.avatarUrl ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('editChat')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.t('chatName')),
            ),
            TextField(
              controller: avatarCtrl,
              decoration: InputDecoration(labelText: l10n.t('chatAvatarUrl')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              bloc.add(ChatMetadataUpdateRequested(
                chatId: chat.id,
                name: nameCtrl.text.trim(),
                avatarUrl: avatarCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: Text(l10n.t('saveChanges')),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isChecked,
    required this.onToggleSelect,
    required this.onDelete,
  });

  final ChatMessageEntity message;
  final bool isChecked;
  final VoidCallback onToggleSelect;
  final VoidCallback onDelete;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hovered = false;

  bool get _isMediaMessage {
    return switch (widget.message.type) {
      ChatMessageType.image ||
      ChatMessageType.video ||
      ChatMessageType.audio =>
        true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final message = widget.message;
    final sender = message.sender;
    final deleted = message.isDeleted;
    final bubbleColor = deleted
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Checkbox(
              value: widget.isChecked,
              onChanged: (_) => widget.onToggleSelect(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundImage: () {
              final resolved = sender?.avatarUrl != null
                  ? MediaUrlResolver.resolve(sender!.avatarUrl!)
                  : null;
              return resolved != null
                  ? CachedNetworkImageProvider(resolved)
                  : null;
            }(),
            child: sender?.avatarUrl == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    sender?.displayName ?? message.senderId,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (message.replyTo != null)
                              _ReplyQuote(
                                reply: message.replyTo!,
                                l10n: l10n,
                                scheme: scheme,
                              ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                _isMediaMessage && !deleted ? 4 : 12,
                                _isMediaMessage && !deleted ? 4 : 10,
                                8,
                                6,
                              ),
                              child: deleted
                                  ? Text(
                                      l10n.t('messageDeletedPreview'),
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : _MessageBody(
                                      message: message,
                                      embedded: true,
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 6, 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (deleted)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.block,
                                        size: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  Text(
                                    formatChatTime(message.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 10.5,
                                        ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: _hovered && !deleted ? 1 : 0,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 15,
                                        color: scheme.error,
                                      ),
                                      onPressed:
                                          deleted ? null : widget.onDelete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (message.reactions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final r in message.reactions)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${r.emoji} ${r.user?.username ?? ''}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.reply,
    required this.l10n,
    required this.scheme,
  });

  final ChatMessageEntity reply;
  final AppLocalizations l10n;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 3),
        ),
      ),
      child: Text(
        reply.content ?? l10n.t('messageDeletedPreview'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    this.embedded = false,
  });

  final ChatMessageEntity message;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.image:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '');
        return ChatImageMessage(imageUrl: url, embedded: embedded);
      case ChatMessageType.video:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '');
        return ChatVideoMessage(videoUrl: url);
      case ChatMessageType.audio:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '');
        return ChatAudioMessage(audioUrl: url, embedded: embedded);
      case ChatMessageType.postShare:
        return _PostSharePreview(message: message);
      case ChatMessageType.text:
      case ChatMessageType.unknown:
        return Text(
          message.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
              ),
        );
    }
  }
}

class _PostSharePreview extends StatelessWidget {
  const _PostSharePreview({required this.message});

  final ChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.share_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.sharedPostId ?? message.content ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
