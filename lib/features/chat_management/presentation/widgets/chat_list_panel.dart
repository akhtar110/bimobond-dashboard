import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _TypeTabs(
                          selected: state.listQuery.typeFilter,
                          onChanged: (filter) => context
                              .read<ChatManagementBloc>()
                              .add(ChatsTypeFilterChanged(filter)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortDropdown(
                      l10n: l10n,
                      selected: state.dateSort,
                      onChanged: (sort) => context
                          .read<ChatManagementBloc>()
                          .add(ChatsDateSortChanged(sort)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminUserSearchField(
                  key: ValueKey('chat-user-${state.listFilterRevision}'),
                  selectedUser: state.filterUser,
                  hintText: l10n.t('notificationSearchUsersHint'),
                  compact: true,
                  compactFilterStyle: true,
                  onUserSelected: (user) => context
                      .read<ChatManagementBloc>()
                      .add(ChatsParticipantFilterChanged(user)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                    subtitle: l10n.t('noChatsFoundHint'),
                    actionLabel: state.failureMessage != null
                        ? l10n.t('retry')
                        : null,
                    onAction: state.failureMessage != null
                        ? () => context.read<ChatManagementBloc>().add(
                            const ChatsRefreshed(),
                          )
                        : null,
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (useDesktopPagination) return false;
                      if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120 &&
                          !state.isLoadingMoreChats) {
                        onLoadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount:
                          state.chats.length +
                          (!useDesktopPagination && state.isLoadingMoreChats
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.chats.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
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
                        final chat = state.chats[index];
                        return ChatCard(
                          chat: chat,
                          isSelected: state.selectedChat?.id == chat.id,
                          isChecked: state.selectedChatIds.contains(chat.id),
                          showCheckbox: state.hasChatSelection,
                          onTap: () => context.read<ChatManagementBloc>().add(
                            ChatSelected(chat.id),
                          ),
                          onCheckChanged: () => context
                              .read<ChatManagementBloc>()
                              .add(ChatSelectionToggled(chat.id)),
                        );
                      },
                    ),
                  ),
          ),
          if (useDesktopPagination &&
              state.chatsMeta != null &&
              state.chatsMeta!.total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: AppPaginationBar(
                currentPage: state.chatsMeta!.page,
                lastPage: state.chatsMeta!.totalPages,
                total: state.chatsMeta!.total,
                pageSize: state.chatsMeta!.limit,
                itemCount: state.chats.length,
                hideWhenSinglePage: false,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                onPageChanged: (page) => context.read<ChatManagementBloc>().add(
                  ChatsGoToPageRequested(page),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selected, required this.onChanged});

  final ChatTypeFilter selected;
  final ValueChanged<ChatTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ChatTypeFilter.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          _TypeTab(
            label: switch (ChatTypeFilter.values[i]) {
              ChatTypeFilter.all => l10n.t('filterAll'),
              ChatTypeFilter.direct => l10n.t('chatFilterDirect'),
              ChatTypeFilter.group => l10n.t('chatFilterGroup'),
            },
            isSelected: selected == ChatTypeFilter.values[i],
            onTap: () => onChanged(ChatTypeFilter.values[i]),
            scheme: scheme,
          ),
        ],
      ],
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.l10n,
    required this.selected,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final ChatDateSort selected;
  final ValueChanged<ChatDateSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedLabel = selected == ChatDateSort.newest
        ? l10n.t('searchMgmtSortNewest')
        : l10n.t('searchMgmtSortOldest');
    final label = 'Sort: $selectedLabel';

    return PopupMenuButton<ChatDateSort>(
      tooltip: label,
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: ChatDateSort.newest,
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('searchMgmtSortNewest'),
                  style: TextStyle(
                    fontWeight: selected == ChatDateSort.newest
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (selected == ChatDateSort.newest)
                Icon(Icons.check_rounded, size: 16, color: scheme.primary),
            ],
          ),
        ),
        PopupMenuItem(
          value: ChatDateSort.oldest,
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('searchMgmtSortOldest'),
                  style: TextStyle(
                    fontWeight: selected == ChatDateSort.oldest
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (selected == ChatDateSort.oldest)
                Icon(Icons.check_rounded, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatCard extends StatefulWidget {
  const ChatCard({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.isChecked,
    required this.showCheckbox,
    required this.onTap,
    required this.onCheckChanged,
  });

  final ChatEntity chat;
  final bool isSelected;
  final bool isChecked;
  final bool showCheckbox;
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
              messageTypeLabel(
                l10n,
                chat.lastMessage?.type ?? ChatMessageType.text,
              );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? scheme.primary.withValues(alpha: 0.08)
              : _hovered
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? scheme.primary.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.25),
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onLongPress: widget.showCheckbox ? null : widget.onCheckChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (widget.showCheckbox)
                  ChatModerationGate(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Checkbox(
                        value: widget.isChecked,
                        onChanged: (_) => widget.onCheckChanged(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                _ChatAvatarGroup(chat: chat),
                const SizedBox(width: 12),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: widget.isSelected
                                    ? scheme.onSurface
                                    : scheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          Text(
                            formatChatListTime(chat.updatedAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 11,
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
                          fontSize: 12.5,
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

class _ChatAvatarGroup extends StatelessWidget {
  const _ChatAvatarGroup({required this.chat});

  final ChatEntity chat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (chat.isGroup) {
      return _SingleAvatar(
        url: chat.avatarUrl,
        icon: Icons.groups_rounded,
        scheme: scheme,
      );
    }

    final participants = chat.participants.take(2).toList();
    if (participants.length < 2) {
      final url = participants.isNotEmpty
          ? participants.first.user?.avatarUrl
          : chat.avatarUrl;
      return _SingleAvatar(
        url: url,
        icon: Icons.person_rounded,
        scheme: scheme,
      );
    }

    return SizedBox(
      width: 44,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: _SmallAvatar(
              url: participants[0].user?.avatarUrl,
              scheme: scheme,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: _SmallAvatar(
              url: participants[1].user?.avatarUrl,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleAvatar extends StatelessWidget {
  const _SingleAvatar({
    required this.url,
    required this.icon,
    required this.scheme,
  });

  final String? url;
  final IconData icon;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final resolved = url != null ? MediaUrlResolver.resolve(url!) : null;
    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.surfaceContainerHighest,
      backgroundImage:
          resolved != null ? CachedNetworkImageProvider(resolved) : null,
      child: resolved == null
          ? Icon(icon, size: 20, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, required this.scheme});

  final String? url;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final resolved = url != null ? MediaUrlResolver.resolve(url!) : null;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage:
            resolved != null ? CachedNetworkImageProvider(resolved) : null,
        child: resolved == null
            ? Icon(Icons.person_rounded, size: 14, color: scheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
