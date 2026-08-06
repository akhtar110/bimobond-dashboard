import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../post_reports/domain/entities/post_report_entities.dart';
import '../../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../bloc/post_management_bloc.dart';
import '../comments_moderation_panel.dart';
import 'investigation_theme.dart';
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
    this.embedded = false,
  });

  final bool isBusy;
  final bool hideComments;
  final String? highlightCommentId;
  final int initialTabIndex;
  final bool embedded;

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

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
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
          padding: EdgeInsets.all(widget.embedded ? 0 : 16),
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
                        ({
                          ManagedPostEntity? post,
                          PostReportDetailEntity? analyticsDetail,
                        })>(
                      selector: (s) {
                        if (s is! PostManagementLoaded) {
                          return (post: null, analyticsDetail: null);
                        }
                        return (
                          post: s.post,
                          analyticsDetail: s.analyticsDetail,
                        );
                      },
                      builder: (context, data) {
                        if (data.post == null) return const SizedBox.shrink();
                        return _PostViewsTab(
                          totalCount: data.post!.viewCount,
                          analyticsDetail: data.analyticsDetail,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );

    if (widget.embedded) return body;
    return PostSurfaceCard(padding: EdgeInsets.zero, child: body);
  }
}

// ── Post Views tab: traffic breakdown + viewer list ──────────────────────────

class _PostViewsTab extends StatefulWidget {
  const _PostViewsTab({
    required this.totalCount,
    required this.analyticsDetail,
  });

  final int totalCount;
  final PostReportDetailEntity? analyticsDetail;

  @override
  State<_PostViewsTab> createState() => _PostViewsTabState();
}

class _PostViewsTabState extends State<_PostViewsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Trigger analytics load if not already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.analyticsDetail == null) {
        context.read<PostManagementBloc>().add(LoadPostAdvancedAnalyticsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final detail = widget.analyticsDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Traffic source breakdown ──────────────────────────────────────
        _TrafficBreakdownCard(
          breakdown: detail?.metrics.trafficSourceBreakdown,
          isLoading: detail == null,
        ),
        const SizedBox(height: InvestigationTheme.s16),
        // ── Recent viewers list ───────────────────────────────────────────
        PostEngagementUsersPanel(
          kind: PostEngagementKind.views,
          totalCount: widget.totalCount,
          emptyMessage: l10n.tOr('noViewsYet', 'No views yet'),
          subtitleLabel: l10n.tOr('watchDuration', 'Watched'),
        ),
      ],
    );
  }
}

class _TrafficBreakdownCard extends StatelessWidget {
  const _TrafficBreakdownCard({
    required this.breakdown,
    required this.isLoading,
  });

  final PostReportTrafficSourceBreakdown? breakdown;
  final bool isLoading;

  static Color _accentFor(String key, ColorScheme scheme) {
    return switch (key) {
      'FOR_YOU' => const Color(0xFF2563EB),
      'FOLLOWING' => const Color(0xFF7C3AED),
      'PROFILE' => const Color(0xFF0891B2),
      'SEARCH' => const Color(0xFFD97706),
      'HASHTAGS' => const Color(0xFF059669),
      'SHARES' => const Color(0xFFDB2777),
      'SOUND' => const Color(0xFF9333EA),
      'LIVE' => const Color(0xFFDC2626),
      'NOTIFICATION' => const Color(0xFFF59E0B),
      'SAVED' => const Color(0xFF0284C7),
      'LIKED' => const Color(0xFFE11D48),
      'REPOST' => const Color(0xFF16A34A),
      'CHAT' => const Color(0xFF0EA5E9),
      'EXPLORE' => const Color(0xFF0D9488),
      'STORY' => const Color(0xFFC026D3),
      'RECOMMENDED' => const Color(0xFF6D28D9),
      'PROMOTION' => const Color(0xFFEA580C),
      'EXTERNAL' => const Color(0xFF475569),
      'OTHER' => scheme.outline,
      _ => scheme.primary,
    };
  }

  static IconData _iconFor(String key) {
    return switch (key) {
      'FOR_YOU' => Icons.home_outlined,
      'FOLLOWING' => Icons.people_outline_rounded,
      'PROFILE' => Icons.person_outline_rounded,
      'SEARCH' => Icons.search_rounded,
      'HASHTAGS' => Icons.tag_rounded,
      'SHARES' => Icons.share_outlined,
      'SOUND' => Icons.music_note_outlined,
      'LIVE' => Icons.videocam_outlined,
      'NOTIFICATION' => Icons.notifications_none_rounded,
      'SAVED' => Icons.bookmark_border_rounded,
      'LIKED' => Icons.favorite_border_rounded,
      'REPOST' => Icons.repeat_rounded,
      'CHAT' => Icons.chat_bubble_outline_rounded,
      'EXPLORE' => Icons.explore_outlined,
      'STORY' => Icons.auto_stories_outlined,
      'RECOMMENDED' => Icons.auto_awesome_outlined,
      'PROMOTION' => Icons.campaign_outlined,
      'EXTERNAL' => Icons.open_in_new_rounded,
      'OTHER' => Icons.more_horiz_rounded,
      _ => Icons.bar_chart_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(InvestigationTheme.s12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tOr('trafficSources', 'Traffic Sources'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: InvestigationTheme.s8),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    final entries = breakdown?.sortedEntries ?? [];
    final total = breakdown?.total ?? 0;

    return Container(
      padding: const EdgeInsets.all(InvestigationTheme.s12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.tOr('trafficSources', 'Traffic Sources'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ReportDetailLabels.trafficSourceTotal(l10n, total),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: InvestigationTheme.s12),
          if (entries.isEmpty)
            Text(
              ReportDetailLabels.noTrafficSourceData(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.map((e) {
              final label = ReportDetailLabels.trafficSourceLabel(l10n, e.key);
              final accent = _accentFor(e.key, scheme);
              final icon = _iconFor(e.key);
              final fraction = total > 0 ? e.value / total : 0.0;
              final pct = (fraction * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
                child: Row(
                  children: [
                    // icon badge
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, size: 14, color: accent),
                    ),
                    const SizedBox(width: InvestigationTheme.s8),
                    // label + bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${e.value}',
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: fraction),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 5,
                                backgroundColor:
                                    accent.withValues(alpha: 0.10),
                                valueColor:
                                    AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
