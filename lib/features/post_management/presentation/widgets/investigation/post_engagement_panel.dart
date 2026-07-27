import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../../domain/entities/post_engagement_user_item.dart';
import '../../bloc/post_management_bloc.dart';
import '../comments_moderation_panel.dart';
import 'post_engagement_users_panel.dart';
import 'post_reposts_panel.dart';
import 'post_surface_card.dart';

/// Comments, reposts, likes, mentions, and post views tabbed section.
class PostEngagementPanel extends StatefulWidget {
  const PostEngagementPanel({
    super.key,
    required this.isBusy,
    this.hideComments = false,
    this.highlightCommentId,
    this.initialTabIndex = 0,
  });

  final bool isBusy;
  final bool hideComments;
  final String? highlightCommentId;
  final int initialTabIndex;

  @override
  State<PostEngagementPanel> createState() => _PostEngagementPanelState();
}

class _PostEngagementPanelState extends State<PostEngagementPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int get _tabCount => widget.hideComments ? 4 : 5;

  int _engagementLoadIndex(int tabIndex) {
    if (widget.hideComments) {
      return tabIndex + 1;
    }
    return tabIndex;
  }

  @override
  void initState() {
    super.initState();
    final maxIndex = _tabCount - 1;
    final initialIndex = widget.initialTabIndex.clamp(0, maxIndex);
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_engagementLoadIndex(initialIndex) >= 1) {
        _loadEngagementForTab(initialIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadEngagementForTab(_tabController.index);
  }

  void _loadEngagementForTab(int index) {
    final kind = switch (_engagementLoadIndex(index)) {
      1 => PostEngagementKind.reposts,
      2 => PostEngagementKind.likes,
      3 => PostEngagementKind.mentions,
      4 => PostEngagementKind.views,
      _ => null,
    };
    if (kind == null) return;
    context.read<PostManagementBloc>().add(LoadPostEngagementUsersEvent(kind));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PostSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.forum_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.t('commentsInvestigation'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
            tabs: [
              if (!widget.hideComments) Tab(text: l10n.t('comments')),
              Tab(text: l10n.t('reposts')),
              Tab(text: l10n.t('likes')),
              Tab(text: l10n.t('mentions')),
              Tab(text: l10n.tOr('postViews', 'Post Views')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return IndexedStack(
                  index: _tabController.index,
                  children: [
                    if (!widget.hideComments)
                      BlocSelector<PostManagementBloc, PostManagementState,
                          PostManagementLoaded?>(
                        selector: (s) => s is PostManagementLoaded ? s : null,
                        builder: (context, loaded) {
                          if (loaded == null) return const SizedBox.shrink();
                          return CommentsModerationPanel(
                            state: loaded,
                            isBusy: widget.isBusy,
                            highlightCommentId: widget.highlightCommentId,
                            embedded: true,
                          );
                        },
                      ),
                    BlocSelector<PostManagementBloc, PostManagementState,
                        ManagedPostEntity?>(
                      selector: (s) =>
                          s is PostManagementLoaded ? s.post : null,
                      builder: (context, post) {
                        if (post == null) return const SizedBox.shrink();
                        return PostRepostsPanel(totalCount: post.repostCount);
                      },
                    ),
                    BlocSelector<PostManagementBloc, PostManagementState,
                        ManagedPostEntity?>(
                      selector: (s) =>
                          s is PostManagementLoaded ? s.post : null,
                      builder: (context, post) {
                        if (post == null) return const SizedBox.shrink();
                        return PostEngagementUsersPanel(
                          kind: PostEngagementKind.likes,
                          totalCount: post.likeCount,
                          emptyMessage: l10n.t('noLikesYet'),
                        );
                      },
                    ),
                    BlocSelector<PostManagementBloc, PostManagementState,
                        ({ManagedPostEntity? post, PostEngagementListState? mentions})>(
                      selector: (s) {
                        if (s is! PostManagementLoaded) {
                          return (post: null, mentions: null);
                        }
                        return (post: s.post, mentions: s.mentions);
                      },
                      builder: (context, data) {
                        if (data.post == null) return const SizedBox.shrink();
                        final mentionCount = data.mentions?.items.isNotEmpty == true
                            ? data.mentions!.items.length
                            : data.post!.recentMentions.length;
                        return PostEngagementUsersPanel(
                          kind: PostEngagementKind.mentions,
                          totalCount: mentionCount,
                          emptyMessage: l10n.t('noMentionsYet'),
                          subtitleLabel: l10n.tOr('mentionText', 'Mention'),
                        );
                      },
                    ),
                    BlocSelector<PostManagementBloc, PostManagementState,
                        ManagedPostEntity?>(
                      selector: (s) =>
                          s is PostManagementLoaded ? s.post : null,
                      builder: (context, post) {
                        if (post == null) return const SizedBox.shrink();
                        return PostEngagementUsersPanel(
                          kind: PostEngagementKind.views,
                          totalCount: post.viewCount,
                          emptyMessage:
                              l10n.tOr('noViewsYet', 'No views yet'),
                          subtitleLabel:
                              l10n.tOr('watchDuration', 'Watched'),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
