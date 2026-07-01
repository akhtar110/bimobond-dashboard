import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/chat_management_bloc.dart';
import '../widgets/chat_list_panel.dart';
import '../widgets/chat_messages_panel.dart';
import '../widgets/chat_moderation_sidebar.dart';

class ChatManagementPage extends StatelessWidget {
  const ChatManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('ChatManagementPage rebuilt');
    return PersistentBlocProvider<ChatManagementBloc>(
      debugLabel: 'ChatManagementPage',
      create: () =>
          di.sl<ChatManagementBloc>()..add(const ChatManagementStarted()),
      child: const _ChatManagementPageView(),
    );
  }
}

class _ChatManagementPageView extends StatefulWidget {
  const _ChatManagementPageView();

  @override
  State<_ChatManagementPageView> createState() =>
      _ChatManagementPageViewState();
}

class _ChatManagementPageViewState extends State<_ChatManagementPageView> {
  final _chatsScroll = ScrollController();
  final _messagesScroll = ScrollController();

  @override
  void dispose() {
    _chatsScroll.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ChatManagementBloc, ChatManagementState>(
      listenWhen: (prev, next) =>
          next is ChatManagementLoaded &&
          (next.successMessage != null || next.failureMessage != null),
      listener: (context, state) {
        if (state is! ChatManagementLoaded) return;
        final messenger = ScaffoldMessenger.of(context);
        if (state.successMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(_resolveSuccess(context, state.successMessage!)),
            ),
          );
        } else if (state.failureMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.errorContainer,
              content: Text(
                state.failureMessage!,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          );
        }
        context.read<ChatManagementBloc>().add(const ChatFeedbackCleared());
      },
      builder: (context, state) {
        if (state is! ChatManagementLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerLowest,
                scheme.surface,
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surfaceContainerLow,
                ),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width >= 1400) {
                return _DesktopLayout(
                  state: state,
                  chatsScroll: _chatsScroll,
                  messagesScroll: _messagesScroll,
                );
              }
              if (width >= 900) {
                return _TabletLayout(
                  state: state,
                  chatsScroll: _chatsScroll,
                  messagesScroll: _messagesScroll,
                );
              }
              return _MobileLayout(
                state: state,
                chatsScroll: _chatsScroll,
                messagesScroll: _messagesScroll,
              );
            },
          ),
        );
      },
    );
  }

  String _resolveSuccess(BuildContext context, String key) {
    final l10n = context.l10n;
    if (key.startsWith('bulkChatsDeleted:')) {
      final parts = key.split(':');
      return context.tr('bulkChatsDeletedSuccess', {
        'success': parts.length > 1 ? parts[1] : '0',
        'notFound': parts.length > 2 ? parts[2] : '0',
      });
    }
    if (key.startsWith('bulkMessagesDeleted:')) {
      final parts = key.split(':');
      return context.tr('bulkMessagesDeletedSuccess', {
        'success': parts.length > 1 ? parts[1] : '0',
        'notFound': parts.length > 2 ? parts[2] : '0',
      });
    }
    return switch (key) {
      'chatDeletedSuccess' => l10n.t('chatDeletedSuccess'),
      'messageDeletedSuccess' => l10n.t('messageDeletedSuccess'),
      'chatUpdatedSuccess' => l10n.t('chatUpdatedSuccess'),
      _ => key,
    };
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.state,
    required this.chatsScroll,
    required this.messagesScroll,
  });

  final ChatManagementLoaded state;
  final ScrollController chatsScroll;
  final ScrollController messagesScroll;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatManagementBloc>();
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 380,
                child: ChatListPanel(
                  state: state,
                  scrollController: chatsScroll,
                  onLoadMore: () => bloc.add(const ChatsLoadMoreRequested()),
                ),
              ),
              Expanded(
                child: ChatMessagesPanel(
                  state: state,
                  scrollController: messagesScroll,
                  onLoadMore: () =>
                      bloc.add(const MessagesLoadMoreRequested()),
                ),
              ),
              SizedBox(
                width: 320,
                child: ChatModerationSidebar(state: state),
              ),
            ],
          ),
        ),
        ChatBulkActionToolbar(state: state),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.state,
    required this.chatsScroll,
    required this.messagesScroll,
  });

  final ChatManagementLoaded state;
  final ScrollController chatsScroll;
  final ScrollController messagesScroll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ChatManagementBloc>();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 340,
                  child: ChatListPanel(
                    state: state,
                    scrollController: chatsScroll,
                    onLoadMore: () => bloc.add(const ChatsLoadMoreRequested()),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: l10n.t('messages')),
                          Tab(text: l10n.t('participants')),
                          Tab(text: l10n.t('chatAnalytics')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ChatMessagesPanel(
                              state: state,
                              scrollController: messagesScroll,
                              onLoadMore: () => bloc
                                  .add(const MessagesLoadMoreRequested()),
                            ),
                            ChatModerationSidebar(state: state),
                            ChatModerationSidebar(state: state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ChatBulkActionToolbar(state: state),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.state,
    required this.chatsScroll,
    required this.messagesScroll,
  });

  final ChatManagementLoaded state;
  final ScrollController chatsScroll;
  final ScrollController messagesScroll;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatManagementBloc>();
    if (state.selectedChat == null) {
      return Column(
        children: [
          Expanded(
            child: ChatListPanel(
              state: state,
              scrollController: chatsScroll,
              onLoadMore: () => bloc.add(const ChatsLoadMoreRequested()),
            ),
          ),
          ChatBulkActionToolbar(state: state),
        ],
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              context.read<ChatManagementBloc>().add(const ChatSelected(''));
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(context.l10n.t('backToChats')),
          ),
        ),
        Expanded(
          child: ChatMessagesPanel(
            state: state,
            scrollController: messagesScroll,
            onLoadMore: () => bloc.add(const MessagesLoadMoreRequested()),
          ),
        ),
        SizedBox(
          height: 280,
          child: ChatModerationSidebar(state: state),
        ),
        ChatBulkActionToolbar(state: state),
      ],
    );
  }
}
