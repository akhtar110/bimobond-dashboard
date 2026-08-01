import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_management_header.dart';
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
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(
            left: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: ChatEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.t('selectChatToModerate'),
          subtitle: l10n.t('selectChatToModerateHint'),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChatDetailsHeader(chat: chat, state: state),
          const MessagesSelectionHeader(),
          if (state.typingUserId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
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
                        child: _ChronologicalMessagesList(
                          state: state,
                          chat: chat,
                          scrollController: scrollController,
                          useDesktopPagination: useDesktopPagination,
                          onLoadMore: onLoadMore,
                        ),
                      ),
                      if (useDesktopPagination &&
                          state.messagesMeta != null &&
                          state.messagesMeta!.total > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: AppPaginationBar(
                            currentPage: state.messagesMeta!.page,
                            lastPage: state.messagesMeta!.totalPages,
                            total: state.messagesMeta!.total,
                            pageSize: state.messagesMeta!.limit,
                            itemCount: state.messages.length,
                            hideWhenSinglePage: false,
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}


class _ChronologicalMessagesList extends StatefulWidget {
  const _ChronologicalMessagesList({
    required this.state,
    required this.chat,
    required this.scrollController,
    required this.useDesktopPagination,
    required this.onLoadMore,
  });

  final ChatManagementLoaded state;
  final ChatEntity chat;
  final ScrollController scrollController;
  final bool useDesktopPagination;
  final VoidCallback onLoadMore;

  @override
  State<_ChronologicalMessagesList> createState() =>
      _ChronologicalMessagesListState();
}

class _ChronologicalMessagesListState extends State<_ChronologicalMessagesList> {
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNewest());
  }

  @override
  void didUpdateWidget(covariant _ChronologicalMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final chatChanged = widget.chat.id != oldWidget.chat.id;
    final grew =
        widget.state.messages.length > _lastMessageCount && !chatChanged;
    final firstLoad =
        oldWidget.state.messages.isEmpty && widget.state.messages.isNotEmpty;

    if (chatChanged || firstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNewest());
    } else if (grew &&
        widget.scrollController.hasClients &&
        widget.scrollController.position.pixels >=
            widget.scrollController.position.maxScrollExtent - 80) {
      // Stay pinned near newest when already at the bottom.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNewest());
    }
    _lastMessageCount = widget.state.messages.length;
  }

  void _scrollToNewest() {
    if (!mounted || !widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    if (!position.hasContentDimensions) return;
    widget.scrollController.jumpTo(position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeline = buildChatTimeline(widget.state.messages);
    final showLoader =
        !widget.useDesktopPagination && widget.state.isLoadingMoreMessages;
    final itemCount = timeline.length + (showLoader ? 1 : 0);
    final canModerate = PermissionManager.canModerateChatAdmin(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Older pages load when scrolling toward the top (oldest messages).
        if (!widget.useDesktopPagination &&
            n.metrics.pixels <= 120 &&
            !widget.state.isLoadingMoreMessages) {
          widget.onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showLoader && index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final itemIndex = showLoader ? index - 1 : index;
          final item = timeline[itemIndex];

          if (item is ChatTimelineDateDivider) {
            return ChatDateSeparator(date: item.date);
          }

          final message = (item as ChatTimelineMessage).message;
          return MessageBubble(
            message: message,
            chat: widget.chat,
            isChecked: widget.state.selectedMessageIds.contains(message.id),
            showCheckbox: widget.state.hasMessageSelection,
            canModerate: canModerate,
            onToggleSelect: canModerate
                ? () => context.read<ChatManagementBloc>().add(
                      MessageSelectionToggled(message.id),
                    )
                : null,
            onDelete: canModerate
                ? () async {
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
                  }
                : null,
          );
        },
      ),
    );
  }
}

class ChatDetailsHeader extends StatelessWidget {
  const ChatDetailsHeader({super.key, required this.chat, required this.state});

