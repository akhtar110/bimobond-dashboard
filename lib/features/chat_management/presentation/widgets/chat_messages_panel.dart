import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_message_media.dart';
import 'chat_message_rich_previews.dart';
import 'chat_ui_shared.dart';
import 'messages_selection_header.dart';

class ChatMessagesPanel extends StatelessWidget {
  const ChatMessagesPanel({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onLoadMore,
    this.useDesktopPagination = false,
  });

  final ChatManagementLoaded state;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final bool useDesktopPagination;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 560;
              final search = TextField(
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
              );

              final chips = [
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
                  onSelected: (selected) =>
                      context.read<ChatManagementBloc>().add(
                            MessagesDeletedFilterChanged(
                              selected
                                  ? ChatDeletedFilter.deletedOnly
                                  : ChatDeletedFilter.all,
                            ),
                          ),
                ),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: chips),
                  ],
                );
              }

              return Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(width: 220, child: search),
                  ...chips,
                ],
              );
            },
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
                  : Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (!useDesktopPagination &&
                                  n.metrics.pixels >=
                                      n.metrics.maxScrollExtent - 120 &&
                                  !state.isLoadingMoreMessages) {
                                onLoadMore();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              itemCount: state.messages.length +
                                  (!useDesktopPagination &&
                                          state.isLoadingMoreMessages
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index >= state.messages.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final message = state.messages[index];
                                return MessageBubble(
                                  message: message,
                                  isChecked: state.selectedMessageIds
                                      .contains(message.id),
                                  onToggleSelect: () => context
                                      .read<ChatManagementBloc>()
                                      .add(
                                        MessageSelectionToggled(message.id),
                                      ),
                                  onDelete: () async {
                                    final ok =
                                        await confirmChatModerationAction(
                                      context,
                                      title: l10n.t('deleteMessageTitle'),
                                      message:
                                          l10n.t('deleteMessageConfirm'),
                                      destructive: true,
                                    );
                                    if (ok && context.mounted) {
                                      context
                                          .read<ChatManagementBloc>()
                                          .add(
                                            MessageDeleteRequested(
                                              message.id,
                                            ),
                                          );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        if (useDesktopPagination &&
                            state.messagesMeta != null &&
                            state.messagesMeta!.total > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            child: AppPaginationBar(
                              currentPage: state.messagesMeta!.page,
                              lastPage: state.messagesMeta!.totalPages,
                              total: state.messagesMeta!.total,
                              pageSize: state.messagesMeta!.limit,
                              itemCount: state.messages.length,
                              hideWhenSinglePage: false,
                              borderRadius: BorderRadius.circular(10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              onPageChanged: (page) => context
                                  .read<ChatManagementBloc>()
                                  .add(MessagesGoToPageRequested(page)),
                            ),
                          ),
                      ],
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
      ChatMessageTypeFilter.location => l10n.t('chatMessageLocation'),
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
    final narrow = MediaQuery.sizeOf(context).width < 720;

    final actions = [
      if (state.isSocketConnected)
        Tooltip(
          message: l10n.t('liveConnected'),
          child: Icon(Icons.circle, size: 10, color: scheme.tertiary),
        ),
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
          final buffer =
              StringBuffer('chatId,messageId,sender,type,content,createdAt\n');
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
      if (narrow)
        IconButton(
          tooltip: l10n.t('delete'),
          style: IconButton.styleFrom(
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
          icon: const Icon(Icons.delete_outline_rounded),
        )
      else
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
    ];

    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 10 : 14,
          vertical: narrow ? 8 : 12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: narrow ? 16 : 20,
              child: Icon(
                chat.isGroup ? Icons.groups_rounded : Icons.person_rounded,
                size: narrow ? 18 : 24,
              ),
            ),
            SizedBox(width: narrow ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayTitle(directFallback: l10n.t('directChat')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: narrow ? 14 : null,
                    ),
                  ),
                  Text(
                    '${chat.isGroup ? l10n.t('groupChat') : l10n.t('directChat')} · ${chat.participantCount} · ${formatChatTime(chat.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            ...[
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: narrow ? 2 : 4),
                actions[i],
              ],
            ],
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

  bool get _isRichBubble {
    return switch (widget.message.type) {
      ChatMessageType.image ||
      ChatMessageType.video ||
      ChatMessageType.postShare ||
      ChatMessageType.location =>
        true,
      ChatMessageType.text || ChatMessageType.unknown
          when widget.message.locationPayload != null =>
        true,
      _ => false,
    };
  }

  bool get _isMediaPadding {
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final bubbleMaxWidth = math.min(
      _isRichBubble ? 300.0 : 420.0,
      width * (compact ? 0.78 : (_isRichBubble ? 0.42 : 0.55)),
    );

    final bubbleColor = deleted
        ? scheme.surfaceContainerHighest
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surfaceContainerLow,
          );

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(18),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Checkbox(
            value: widget.isChecked,
            onChanged: (_) => widget.onToggleSelect(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          if (!compact) ...[
            CircleAvatar(
              radius: 15,
              backgroundImage: () {
                final resolved = sender?.avatarUrl != null
                    ? MediaUrlResolver.resolve(sender!.avatarUrl!)
                    : null;
                return resolved != null
                    ? CachedNetworkImageProvider(resolved)
                    : null;
              }(),
              child: sender?.avatarUrl == null
                  ? const Icon(Icons.person, size: 15)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 3),
                  child: Text(
                    sender?.displayName ?? message.senderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                          fontSize: compact ? 11 : null,
                        ),
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
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
                              padding: deleted
                                  ? const EdgeInsets.fromLTRB(12, 10, 10, 4)
                                  : _isRichBubble
                                      ? const EdgeInsets.fromLTRB(3, 3, 3, 0)
                                      : _isMediaPadding
                                          ? const EdgeInsets.fromLTRB(4, 4, 4, 0)
                                          : const EdgeInsets.fromLTRB(
                                              12, 10, 10, 4),
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
                                      bubbleStyle: true,
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                _isRichBubble && !deleted ? 8 : 10,
                                _isRichBubble && !deleted ? 4 : 0,
                                6,
                                6,
                              ),
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
                                    opacity: (_hovered || compact) && !deleted
                                        ? 1
                                        : 0,
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
                    padding: const EdgeInsetsDirectional.only(start: 4),
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
    this.bubbleStyle = false,
  });

  final ChatMessageEntity message;
  final bool embedded;
  final bool bubbleStyle;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.image:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '');
        return ChatImageMessage(
          imageUrl: url,
          embedded: embedded,
          bubbleStyle: bubbleStyle,
        );
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
        return ChatPostSharePreview(
          message: message,
          bubbleStyle: bubbleStyle,
        );
      case ChatMessageType.location:
        final payload = message.locationPayload;
        if (payload != null) {
          return ChatLocationSharePreview(
            payload: payload,
            bubbleStyle: bubbleStyle,
          );
        }
        return Text(message.content ?? '');
      case ChatMessageType.text:
      case ChatMessageType.unknown:
        if (message.locationPayload != null) {
          return ChatLocationSharePreview(
            payload: message.locationPayload!,
            bubbleStyle: bubbleStyle,
          );
        }
        return Text(
          message.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
              ),
        );
    }
  }
}

