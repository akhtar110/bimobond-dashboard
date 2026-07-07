import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_ui_shared.dart';
import 'chats_selection_header.dart';

class ChatListPanel extends StatelessWidget {
  const ChatListPanel({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('chatManagementTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: ValueKey('chat-search-${state.listFilterRevision}'),
                  decoration: InputDecoration(
                    hintText: l10n.t('searchChats'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => context
                      .read<ChatManagementBloc>()
                      .add(ChatsSearchChanged(v)),
                ),
                const SizedBox(height: 8),
                AdminUserSearchField(
                  key: ValueKey('chat-user-${state.listFilterRevision}'),
                  selectedUser: state.filterUser,
                  label: l10n.t('filterChatsByUser'),
                  hintText: l10n.t('notificationSearchUsersHint'),
                  onUserSelected: (user) => context
                      .read<ChatManagementBloc>()
                      .add(ChatsParticipantFilterChanged(user)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in ChatTypeFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(_typeLabel(l10n, filter)),
                            selected: state.listQuery.typeFilter == filter,
                            onSelected: (selected) {
                              final bloc = context.read<ChatManagementBloc>();
                              if (selected || filter == ChatTypeFilter.all) {
                                bloc.add(ChatsTypeFilterChanged(filter));
                              } else {
                                bloc.add(
                                  const ChatsTypeFilterChanged(
                                    ChatTypeFilter.all,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: Text(l10n.t('resetFilters')),
                        onPressed: () => context
                            .read<ChatManagementBloc>()
                            .add(const ChatsFiltersReset()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ChatsSelectionHeader(),
          Expanded(
            child: state.isLoadingChats && state.chats.isEmpty
                ? const ChatListSkeleton()
                : state.chats.isEmpty
                    ? ChatEmptyState(
                        icon: state.failureMessage != null
                            ? Icons.error_outline_rounded
                            : Icons.forum_outlined,
                        title: state.failureMessage ?? l10n.t('noChatsFound'),
                        subtitle: state.failureMessage != null
                            ? l10n.t('noChatsFoundHint')
                            : l10n.t('noChatsFoundHint'),
                        actionLabel:
                            state.failureMessage != null ? l10n.t('retry') : null,
                        onAction: state.failureMessage != null
                            ? () => context
                                .read<ChatManagementBloc>()
                                .add(const ChatsRefreshed())
                            : null,
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >=
                                  n.metrics.maxScrollExtent - 120 &&
                              !state.isLoadingMoreChats) {
                            onLoadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                          itemCount: state.chats.length +
                              (state.isLoadingMoreChats ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.chats.length) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final chat = state.chats[index];
                            return ChatCard(
                              chat: chat,
                              isSelected: state.selectedChat?.id == chat.id,
                              isChecked: state.selectedChatIds.contains(chat.id),
                              onTap: () => context
                                  .read<ChatManagementBloc>()
                                  .add(ChatSelected(chat.id)),
                              onCheckChanged: () => context
                                  .read<ChatManagementBloc>()
                                  .add(ChatSelectionToggled(chat.id)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, ChatTypeFilter filter) {
    return switch (filter) {
      ChatTypeFilter.all => l10n.t('filterAll'),
      ChatTypeFilter.group => l10n.t('chatFilterGroup'),
      ChatTypeFilter.direct => l10n.t('chatFilterDirect'),
    };
  }
}

class ChatCard extends StatefulWidget {
  const ChatCard({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
    required this.onCheckChanged,
  });

  final ChatEntity chat;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;
  final VoidCallback onCheckChanged;

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final chat = widget.chat;
    final preview = chat.lastMessage?.isDeleted == true
        ? l10n.t('messageDeletedPreview')
        : chat.lastMessage?.content ??
            messageTypeLabel(l10n, chat.lastMessage?.type ?? ChatMessageType.text);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : _hovered
                  ? scheme.surfaceContainerHigh
                  : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? scheme.primary.withValues(alpha: 0.45)
                : scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Checkbox(
                  value: widget.isChecked,
                  onChanged: (_) => widget.onCheckChanged(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                _ChatAvatar(chat: chat),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.displayTitle(
                                directFallback: l10n.t('directChat'),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            formatChatTime(chat.updatedAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(
                            label: chat.isGroup
                                ? l10n.t('groupChat')
                                : l10n.t('directChat'),
                            color: chat.isGroup
                                ? scheme.tertiary
                                : scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${chat.participantCount} · ${chat.messageCount}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
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
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.chat});
  final ChatEntity chat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = chat.avatarUrl != null
        ? MediaUrlResolver.resolve(chat.avatarUrl!)
        : null;
    return CircleAvatar(
      radius: 22,
      backgroundColor: scheme.primaryContainer,
      backgroundImage:
          url != null ? CachedNetworkImageProvider(url) : null,
      child: url == null
          ? Icon(
              chat.isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: scheme.primary,
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