  final ChatEntity chat;
  final ChatManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final subtitle = chat.isGroup
        ? '${l10n.t('groupChat')} · ${chat.participantCount}'
        : '${l10n.t('directChat')} · ${chat.participantCount}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _HeaderAvatars(chat: chat),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.displayTitle(directFallback: l10n.t('directChat')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.isSocketConnected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: l10n.t('liveConnected'),
                child: Icon(Icons.circle, size: 8, color: scheme.tertiary),
              ),
            ),
          IconButton(
            tooltip: l10n.t('chatInfo'),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.info_outline_rounded, size: 20, color: scheme.onSurfaceVariant),
            onPressed: () => showChatInfoDialog(context, state),
          ),
        ],
      ),
    );
  }

  static Future<void> showEditDialog(
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
              bloc.add(
                ChatMetadataUpdateRequested(
                  chatId: chat.id,
                  name: nameCtrl.text.trim(),
                  avatarUrl: avatarCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            },
            child: Text(l10n.t('saveChanges')),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatars extends StatelessWidget {
  const _HeaderAvatars({required this.chat});

  final ChatEntity chat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final participants = chat.participants.take(2).toList();

    if (chat.isGroup || participants.length < 2) {
      final url = chat.avatarUrl ?? participants.firstOrNull?.user?.avatarUrl;
      final resolved = url != null ? MediaUrlResolver.resolve(url) : null;
      return CircleAvatar(
        radius: 22,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage:
            resolved != null ? CachedNetworkImageProvider(resolved) : null,
        child: resolved == null
            ? Icon(
                chat.isGroup ? Icons.groups_rounded : Icons.person_rounded,
                color: scheme.onSurfaceVariant,
              )
            : null,
      );
    }

    return SizedBox(
      width: 52,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _HeaderSmallAvatar(url: participants[0].user?.avatarUrl),
          ),
          Positioned(
            right: 0,
            top: 6,
            child: _HeaderSmallAvatar(url: participants[1].user?.avatarUrl),
          ),
        ],
      ),
    );
  }
}

class _HeaderSmallAvatar extends StatelessWidget {
  const _HeaderSmallAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = url != null ? MediaUrlResolver.resolve(url!) : null;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surfaceContainerLowest, width: 2),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage:
            resolved != null ? CachedNetworkImageProvider(resolved) : null,
        child: resolved == null
            ? Icon(Icons.person_rounded, size: 18, color: scheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}

