import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/chat_management_bloc.dart';
import 'chat_filters_popover.dart';
import 'chat_moderation_sidebar.dart';
import 'chat_ui_shared.dart';

/// Shared dimensions so action buttons share the same shape.
abstract final class ChatManagementChrome {
  static const double controlHeight = 40;
  static const double borderRadius = 12;

  static BorderRadius get radius => BorderRadius.circular(borderRadius);

  static BoxDecoration actionDecoration(ColorScheme scheme) => BoxDecoration(
    color: scheme.surface,
    borderRadius: radius,
    border: Border.all(
      color: scheme.outlineVariant.withValues(alpha: 0.65),
    ),
  );
}

class ChatManagementHeader extends StatelessWidget {
  const ChatManagementHeader({super.key, required this.state});

  final ChatManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatManagementBloc>();
    final canModerate = PermissionManager.canModerateChatAdmin(context);
    final chat = state.selectedChat;
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, narrow ? 12 : 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactActions = constraints.maxWidth < 1100;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.t('chatManagementTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    fontSize: narrow ? 18 : null,
                  ),
                ),
              ),
              _HeaderActionButton(
                icon: Icons.tune_rounded,
                label: compactActions ? null : l10n.t('giftFiltersTitle'),
                tooltip: l10n.t('giftFiltersTitle'),
                onPressed: () => showChatFiltersPopover(context, state),
              ),
              const SizedBox(width: 8),
              _HeaderActionButton(
                icon: Icons.download_outlined,
                label: compactActions ? null : l10n.t('export'),
                tooltip: l10n.t('exportLogs'),
                onPressed: chat != null
                    ? () => _exportMessages(context, state)
                    : state.hasChatSelection
                    ? () => _exportSelectedChats(context, state)
                    : null,
              ),
              if (canModerate) ...[
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: compactActions ? null : l10n.t('delete'),
                  tooltip: l10n.t('delete'),
                  destructive: true,
                  onPressed: chat != null && !state.isSubmitting
                      ? () async {
                          final ok = await confirmChatModerationAction(
                            context,
                            title: l10n.t('deleteChatTitle'),
                            message: l10n.t('deleteChatConfirm'),
                            destructive: true,
                          );
                          if (ok && context.mounted) {
                            bloc.add(ChatDeleteRequested(chat.id));
                          }
                        }
                      : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _exportMessages(BuildContext context, ChatManagementLoaded state) {
    final l10n = context.l10n;
    final buffer = StringBuffer(
      'chatId,messageId,sender,type,content,createdAt\n',
    );
    for (final m in state.messages) {
      buffer.writeln(
        '"${m.chatId}","${m.id}","${m.senderId}","${m.type.name}","${(m.content ?? '').replaceAll('"', '""')}","${m.createdAt.toIso8601String()}"',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('chatExportCopied'))));
  }

  void _exportSelectedChats(BuildContext context, ChatManagementLoaded state) {
    final l10n = context.l10n;
    final buffer = StringBuffer('chatId,name,isGroup,participants,messages\n');
    for (final id in state.selectedChatIds) {
      final chat = state.chats.firstWhere((c) => c.id == id);
      buffer.writeln(
        '"${chat.id}","${chat.displayTitle()}","${chat.isGroup}",${chat.participantCount},${chat.messageCount}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('chatExportCopied'))));
  }

}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.destructive = false,
  });

  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final color = destructive
        ? scheme.error.withValues(alpha: enabled ? 1 : 0.45)
        : scheme.onSurface.withValues(alpha: enabled ? 0.85 : 0.45);

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: ChatManagementChrome.radius,
        child: Container(
          height: ChatManagementChrome.controlHeight,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 14),
          decoration: ChatManagementChrome.actionDecoration(scheme).copyWith(
            color: enabled
                ? scheme.surface
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

void showChatInfoDialog(BuildContext context, ChatManagementLoaded state) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: ChatModerationSidebar(state: state),
      ),
    ),
  );
}
