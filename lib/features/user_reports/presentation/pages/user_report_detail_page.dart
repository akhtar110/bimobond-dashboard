import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../user_activity/domain/entities/user_gift_transaction_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/user_report_entities.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../reports/presentation/widgets/report_detail_header_layout.dart';
import '../../../reports/presentation/widgets/report_detail_metric_card.dart';
import '../../../reports/presentation/widgets/report_safe_media.dart';
import '../../../reports/presentation/widgets/reports_detail_section.dart';
import '../../../reports/presentation/widgets/reports_embedded_panel.dart';
import '../bloc/user_reports_bloc.dart';

class UserReportDetailPage extends StatefulWidget {
  const UserReportDetailPage({
    super.key,
    required this.userId,
    this.initialDays = 30,
    this.onClose,
  });

  final String userId;
  final int initialDays;
  final VoidCallback? onClose;

  @override
  State<UserReportDetailPage> createState() => _UserReportDetailPageState();
}

class _UserReportDetailPageState extends State<UserReportDetailPage> {
  late int _days;

  bool get _embedded => widget.onClose != null;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDays;
    context.read<UserReportsBloc>().add(
          LoadDetail(widget.userId, days: _days),
        );
  }

  void _reload(int days) {
    setState(() => _days = days);
    context.read<UserReportsBloc>().add(
          LoadDetail(widget.userId, days: days),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final actions = <Widget>[
      _PeriodControl(
        days: _days,
        compact: _embedded,
        onChanged: _reload,
      ),
      IconButton(
        tooltip: l10n.t('refresh'),
        visualDensity: VisualDensity.compact,
        onPressed: () => _reload(_days),
        icon: Icon(Icons.refresh_rounded, color: scheme.onSurfaceVariant),
      ),
    ];

    return ReportsDetailShell(
      title: ReportDetailLabels.userReportTitle(l10n),
      subtitle: ReportDetailLabels.userReportSubtitle(l10n),
      onClose: widget.onClose,
      backgroundColor: scheme.surfaceContainerLowest,
      actions: actions,
      body: BlocBuilder<UserReportsBloc, UserReportsState>(
        builder: (context, state) {
          if (state is UserReportsLoaded &&
              state.detailLoading &&
              state.detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserReportsLoaded && state.detailError != null) {
            return _ErrorView(
              message: state.detailError!,
              onRetry: () => _reload(_days),
            );
          }

          final detail = state is UserReportsLoaded ? state.detail : null;
          if (detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state is UserReportsLoaded && state.detailLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: scheme.primary,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(_embedded ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        profile: detail.profile,
                        compact: _embedded,
                      ),
                      SizedBox(height: _embedded ? 10 : 16),
                      _MetricsGrid(
                        counts: detail.counts,
                        periodActivity: detail.periodActivity,
                        postMetrics: detail.allTimePostMetrics,
                        wallet: detail.wallet,
                        notifications: detail.notifications,
                        compact: _embedded,
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.wallet(l10n),
                        compact: _embedded,
                        child: _WalletSection(wallet: detail.wallet),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.periodActivity(l10n),
                        compact: _embedded,
                        child: _PeriodActivityGrid(
                          activity: detail.periodActivity,
                        ),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.devicesSection(
                          l10n,
                          detail.devices.total,
                        ),
                        compact: _embedded,
                        child: _DevicesList(devices: detail.devices.recent),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.recentPosts(l10n),
                        compact: _embedded,
                        child: _PostsList(posts: detail.recentPosts),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.topPostsInPeriod(l10n),
                        compact: _embedded,
                        child: _PostsList(posts: detail.topPostsInPeriod),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.recentGiftsSent(l10n),
                        compact: _embedded,
                        child: _GiftsList(gifts: detail.recentGiftsSent),
                      ),
                      SizedBox(height: _embedded ? 8 : 12),
                      _ReportSection(
                        title: ReportDetailLabels.recentGiftsReceived(l10n),
                        compact: _embedded,
                        child: _GiftsList(gifts: detail.recentGiftsReceived),
                      ),
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
}

class _PeriodControl extends StatelessWidget {
  const _PeriodControl({
    required this.days,
    required this.compact,
    required this.onChanged,
  });

  final int days;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (compact) {
      return PopupMenuButton<int>(
        tooltip: ReportDetailLabels.period(l10n),
        icon: Icon(Icons.date_range_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onSelected: onChanged,
        itemBuilder: (_) => [
          _periodItem(l10n, 7, days),
          _periodItem(l10n, 30, days),
          _periodItem(l10n, 90, days),
        ],
      );
    }

    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 7,
          label: Text(ReportDetailLabels.periodDaysShort(l10n, 7)),
        ),
        ButtonSegment(
          value: 30,
          label: Text(ReportDetailLabels.periodDaysShort(l10n, 30)),
        ),
        ButtonSegment(
          value: 90,
          label: Text(ReportDetailLabels.periodDaysShort(l10n, 90)),
        ),
      ],
      selected: {days},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }

  PopupMenuItem<int> _periodItem(
    AppLocalizations l10n,
    int value,
    int selected,
  ) {
    return PopupMenuItem(
      value: value,
      child: Text(
        ReportDetailLabels.lastNDays(
          l10n,
          value,
          selected: selected == value,
        ),
      ),
    );
  }
}

typedef _ReportSection = ReportsDetailSection;

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    this.compact = false,
  });

  final UserReportProfileEntity profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final displayName = profile.fullName ?? profile.username;
    final cardPadding = EdgeInsets.all(compact ? 12 : 14);

    return ReportDetailHeaderSplit(
      spacing: compact ? 8 : 12,
      start: ReportDetailHeaderCard(
        padding: cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportSafeAvatar(
              url: profile.avatarUrl,
              fallbackLabel: profile.username,
              radius: compact ? 24 : 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NameRow(profile: profile, displayName: displayName),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (profile.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!compact &&
                      profile.bio != null &&
                      profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      end: ReportDetailHeaderCard(
        padding: cardPadding,
        child: _StatWrap(profile: profile, dateFormat: dateFormat),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.profile,
    required this.displayName,
  });

  final UserReportProfileEntity profile;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (profile.isVerified)
          Icon(Icons.verified_rounded, size: 18, color: scheme.primary),
        if (profile.isBanned)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.t('banned'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatWrap extends StatelessWidget {
  const _StatWrap({
    required this.profile,
    required this.dateFormat,
  });

  final UserReportProfileEntity profile;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(label: l10n.t('followers'), value: '${profile.followerCount}'),
        _StatChip(label: l10n.t('following'), value: '${profile.followingCount}'),
        _StatChip(label: l10n.t('posts'), value: '${profile.postCount}'),
        _StatChip(label: l10n.t('likes'), value: '${profile.totalLikes}'),
        if (profile.country != null)
          _StatChip(
            label: ReportDetailLabels.country(l10n),
            value: profile.country!,
          ),
        if (profile.createdAt != null)
          _StatChip(
            label: l10n.t('joined'),
            value: dateFormat.format(profile.createdAt!),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.counts,
    required this.periodActivity,
    required this.postMetrics,
    required this.wallet,
    required this.notifications,
    this.compact = false,
  });

  final UserReportCountsEntity counts;
  final UserReportPeriodActivityEntity periodActivity;
  final UserReportPostMetricsEntity postMetrics;
  final UserReportWalletEntity wallet;
  final UserReportNotificationsEntity notifications;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.simpleCurrency();

    return ReportDetailMetricsGrid(
      compact: compact,
      children: [
        ReportDetailMetricCard(
          title: ReportDetailLabels.wallet(l10n),
          value: currency.format(wallet.balanceCoins),
          icon: Icons.account_balance_wallet_outlined,
          accent: const Color(0xFFD97706),
        ),
        ReportDetailMetricCard(
          title: l10n.t('devices'),
          value: '${counts.devices}',
          icon: Icons.devices_other_outlined,
          accent: Theme.of(context).colorScheme.primary,
        ),
        ReportDetailMetricCard(
          title: l10n.t('comments'),
          value: '${counts.comments}',
          icon: Icons.chat_bubble_outline_rounded,
          accent: const Color(0xFF0891B2),
        ),
        ReportDetailMetricCard(
          title: ReportDetailLabels.giftsSent(l10n),
          value: '${counts.sentGifts}',
          icon: Icons.outbound_rounded,
          accent: const Color(0xFFDB2777),
        ),
        ReportDetailMetricCard(
          title: ReportDetailLabels.giftsReceived(l10n),
          value: '${counts.receivedGifts}',
          icon: Icons.redeem_outlined,
          accent: const Color(0xFF7C3AED),
        ),
        ReportDetailMetricCard(
          title: ReportDetailLabels.viewsAllTime(l10n),
          value: '${postMetrics.views}',
          icon: Icons.visibility_outlined,
          accent: const Color(0xFF2563EB),
        ),
        ReportDetailMetricCard(
          title: ReportDetailLabels.postsInPeriod(l10n),
          value: '${periodActivity.postsCreated}',
          icon: Icons.video_library_outlined,
          accent: const Color(0xFF059669),
        ),
        ReportDetailMetricCard(
          title: ReportDetailLabels.unreadNotifications(l10n),
          value: '${notifications.unreadCount}',
          icon: Icons.notifications_none_outlined,
          accent: const Color(0xFFEA580C),
        ),
      ],
    );
  }
}

class _WalletSection extends StatelessWidget {
  const _WalletSection({required this.wallet});

  final UserReportWalletEntity wallet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (wallet.recentTransactions.isEmpty) {
      return Text(
        ReportDetailLabels.noRecentTransactions(context.l10n),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      );
    }

    final dateFormat = DateFormat.yMMMd().add_Hm();
    final currency = NumberFormat.simpleCurrency();

    return Column(
      children: wallet.recentTransactions.map((tx) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(
            tx.action.toUpperCase() == 'DEBIT'
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          title: Text(
            '${tx.type} · ${tx.action}',
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            tx.createdAt != null ? dateFormat.format(tx.createdAt!) : '',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          trailing: Text(
            currency.format(tx.amountCoins),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }
}

class _PeriodActivityGrid extends StatelessWidget {
  const _PeriodActivityGrid({required this.activity});

  final UserReportPeriodActivityEntity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ReportDetailMetricsGrid(
      children: [
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.postsCreated(l10n),
          count: activity.postsCreated,
          icon: Icons.post_add_outlined,
          accent: const Color(0xFF059669),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.commentsMade(l10n),
          count: activity.commentsMade,
          icon: Icons.chat_bubble_outline_rounded,
          accent: const Color(0xFF0891B2),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.likesGiven(l10n),
          count: activity.likesGiven,
          icon: Icons.favorite_border_rounded,
          accent: const Color(0xFFDB2777),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.repostsMade(l10n),
          count: activity.repostsMade,
          icon: Icons.repeat_rounded,
          accent: const Color(0xFF7C3AED),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.viewsOnPosts(l10n),
          count: activity.viewsOnPosts,
          icon: Icons.visibility_outlined,
          accent: const Color(0xFF2563EB),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.likesOnPosts(l10n),
          count: activity.likesOnPosts,
          icon: Icons.thumb_up_outlined,
          accent: const Color(0xFFDB2777),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.commentsOnPosts(l10n),
          count: activity.commentsOnPosts,
          icon: Icons.mode_comment_outlined,
          accent: const Color(0xFF0891B2),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.newFollowers(l10n),
          count: activity.newFollowers,
          icon: Icons.person_add_outlined,
          accent: Theme.of(context).colorScheme.primary,
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.giftsSent(l10n),
          count: activity.giftsSent,
          icon: Icons.outbound_rounded,
          accent: const Color(0xFFDB2777),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.giftsReceived(l10n),
          count: activity.giftsReceived,
          icon: Icons.redeem_outlined,
          accent: const Color(0xFF7C3AED),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.auctionsHosted(l10n),
          count: activity.auctionsHosted,
          icon: Icons.gavel_rounded,
          accent: const Color(0xFFD97706),
        ),
        ReportDetailCountMetricCard(
          title: ReportDetailLabels.auctionsWon(l10n),
          count: activity.auctionsWon,
          icon: Icons.emoji_events_outlined,
          accent: const Color(0xFFD97706),
        ),
      ],
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.devices});

  final List<UserReportDeviceSummaryEntity> devices;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (devices.isEmpty) {
      return Text(
        ReportDetailLabels.noDevices(context.l10n),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      );
    }

    final dateFormat = DateFormat.yMMMd().add_Hm();

    return Column(
      children: devices.map((device) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(Icons.devices_rounded, size: 18, color: scheme.onSurfaceVariant),
          title: Text(
            '${device.deviceType} · ${device.osVersion ?? '-'}',
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            '${device.appVersion ?? '-'} · ${device.lastActiveIp ?? '-'}'
            '${device.lastActiveAt != null ? ' · ${dateFormat.format(device.lastActiveAt!)}' : ''}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<UserPostEntity> posts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final l10n = context.l10n;
    if (posts.isEmpty) {
      return Text(
        ReportDetailLabels.noPosts(l10n),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      );
    }

    return Column(
      children: posts.map((post) {
        final description = post.description?.toString().trim();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: ReportSafeThumbnail(
            url: post.thumbnailUrl ?? post.videoUrl,
            width: 44,
            height: 44,
          ),
          title: Text(
            description?.isNotEmpty == true
                ? description!
                : ReportDetailLabels.postFallback(l10n, post.id),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            ReportDetailLabels.viewsLikesComments(
              l10n,
              views: post.viewCount,
              likes: post.likeCount,
              comments: post.commentCount,
            ),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}

class _GiftsList extends StatelessWidget {
  const _GiftsList({required this.gifts});

  final List<UserGiftTransactionEntity> gifts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final l10n = context.l10n;
    if (gifts.isEmpty) {
      return Text(
        ReportDetailLabels.noGiftTransactions(l10n),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      );
    }

    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat.yMMMd().add_Hm();

    return Column(
      children: gifts.map((gift) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(
            Icons.card_giftcard_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          title: Text(
            ReportDetailLabels.giftFallback(l10n, gift.giftId),
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            dateFormat.format(gift.createdAt),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          trailing: Text(
            currency.format(gift.priceCoins),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
