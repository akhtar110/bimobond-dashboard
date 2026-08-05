import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../bloc/post_management_bloc.dart';
import 'post_advanced_analytics_section.dart';
import 'post_engagement_panel.dart';
import 'post_moderation_timeline_panel.dart';
import 'post_surface_card.dart';

/// Overview, analytics, and moderation timeline tabs for post detail.
class PostDetailInsightsPanel extends StatefulWidget {
  const PostDetailInsightsPanel({
    super.key,
    required this.isBusy,
    this.hideComments = false,
    this.highlightCommentId,
    this.engagementInitialTabIndex = 0,
  });

  final bool isBusy;
  final bool hideComments;
  final String? highlightCommentId;
  final int engagementInitialTabIndex;

  @override
  State<PostDetailInsightsPanel> createState() =>
      _PostDetailInsightsPanelState();
}

class _PostDetailInsightsPanelState extends State<PostDetailInsightsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTab(0));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadTab(_tabController.index);
  }

  void _loadTab(int index) {
    final bloc = context.read<PostManagementBloc>();
    switch (index) {
      case 1:
        bloc.add(LoadPostAdvancedAnalyticsEvent());
        break;
      case 2:
        bloc.add(LoadPostModerationTimelineEvent());
        break;
      default:
        break;
    }
  }

  void _openTimelineTab() {
    if (_tabController.index != 2) {
      _tabController.animateTo(2);
    }
    _loadTab(2);
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
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
            tabs: [
              Tab(text: l10n.tOr('overview', 'Overview')),
              Tab(text: l10n.tOr('analytics', 'Analytics')),
              Tab(text: l10n.tOr('moderationTimeline', 'Timeline')),
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
                    PostEngagementPanel(
                      isBusy: widget.isBusy,
                      hideComments: widget.hideComments,
                      highlightCommentId: widget.highlightCommentId,
                      initialTabIndex: widget.engagementInitialTabIndex,
                      embedded: true,
                    ),
                    PostAdvancedAnalyticsSection(
                      onViewFullTimeline: _openTimelineTab,
                    ),
                    const PostModerationTimelinePanel(),
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
