import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_ui_shared.dart';

class ChatModerationSidebar extends StatelessWidget {
  const ChatModerationSidebar({super.key, required this.state});

  final ChatManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final chat = state.selectedChat;

    if (chat == null) {
      return ChatEmptyState(
        icon: Icons.insights_outlined,
        title: l10n.t('chatInsightsEmpty'),
        subtitle: l10n.t('chatInsightsEmptyHint'),
      );
    }

    final analytics = state.analytics;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _InfoCard(
            title: l10n.t('chatInfo'),
            children: [
              _InfoRow(
                l10n.tOr('type', 'Type'),
                chat.isGroup ? l10n.t('groupChat') : l10n.t('directChat'),
              ),
              _InfoRow(l10n.t('createdAt'), formatChatTime(chat.createdAt)),
              _InfoRow(l10n.t('lastActivity'), formatChatTime(chat.updatedAt)),
              _InfoRow(l10n.t('totalMessages'), '${chat.messageCount}'),
              _InfoRow(l10n.t('deletedMessages'), '${analytics.deleted}'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.t('participants'),
            children: [
              for (final p in chat.participants)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: () {
                      final resolved = p.user?.avatarUrl != null
                          ? MediaUrlResolver.resolve(p.user!.avatarUrl!)
                          : null;
                      return resolved != null
                          ? CachedNetworkImageProvider(resolved)
                          : null;
                    }(),
                    child: p.user?.avatarUrl == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  title: Text(p.user?.displayName ?? p.userId),
                  subtitle: Text('@${p.user?.username ?? p.userId}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (p.user?.isVerified == true)
                        Icon(Icons.verified_rounded,
                            size: 16, color: scheme.primary),
                      if (p.user?.isBanned == true)
                        Icon(Icons.block_rounded,
                            size: 16, color: scheme.error),
                      if (p.isMuted)
                        Icon(Icons.volume_off_rounded,
                            size: 16, color: scheme.onSurfaceVariant),
                    ],
                  ),
                  onTap: p.user != null
                      ? () {
                          // Navigate if we had full UserEntity — show snackbar for now
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(p.user!.username),
                            ),
                          );
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.t('chatAnalytics'),
            children: [
              _AnalyticsBar(
                label: l10n.t('chatMessageText'),
                value: analytics.text,
                total: analytics.total,
                color: scheme.primary,
              ),
              _AnalyticsBar(
                label: l10n.t('chatMessageImage'),
                value: analytics.image,
                total: analytics.total,
                color: scheme.secondary,
              ),
              _AnalyticsBar(
                label: l10n.t('chatMessageVideo'),
                value: analytics.video,
                total: analytics.total,
                color: scheme.tertiary,
              ),
              _AnalyticsBar(
                label: l10n.t('chatMessageAudio'),
                value: analytics.audio,
                total: analytics.total,
                color: scheme.primaryFixed,
              ),
              _AnalyticsBar(
                label: l10n.t('chatMessagePostShare'),
                value: analytics.postShare,
                total: analytics.total,
                color: scheme.secondaryFixed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final factor = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$value'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBulkActionToolbar extends StatelessWidget {
  const ChatBulkActionToolbar({super.key, required this.state});

  final ChatManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasChatSelection) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatManagementBloc>();

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: 1,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.tr('chatsSelectedCount', {
                  'count': '${state.selectedChatIds.length}',
                }),
                style: const TextStyle(fontWeight: FontWeight.w800),
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
                          message: context.tr('deleteChatsBulkConfirm', {
                            'count': '${state.selectedChatIds.length}',
                          }),
                          destructive: true,
                        );
                        if (ok && context.mounted) {
                          bloc.add(const ChatsBulkDeleteRequested());
                        }
                      },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(l10n.t('deleteChats')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final buffer = StringBuffer('chatId,name,isGroup,participants,messages\n');
                  for (final id in state.selectedChatIds) {
                    final chat = state.chats.firstWhere((c) => c.id == id);
                    buffer.writeln(
                      '"${chat.id}","${chat.displayTitle()}","${chat.isGroup}",${chat.participantCount},${chat.messageCount}',
                    );
                  }
                  Clipboard.setData(ClipboardData(text: buffer.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.t('chatExportCopied'))),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(l10n.t('export')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
