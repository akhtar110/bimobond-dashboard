import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../analytics/presentation/utils/analytics_format.dart';
import '../../../analytics/presentation/widgets/analytics_kpi_card.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../reports/presentation/widgets/report_detail_header_layout.dart';
import '../../../reports/presentation/widgets/report_detail_metric_card.dart';
import '../../../reports/presentation/widgets/report_safe_media.dart';
import '../../../reports/presentation/widgets/reports_embedded_panel.dart';
import '../../domain/entities/post_report_entities.dart';
import '../bloc/post_report_detail_bloc.dart';
import '../widgets/post_report_thumbnail.dart';

class PostReportDetailPage extends StatefulWidget {
  const PostReportDetailPage({
    super.key,
    required this.postId,
    this.initialDays = 30,
    this.onClose,
  });

  final String postId;
  final int initialDays;
  final VoidCallback? onClose;

  @override
  State<PostReportDetailPage> createState() => _PostReportDetailPageState();
}

class _PostReportDetailPageState extends State<PostReportDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<PostReportDetailBloc>().add(
          LoadPostReportDetailEvent(
            postId: widget.postId,
            days: widget.initialDays,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return _PostReportDetailView(onClose: widget.onClose);
  }
}

class _PostReportDetailView extends StatelessWidget {
  const _PostReportDetailView({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final actions = <Widget>[
      BlocBuilder<PostReportDetailBloc, PostReportDetailState>(
        builder: (context, state) {
          final days = state is PostReportDetailLoaded ? state.days : 30;
          final periodL10n = context.l10n;
          return SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 7,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 7)),
              ),
              ButtonSegment(
                value: 30,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 30)),
              ),
              ButtonSegment(
                value: 90,
                label: Text(ReportDetailLabels.periodDaysShort(periodL10n, 90)),
              ),
            ],
            selected: {days},
            onSelectionChanged: (selection) {
              context.read<PostReportDetailBloc>().add(
                    ChangePostReportDetailDaysEvent(selection.first),
                  );
            },
          );
        },
      ),
      IconButton(
        tooltip: l10n.t('refresh'),
        onPressed: () => context
            .read<PostReportDetailBloc>()
            .add(RefreshPostReportDetailEvent()),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ];

    return ReportsDetailShell(
      title: ReportDetailLabels.postReportTitle(l10n),
      subtitle: ReportDetailLabels.postReportSubtitle(l10n),
      onClose: onClose,
      backgroundColor: scheme.surfaceContainerLowest,
      actions: actions,
      body: BlocBuilder<PostReportDetailBloc, PostReportDetailState>(
        builder: (context, state) {
          if (state is PostReportDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PostReportDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<PostReportDetailBloc>()
                        .add(RefreshPostReportDetailEvent()),
                    child: Text(context.l10n.t('retry')),
                  ),
                ],
              ),
            );
          }
          if (state is! PostReportDetailLoaded) {
            return const SizedBox.shrink();
          }

          final detail = state.detail;
          return Column(
            children: [
              if (state.isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PostHeader(post: detail.post),
                      const SizedBox(height: 12),
                      Text(
                        AnalyticsFormat.rangeLabel(
                          detail.period.from,
                          detail.period.to,
                        ),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      _MetricsGrid(detail: detail),
                      const SizedBox(height: 12),
                      _PeriodActivitySection(activity: detail.periodActivity),
                      const SizedBox(height: 12),
                      _RecentSection(
                        title: ReportDetailLabels.recentComments(l10n),
                        icon: Icons.chat_bubble_outline_rounded,
                        emptyLabel: ReportDetailLabels.noRecentComments(l10n),
                        children: detail.recentComments
                            .map((c) => _CommentTile(comment: c))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      _RecentSection(
                        title: ReportDetailLabels.recentLikes(l10n),
                        icon: Icons.favorite_border_rounded,
                        emptyLabel: ReportDetailLabels.noRecentLikes(l10n),
                        children: detail.recentLikes
                            .map(
                              (l) => _UserActivityTile(
                                user: l.user,
                                subtitle: _formatDate(l.createdAt),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      _RecentSection(
                        title: ReportDetailLabels.recentGifts(l10n),
                        icon: Icons.card_giftcard_outlined,
                        emptyLabel: ReportDetailLabels.noRecentGifts(l10n),
                        children: detail.recentGifts
                            .map((g) => _GiftTile(gift: g))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      _ModerationSection(flags: detail.moderationFlags),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy HH:mm').format(date);
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final PostReportListItem post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final title = post.description?.trim().isNotEmpty == true
        ? post.description!.trim()
        : ReportDetailLabels.postFallback(l10n, post.id);
    final subtitle =
        '@${post.user?.username ?? post.userId} · ${post.type} · ${post.status}';

    return ReportDetailHeaderSplit(
      start: ReportDetailHeaderCard(
        title: title,
        subtitle: subtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostReportThumbnail(
              post: post,
              width: 88,
              height: 88,
              borderRadius: 12,
            ),
            const SizedBox(height: 8),
            Text(
              _PostReportDetailView._formatDate(post.createdAt),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      end: ReportDetailHeaderCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (post.categoryRelation != null)
              Chip(
                label: Text(post.categoryRelation!.name),
                visualDensity: VisualDensity.compact,
              ),
            if (post.isAd) Chip(label: Text(ReportDetailLabels.ad(l10n))),
            if (post.isStory) Chip(label: Text(ReportDetailLabels.story(l10n))),
            if (post.isAuctionable)
              Chip(label: Text(ReportDetailLabels.auctionable(l10n))),
            ...post.hashtags.map(
              (h) => Chip(
                label: Text('#${h.name}'),
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (post.categoryRelation == null &&
                !post.isAd &&
                !post.isStory &&
                !post.isAuctionable &&
                post.hashtags.isEmpty)
              Text(
                '—',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.detail});

  final PostReportDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = detail.metrics;
    final c = detail.counts;

    return ReportDetailMetricsGrid(
      hasSubtitle: true,
      children: [
        ReportDetailMetricCard(
          title: l10n.t('views'),
          value: AnalyticsFormat.count(m.viewCount),
          subtitle: ReportDetailLabels.allTimeCount(
            l10n,
            AnalyticsFormat.count(c.views),
          ),
          icon: Icons.visibility_outlined,
          accent: const Color(0xFF2563EB),
        ),
        ReportDetailMetricCard(
          title: l10n.t('likes'),
          value: AnalyticsFormat.count(m.likeCount),
          subtitle: ReportDetailLabels.moderationFlagsCount(
            l10n,
            c.reports,
          ),
          icon: Icons.favorite_border_rounded,
          accent: const Color(0xFFDB2777),
        ),
        ReportDetailMetricCard(
          title: l10n.t('comments'),
          value: AnalyticsFormat.count(m.commentCount),
          subtitle: ReportDetailLabels.savesCount(
            l10n,
            AnalyticsFormat.count(c.saves),
          ),
          icon: Icons.chat_bubble_outline_rounded,
          accent: const Color(0xFF0891B2),
        ),
        ReportDetailMetricCard(
          title: l10n.t('reposts'),
          value: AnalyticsFormat.count(m.repostCount),
          subtitle: ReportDetailLabels.giftsDuetsCount(
            l10n,
            c.giftTransactions,
            c.duets,
          ),
          icon: Icons.repeat_rounded,
          accent: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _PeriodActivitySection extends StatelessWidget {
  const _PeriodActivitySection({required this.activity});

  final PostReportPeriodActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnalyticsSectionCard(
      title: ReportDetailLabels.periodActivity(l10n),
      subtitle: ReportDetailLabels.engagementInRange(l10n),
      child: ReportDetailMetricsGrid(
        children: [
          ReportDetailCountMetricCard(
            title: l10n.t('views'),
            count: activity.views,
            icon: Icons.visibility_outlined,
            accent: const Color(0xFF2563EB),
          ),
          ReportDetailCountMetricCard(
            title: l10n.t('likes'),
            count: activity.likes,
            icon: Icons.favorite_border_rounded,
            accent: const Color(0xFFDB2777),
          ),
          ReportDetailCountMetricCard(
            title: l10n.t('comments'),
            count: activity.comments,
            icon: Icons.chat_bubble_outline_rounded,
            accent: const Color(0xFF0891B2),
          ),
          ReportDetailCountMetricCard(
            title: ReportDetailLabels.saves(l10n),
            count: activity.saves,
            icon: Icons.bookmark_border_rounded,
            accent: const Color(0xFF7C3AED),
          ),
          ReportDetailCountMetricCard(
            title: l10n.t('reposts'),
            count: activity.reposts,
            icon: Icons.repeat_rounded,
            accent: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.title,
    required this.icon,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: title,
      child: children.isEmpty
          ? Text(
              emptyLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(children: children),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostReportComment comment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _UserAvatar(user: comment.user),
      title: Text(comment.content, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '@${comment.user?.username ?? ReportDetailLabels.unknown(l10n)} · '
        '${_PostReportDetailView._formatDate(comment.createdAt)}',
      ),
      trailing: Text('${comment.likeCount} ♥'),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift});

  final PostReportGiftTransaction gift;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ReportSafeThumbnail(
        url: gift.gift?.thumbnailUrl,
        width: 40,
        height: 40,
        borderRadius: 20,
        fallbackIcon: Icons.card_giftcard_outlined,
      ),
      title: Text(gift.gift?.name ?? ReportDetailLabels.giftLabel(l10n)),
      subtitle: Text(
        '${gift.sender?.username ?? ReportDetailLabels.unknown(l10n)} → '
        '${gift.receiver?.username ?? ReportDetailLabels.unknown(l10n)} · '
        '${AnalyticsFormat.usd(gift.priceCoins)}',
      ),
      trailing: Text(_PostReportDetailView._formatDate(gift.createdAt)),
    );
  }
}

class _UserActivityTile extends StatelessWidget {
  const _UserActivityTile({required this.user, required this.subtitle});

  final ReportAdminUser? user;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _UserAvatar(user: user),
      title: Text(user?.displayName ?? ReportDetailLabels.unknown(l10n)),
      subtitle: Text(
        '@${user?.username ?? ReportDetailLabels.unknown(l10n)} · $subtitle',
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final ReportAdminUser? user;

  @override
  Widget build(BuildContext context) {
    return ReportSafeAvatar(
      url: user?.avatarUrl,
      fallbackLabel: user?.username ?? '?',
      radius: 20,
    );
  }
}

class _ModerationSection extends StatelessWidget {
  const _ModerationSection({required this.flags});

  final PostReportModerationFlags flags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AnalyticsSectionCard(
      title: ReportDetailLabels.moderationFlags(l10n),
      subtitle: ReportDetailLabels.moderationFlagsTotal(l10n, flags.total),
      child: flags.recent.isEmpty
          ? Text(
              ReportDetailLabels.noModerationFlags(l10n),
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: flags.recent
                  .map(
                    (f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.flag_outlined, color: scheme.error),
                      title: Text('${f.reason} · ${f.status}'),
                      subtitle: Text(
                        '@${f.reporter?.username ?? ReportDetailLabels.unknown(l10n)} · '
                        '${_PostReportDetailView._formatDate(f.createdAt)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