bool _isOutgoingMessage(ChatEntity chat, String senderId) {
  if (chat.isGroup || chat.participants.length < 2) return false;
  return chat.participants.first.userId == senderId;
}

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.chat,
    required this.isChecked,
    required this.showCheckbox,
    this.canModerate = false,
    this.onToggleSelect,
    this.onDelete,
  });

  final ChatMessageEntity message;
  final ChatEntity chat;
  final bool isChecked;
  final bool showCheckbox;
  final bool canModerate;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onDelete;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hovered = false;

  bool get _isOutgoing =>
      _isOutgoingMessage(widget.chat, widget.message.senderId);

  bool get _isRichBubble {
    return switch (widget.message.type) {
      ChatMessageType.image ||
      ChatMessageType.video ||
      ChatMessageType.postShare ||
      ChatMessageType.location => true,
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
      ChatMessageType.audio => true,
      _ => false,
    };
  }

  bool get _isCompactBubble {
    return switch (widget.message.type) {
      ChatMessageType.text || ChatMessageType.audio => true,
      ChatMessageType.unknown
          when widget.message.locationPayload == null =>
        true,
      _ => false,
    };
  }

  EdgeInsets _bubbleContentPadding(bool deleted) {
    if (deleted) return const EdgeInsets.fromLTRB(10, 7, 8, 2);
    if (_isRichBubble) return const EdgeInsets.fromLTRB(4, 4, 4, 0);
    if (_isMediaPadding && widget.message.type == ChatMessageType.audio) {
      return const EdgeInsets.fromLTRB(4, 3, 4, 0);
    }
    if (_isMediaPadding) return const EdgeInsets.fromLTRB(4, 4, 4, 0);
    if (_isCompactBubble) return const EdgeInsets.fromLTRB(10, 6, 8, 2);
    return const EdgeInsets.fromLTRB(14, 10, 12, 4);
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
    final isPostShare = message.type == ChatMessageType.postShare;
    final bubbleMaxWidth = isPostShare
        ? ChatRichPreviewSize.cardWidth + 20
        : math.min(
            _isRichBubble
                ? 280.0
                : _isCompactBubble
                ? 260.0
                : 420.0,
            width *
                (compact
                    ? 0.78
                    : (_isRichBubble
                        ? 0.42
                        : _isCompactBubble
                        ? 0.38
                        : 0.55)),
          );

    final bubbleRadius = _isCompactBubble ? 14.0 : 18.0;
    final outgoing = _isOutgoing && !widget.chat.isGroup;
    final bubbleColor = deleted
        ? scheme.surfaceContainerHighest
        : outgoing
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.75),
            const Color(0xFF5A1A2E),
          )
        : scheme.surfaceContainerHigh.withValues(alpha: 0.85);

    final radius = outgoing
        ? BorderRadius.only(
            topLeft: Radius.circular(bubbleRadius),
            topRight: Radius.circular(bubbleRadius),
            bottomLeft: Radius.circular(bubbleRadius),
            bottomRight: const Radius.circular(4),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(bubbleRadius),
            topRight: Radius.circular(bubbleRadius),
            bottomLeft: const Radius.circular(4),
            bottomRight: Radius.circular(bubbleRadius),
          );

    final bubbleContent = Column(
      crossAxisAlignment: outgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!outgoing && !widget.chat.isGroup)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
            child: Text(
              sender?.displayName ?? message.senderId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        if (widget.chat.isGroup)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
            child: Text(
              sender?.displayName ?? message.senderId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
                fontSize: 11,
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
                        outgoing: outgoing,
                      ),
                    Padding(
                      padding: _bubbleContentPadding(deleted),
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
                              outgoing: outgoing,
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        _isRichBubble && !deleted ? 8 : _isCompactBubble ? 8 : 10,
                        _isRichBubble && !deleted ? 4 : 0,
                        _isCompactBubble ? 6 : 8,
                        _isCompactBubble ? 4 : 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (deleted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.block,
                                size: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            formatChatTime(message.createdAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: outgoing
                                      ? scheme.onPrimary.withValues(alpha: 0.75)
                                      : scheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                          ),
                          if (outgoing && !deleted) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: scheme.onPrimary.withValues(alpha: 0.75),
                            ),
                          ],
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity:
                                widget.canModerate &&
                                    widget.onDelete != null &&
                                    (_hovered || compact) &&
                                    !deleted
                                ? 1
                                : 0,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: outgoing ? scheme.onPrimary : scheme.error,
                              ),
                              onPressed: deleted || widget.onDelete == null
                                  ? null
                                  : widget.onDelete,
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
          Wrap(
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
                  ),
                  child: Text(
                    '${r.emoji} ${r.user?.username ?? ''}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 5 : _isCompactBubble ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            outgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (widget.showCheckbox && widget.canModerate)
            Padding(
              padding: EdgeInsets.only(right: outgoing ? 0 : 4, left: outgoing ? 4 : 0),
              child: Checkbox(
                value: widget.isChecked,
                onChanged: (_) => widget.onToggleSelect?.call(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (!outgoing && !compact) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: () {
                final resolved = sender?.avatarUrl != null
                    ? MediaUrlResolver.resolve(sender!.avatarUrl!)
                    : null;
                return resolved != null
                    ? CachedNetworkImageProvider(resolved)
                    : null;
              }(),
              child: sender?.avatarUrl == null
                  ? const Icon(Icons.person, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubbleContent),
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
    required this.outgoing,
  });

  final ChatMessageEntity reply;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: outgoing
            ? Colors.black.withValues(alpha: 0.15)
            : scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: outgoing
                ? scheme.onPrimary.withValues(alpha: 0.6)
                : scheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        reply.content ?? l10n.t('messageDeletedPreview'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: outgoing
              ? scheme.onPrimary.withValues(alpha: 0.85)
              : scheme.onSurfaceVariant,
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
    this.outgoing = false,
  });

  final ChatMessageEntity message;
  final bool embedded;
  final bool bubbleStyle;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.25,
      fontSize: 13,
      color: outgoing ? Theme.of(context).colorScheme.onPrimary : null,
    );

    switch (message.type) {
      case ChatMessageType.image:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '', style: textStyle);
        return ChatImageMessage(
          imageUrl: url,
          embedded: embedded,
          bubbleStyle: bubbleStyle,
        );
      case ChatMessageType.video:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '', style: textStyle);
        return ChatVideoMessage(videoUrl: url);
      case ChatMessageType.audio:
        final url = message.mediaUrl != null
            ? MediaUrlResolver.resolve(message.mediaUrl!)
            : null;
        if (url == null) return Text(message.content ?? '', style: textStyle);
        return ChatAudioMessage(audioUrl: url, embedded: embedded);
      case ChatMessageType.postShare:
        return ChatPostSharePreview(
          message: message,
          bubbleStyle: bubbleStyle,
          outgoing: outgoing,
        );
      case ChatMessageType.location:
        final payload = message.locationPayload;
        if (payload != null) {
          return ChatLocationSharePreview(
            payload: payload,
            bubbleStyle: bubbleStyle,
            outgoing: outgoing,
          );
        }
        return Text(message.content ?? '', style: textStyle);
      case ChatMessageType.text:
      case ChatMessageType.unknown:
        if (message.locationPayload != null) {
          return ChatLocationSharePreview(
            payload: message.locationPayload!,
            bubbleStyle: bubbleStyle,
            outgoing: outgoing,
          );
        }
        return Text(message.content ?? '', style: textStyle);
    }
  }
}
