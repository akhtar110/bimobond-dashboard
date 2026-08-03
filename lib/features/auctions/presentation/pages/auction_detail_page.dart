import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../rbac/presentation/widgets/access_denied_view.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_user_by_id.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/gift_transaction_entity.dart';
import '../bloc/auction_detail_bloc.dart';
import '../services/auctions_list_sync.dart';
import '../utils/auction_detail_labels.dart';
import '../widgets/auction_card.dart';
import '../widgets/auction_edit_dialog.dart';
import '../widgets/auction_detail_dashboard_widgets.dart';

void _confirmAuctionRefund(BuildContext context) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.t('forceEscrowRefundTitle')),
      content: Text(l10n.t('forceEscrowRefundBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuctionDetailBloc>().add(AdminRefundFulfillmentEvent());
          },
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l10n.t('refundEscrow')),
        ),
      ],
    ),
  );
}

void _confirmAuctionRelease(BuildContext context) {
  final l10n = context.l10n;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.t('forceEscrowReleaseTitle')),
      content: Text(l10n.t('forceEscrowReleaseBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuctionDetailBloc>().add(AdminReleaseFulfillmentEvent());
          },
          child: Text(l10n.t('releaseEscrow')),
        ),
      ],
    ),
  );
}

/// Styled refund / release controls for the Escrow fulfillment panel.
class _AuctionFulfillmentActionsBar extends StatelessWidget {
  const _AuctionFulfillmentActionsBar({
    required this.auction,
  });

  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    if (!PermissionManager.canFulfillAuctions(context)) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cards = <Widget>[];

    if (auction.canAdminRefundEscrow) {
      cards.add(
        _FulfillmentActionCard(
          title: l10n.t('forceEscrowRefund'),
          subtitle: l10n.tOr(
            'forceEscrowRefundShort',
            'Return gift coins to senders',
          ),
          icon: Icons.replay_circle_filled_outlined,
          accent: scheme.error,
          surface: scheme.errorContainer.withValues(alpha: 0.55),
          onTap: () => _confirmAuctionRefund(context),
        ),
      );
    }
    if (auction.canAdminReleaseEscrow) {
      cards.add(
        _FulfillmentActionCard(
          title: l10n.t('forceEscrowRelease'),
          subtitle: l10n.tOr(
            'forceEscrowReleaseShort',
            'Pay host and settle escrow',
          ),
          icon: Icons.volunteer_activism_outlined,
          accent: scheme.primary,
          surface: scheme.primaryContainer.withValues(alpha: 0.65),
          onTap: () => _confirmAuctionRelease(context),
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = DashboardSpace.md;
        final sideBySide = cards.length > 1 && constraints.maxWidth >= 520;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _FulfillmentActionCard extends StatefulWidget {
  const _FulfillmentActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  State<_FulfillmentActionCard> createState() => _FulfillmentActionCardState();
}

class _FulfillmentActionCardState extends State<_FulfillmentActionCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final elevation = _hovered ? 6.0 : 2.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : (_hovered ? 1.008 : 1),
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(DashboardSpace.lg),
            decoration: BoxDecoration(
              color: widget.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accent.withValues(alpha: _hovered ? 0.55 : 0.32),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: elevation * 2.5,
                  offset: Offset(0, elevation * 0.75),
                  color: widget.accent.withValues(alpha: _hovered ? 0.22 : 0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.accent),
                ),
                const SizedBox(width: DashboardSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DashboardSpace.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: widget.accent.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuctionDetailPage extends StatefulWidget {
  const AuctionDetailPage({
    super.key,
    required this.auctionId,
    this.listPreview,
  });

  final String auctionId;
  final AuctionEntity? listPreview;

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuctionDetailBloc>().add(
          LoadAuctionDetailsEvent(
            widget.auctionId,
            listPreview: widget.listPreview,
          ),
        );
  }

  void _syncToListBloc(AuctionEntity auction) {
    sl<AuctionsListSync>().publish(auction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FeatureAccessBoundary(
      canAccess: PermissionManager.canReadAuctions,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          centerTitle: false,
          iconTheme: IconThemeData(color: scheme.onSurface),
          title: Text(
            context.l10n.t('auctionDetails'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
        ),
        body: BlocConsumer<AuctionDetailBloc, AuctionDetailState>(
          listenWhen: (previous, current) {
            if (current is! AuctionDetailLoaded) return false;
            if (previous is! AuctionDetailLoaded) return true;
            return previous.auction.id != current.auction.id ||
                previous.auction.status != current.auction.status ||
                previous.auction.currentTotalCoins !=
                    current.auction.currentTotalCoins ||
                previous.successMessage != current.successMessage ||
                previous.errorMessage != current.errorMessage ||
                previous.isActioning != current.isActioning;
          },
          listener: (context, state) {
            if (state is AuctionDetailLoaded) {
              _syncToListBloc(state.auction);
              final l10n = context.l10n;
              final bloc = context.read<AuctionDetailBloc>();

              if (state.successMessage != null) {
                final sm = state.successMessage!;
                final message = () {
                  if (sm.startsWith('auction_fulfillment_refund')) {
                    final parts = sm.split(':');
                    if (parts.length == 2 && parts[1].isNotEmpty) {
                      return context.tr('auctionFulfillmentRefundSuccess', {
                        'count': parts[1],
                      });
                    }
                    return l10n.t('auctionFulfillmentRefundSuccessGeneric');
                  }
                  return switch (sm) {
                    'auction_fulfillment_release' =>
                      l10n.t('auctionFulfillmentReleaseSuccess'),
                    'auction_fulfillment_already_settled' =>
                      l10n.t('auctionFulfillmentAlreadySettled'),
                    'auction_updated_successfully' => l10n.tOr(
                        'auction_updated_successfully',
                        'Auction updated successfully',
                      ),
                    'auction_unbanned_successfully' => l10n.tOr(
                        'auction_unbanned_successfully',
                        'Auction unbanned successfully',
                      ),
                    _ => sm,
                  };
                }();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: scheme.primary,
                  ),
                );
                bloc.add(ClearAuctionDetailMessagesEvent());
              } else if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: scheme.error,
                  ),
                );
                bloc.add(ClearAuctionDetailMessagesEvent());
              }
            }
          },
          builder: (context, state) {
            if (state is AuctionDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AuctionDetailError) {
              return _ErrorBody(
                message: state.message,
                auctionId: widget.auctionId,
                listPreview: widget.listPreview,
              );
            }
            if (state is AuctionDetailLoaded) {
              return _DetailBody(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state});
  final AuctionDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final auction = state.auction;
    final showWinner = auction.winner != null || auction.isCompleted;
    const gap = DashboardSpace.xl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = dashboardLayoutTier(constraints.maxWidth);
        final isDesktop =
            tier == DashboardLayoutTier.desktop ||
            tier == DashboardLayoutTier.largeDesktop;

        Widget spaced(List<Widget> sections) {
          final items = <Widget>[];
          for (var i = 0; i < sections.length; i++) {
            if (i > 0) items.add(const SizedBox(height: gap));
            items.add(sections[i]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          );
        }

        final hero = _AuctionHeroSection(
          auction: auction,
          isLive: state.isLive,
        );
        final progress = _AuctionProgressSection(
          auction: auction,
          lastGiftName: state.lastGiftName,
        );
        final stats = _AuctionStatsSection(auction: auction, tier: tier);
        final host = _AuctionHostSection(auction: auction);
        final winner = showWinner
            ? _AuctionWinnerSection(auction: auction)
            : null;
        final admin = _AuctionAdminSection(state: state);
        final fulfillment = _AuctionFulfillmentSection(state: state);
        final gifts = _AuctionGiftTransactionsSection(
          auction: auction,
          transactions: auction.giftTransactions ?? const [],
        );

        final Widget pageContent;

        if (isDesktop) {
          // Desktop: full-width hero + progress, asymmetric 2-column body,
          // gift transactions last inside the same scroll.
          pageContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: gap),
              progress,
              const SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: spaced([stats, fulfillment, admin]),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: spaced([
                      host,
                      if (winner != null) winner,
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: gap),
              gifts,
            ],
          );
        } else {
          pageContent = spaced([
            hero,
            progress,
            stats,
            fulfillment,
            host,
            if (winner != null) winner,
            admin,
            gifts,
          ]);
        }

        return DashboardShell(child: pageContent);
      },
    );
  }
}

class _AuctionHeroSection extends StatelessWidget {
  const _AuctionHeroSection({
    required this.auction,
    required this.isLive,
  });

  final AuctionEntity auction;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat('MMM d');
    final giftCount = auction.giftTransactionCount;
    final itemName = auction.itemName?.isNotEmpty == true
        ? auction.itemName!
        : l10n.t('noData');

    return DashboardCard(
      interactive: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < DashboardBreakpoints.mobile;

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: stack ? double.infinity : 200,
              height: stack ? 220 : 200,
              child: auction.displayImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: auction.displayImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imagePlaceholder(context),
                      errorWidget: (_, __, ___) => _imagePlaceholder(context),
                    )
                  : _imagePlaceholder(context),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveIndicatorRow(isLive: isLive, auction: auction),
              const SizedBox(height: DashboardSpace.lg),
              Text(
                itemName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: DashboardSpace.md),
              Wrap(
                spacing: DashboardSpace.lg,
                runSpacing: DashboardSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusBadge(status: auction.status),
                  DashboardInlineMeta(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.tOr('started', 'Started'),
                    value: dateFmt.format(auction.startedAt.toLocal()),
                  ),
                  if (auction.endedAt != null)
                    DashboardInlineMeta(
                      icon: Icons.event_outlined,
                      label: l10n.tOr('ends', 'Ends'),
                      value: dateFmt.format(auction.endedAt!.toLocal()),
                    ),
                  if (giftCount > 0)
                    DashboardInlineMeta(
                      icon: Icons.card_giftcard_outlined,
                      label: l10n.t('giftTransactions'),
                      value: '$giftCount',
                    ),
                ],
              ),
              const SizedBox(height: DashboardSpace.lg),
              Wrap(
                spacing: DashboardSpace.xl,
                runSpacing: DashboardSpace.md,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _QuickStat(
                    label: AuctionDetailLabels.raised(l10n),
                    value:
                        CoinFormat.coinsAmount(auction.currentTotalCoins),
                    highlight: true,
                  ),
                  _QuickStat(
                    label: AuctionDetailLabels.goal(l10n),
                    value: CoinFormat.coinsProgress(
                      current: auction.currentTotalCoins,
                      target: auction.effectiveTargetPriceCoins,
                    ),
                  ),
                ],
              ),
              if (auction.hasMoneyTarget) ...[
                const SizedBox(height: DashboardSpace.sm),
                Text(
                  '${l10n.tOr('auctionTargetValue', 'Target value')}: '
                  '${MoneyFormat.format(auction.targetPrice!, auction.currencyCode!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [image, const SizedBox(height: DashboardSpace.xl), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: DashboardSpace.xl),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.gavel_rounded,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DashboardSpace.xs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _LiveIndicatorRow extends StatelessWidget {
  const _LiveIndicatorRow({required this.isLive, required this.auction});
  final bool isLive;
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isLive) {
      return Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: DashboardSpace.sm),
          Text(
            l10n.t('live').toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: DashboardSpace.sm),
          Text(
            '• Real-time updates active',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (auction.isActive) {
      return Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: DashboardSpace.sm),
          Text(
            'Connecting to live updates...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            scheme.primary,
            scheme.primaryContainer,
            _anim.value,
          ),
        ),
      ),
    );
  }
}

class _AuctionStatsSection extends StatelessWidget {
  const _AuctionStatsSection({
    required this.auction,
    required this.tier,
  });

  final AuctionEntity auction;
  final DashboardLayoutTier tier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat('MMM d, yyyy');
    final giftCount = auction.giftTransactionCount;
    final liveTitle = auction.live?.title?.trim();
    final postDesc = auction.post?.description?.trim();

    return DashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = metricGridColumns(tier, constraints.maxWidth);
          final itemWidth =
              (constraints.maxWidth - (columns - 1) * DashboardSpace.md) /
                  columns;

          final metrics = [
            MetricCard(
              icon: Icons.info_outline_rounded,
              label: l10n.t('status'),
              value: auctionStatusStyle(scheme, l10n, auction.status).label,
            ),
            MetricCard(
              icon: Icons.attach_money_rounded,
              label: l10n.t('startingPrice'),
              value: CoinFormat.coins(auction.startingPriceCoins),
            ),
            MetricCard(
              icon: Icons.flag_outlined,
              label: l10n.t('auctionTargetPrice'),
              value: CoinFormat.coins(auction.effectiveTargetPriceCoins),
            ),
            MetricCard(
              icon: Icons.trending_up_rounded,
              label: l10n.tOr('currentRaised', 'Current raised'),
              value: CoinFormat.coins(auction.currentTotalCoins),
              valueColor: scheme.primary,
            ),
            MetricCard(
              icon: Icons.card_giftcard_outlined,
              label: l10n.t('giftTransactions'),
              value: '$giftCount',
            ),
            MetricCard(
              icon: Icons.play_circle_outline_rounded,
              label: l10n.t('auctionStartDate'),
              value: dateFmt.format(auction.startedAt.toLocal()),
              compact: true,
            ),
            MetricCard(
              icon: Icons.stop_circle_outlined,
              label: l10n.t('auctionEndDate'),
              value: auction.endedAt != null
                  ? dateFmt.format(auction.endedAt!.toLocal())
                  : l10n.t('notAvailable'),
              compact: true,
            ),
            MetricCard(
              icon: Icons.link_rounded,
              label: l10n.tOr('linkedPost', 'Linked post'),
              value: auction.hasPost
                  ? (postDesc != null && postDesc.isNotEmpty
                      ? (postDesc.length > 28
                          ? '${postDesc.substring(0, 28)}…'
                          : postDesc)
                      : l10n.tOr('yes', 'Yes'))
                  : l10n.tOr('no', 'No'),
            ),
            MetricCard(
              icon: Icons.live_tv_outlined,
              label: l10n.tOr('liveSession', 'Live session'),
              value: auction.hasLive
                  ? (liveTitle != null && liveTitle.isNotEmpty
                      ? liveTitle
                      : l10n.tOr('yes', 'Yes'))
                  : l10n.tOr('no', 'No'),
            ),
            MetricCard(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.tOr('escrow', 'Escrow'),
              value: auction.effectiveEscrowEnabled
                  ? l10n.tOr('enabled', 'Enabled')
                  : l10n.tOr('disabled', 'Disabled'),
            ),
            if (auction.hasFulfillmentLifecycle)
              MetricCard(
                icon: Icons.local_shipping_outlined,
                label: l10n.tOr('fulfillmentStatus', 'Fulfillment'),
                value: fulfillmentStatusLabel(l10n, auction.fulfillmentStatus),
              ),
          ];

          return Wrap(
            spacing: DashboardSpace.md,
            runSpacing: DashboardSpace.md,
            children: metrics
                .map(
                  (m) => SizedBox(
                    width: columns == 1
                        ? constraints.maxWidth
                        : itemWidth.clamp(168, constraints.maxWidth),
                    child: m,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _AuctionProgressSection extends StatelessWidget {
  const _AuctionProgressSection({
    required this.auction,
    this.lastGiftName,
  });

  final AuctionEntity auction;
  final String? lastGiftName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final pct = auction.progressFraction;
    final color = auctionProgressColor(scheme, auction);
    final remaining = auction.remainingCoins;
    final goal = auction.effectiveTargetPriceCoins;

    return DashboardCard(
      backgroundColor: Color.alphaBlend(
        scheme.primaryContainer.withValues(alpha: 0.25),
        scheme.surface,
      ),
      child: DashboardSection(
        title: AuctionDetailLabels.progressTitle(l10n),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;

            final stats = [
              _ProgressHighlight(
                label: AuctionDetailLabels.raised(l10n),
                value: CoinFormat.coins(auction.currentTotalCoins),
                color: color,
              ),
              _ProgressHighlight(
                label: AuctionDetailLabels.remaining(l10n, context),
                value: CoinFormat.coins(remaining),
              ),
              _ProgressHighlight(
                label: AuctionDetailLabels.goal(l10n),
                value: CoinFormat.coins(goal),
              ),
            ];

            final percentBadge = Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DashboardSpace.lg,
                vertical: DashboardSpace.sm,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...stats.map(
                        (stat) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: DashboardSpace.md,
                          ),
                          child: stat,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: percentBadge,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: DashboardSpace.md),
                        Expanded(child: stats[i]),
                      ],
                      const SizedBox(width: DashboardSpace.md),
                      Flexible(child: percentBadge),
                    ],
                  ),
                const SizedBox(height: DashboardSpace.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'auction-progress-${goal.toStringAsFixed(0)}-'
                      '${auction.currentTotalCoins.toStringAsFixed(0)}',
                    ),
                    tween: Tween<double>(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 14,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: color,
                      );
                    },
                  ),
                ),
                if (lastGiftName != null) ...[
                  const SizedBox(height: DashboardSpace.lg),
                  Row(
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: DashboardSpace.sm),
                      Expanded(
                        child: Text(
                          AuctionDetailLabels.latestGift(l10n, lastGiftName!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressHighlight extends StatelessWidget {
  const _ProgressHighlight({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DashboardSpace.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AuctionHostSection extends StatefulWidget {
  const _AuctionHostSection({required this.auction});
  final AuctionEntity auction;

  @override
  State<_AuctionHostSection> createState() => _AuctionHostSectionState();
}

class _AuctionHostSectionState extends State<_AuctionHostSection> {
  String? _resolvedName;

  @override
  void initState() {
    super.initState();
    _loadHostName();
  }

  @override
  void didUpdateWidget(covariant _AuctionHostSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.hostId != widget.auction.hostId ||
        oldWidget.auction.host != widget.auction.host) {
      _loadHostName();
    }
  }

  Future<void> _loadHostName() async {
    final auction = widget.auction;
    var name = _displayNameFromUserMap(auction.host);

    if (name == null || _looksLikeUsername(name)) {
      final hostId = auction.hostId.trim();
      if (hostId.isNotEmpty) {
        try {
          final detail = await sl<GetUserById>()(hostId);
          final fullName = detail.user.fullName?.trim();
          if (fullName != null && fullName.isNotEmpty) {
            name = fullName;
          }
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() => _resolvedName = name);
  }

  String? _hostField(String key) {
    final value = widget.auction.host?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _resolveUsername() {
    final fromMap = _usernameFromUserMap(widget.auction.host);
    if (fromMap != null) return fromMap;

    final hostName = widget.auction.hostName.trim();
    if (hostName.isEmpty || hostName == widget.auction.hostId) return null;
    if (hostName.contains(' ')) return null;

    return hostName.startsWith('@') ? hostName.substring(1) : hostName;
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fullName = _resolvedName ?? _displayNameFromUserMap(auction.host);
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    String formatDateTime(DateTime date) {
      return '${dateFmt.format(date.toLocal())}\n${timeFmt.format(date.toLocal())}';
    }

    return ProfileCard(
      title: l10n.t('owner'),
      displayName: fullName ?? l10n.t('notAvailable'),
      username: _resolveUsername(),
      email: _hostField('email'),
      avatarUrl: auction.hostAvatar,
      metadata: [
        Wrap(
          spacing: DashboardSpace.md,
          runSpacing: DashboardSpace.md,
          children: [
            DashboardInlineMeta(
              compact: true,
              icon: Icons.info_outline_rounded,
              label: l10n.t('status'),
              value: auctionStatusStyle(scheme, l10n, auction.status).label,
            ),
            DashboardInlineMeta(
              compact: true,
              icon: Icons.play_circle_outline_rounded,
              label: l10n.tOr('started', 'Started'),
              value: formatDateTime(auction.startedAt),
            ),
            if (auction.endedAt != null)
              DashboardInlineMeta(
                compact: true,
                icon: Icons.stop_circle_outlined,
                label: l10n.tOr('ends', 'Ends'),
                value: formatDateTime(auction.endedAt!),
              ),
          ],
        ),
      ],
    );
  }
}

class _AuctionWinnerSection extends StatelessWidget {
  const _AuctionWinnerSection({required this.auction});
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final winner = auction.winner;
    final winnerName = _displayNameFromUserMap(winner) ?? auction.winnerName;
    final winnerUsername = _usernameFromUserMap(winner);

    if (winner == null) {
      return ProfileCard(
        title: l10n.tOr('winner', 'Winner'),
        displayName: auction.winnerId ?? l10n.t('loading'),
        accent: scheme.tertiary,
        trailing: Icon(Icons.emoji_events_rounded,
            size: 22, color: scheme.tertiary),
      );
    }

    return ProfileCard(
      title: l10n.tOr('winner', 'Winner'),
      displayName: winnerName ?? l10n.t('notAvailable'),
      username: winnerUsername,
      avatarUrl: winner['avatarUrl'] as String?,
      accent: scheme.tertiary,
      trailing:
          Icon(Icons.emoji_events_rounded, size: 22, color: scheme.tertiary),
    );
  }
}

class _AuctionFulfillmentSection extends StatelessWidget {
  const _AuctionFulfillmentSection({required this.state});

  final AuctionDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auction = state.auction;
    final canFulfill = PermissionManager.canFulfillAuctions(context);

    // Panel only when escrow is enabled (permission + escrow flag).
    if (!canFulfill || !auction.effectiveEscrowEnabled) {
      return const SizedBox.shrink();
    }

    final hasActions =
        auction.canAdminRefundEscrow || auction.canAdminReleaseEscrow;
    final fulfillmentLabel = fulfillmentStatusLabel(
      l10n,
      auction.fulfillmentStatus,
    );

    return ActionPanel(
      title: l10n.t('auctionFulfillmentTitle'),
      isLoading: state.isActioning,
      children: [
        if (auction.isDisputed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DashboardSpace.md),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel_rounded, size: 18, color: scheme.error),
                const SizedBox(width: DashboardSpace.sm),
                Expanded(
                  child: Text(
                    l10n.t('auctionFulfillmentDisputeHint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DashboardSpace.md),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DashboardSpace.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: DashboardSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.t('auctionEscrowEnabledHint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashboardSpace.sm),
              Text(
                '${l10n.t('status')}: ${auctionStatusStyle(scheme, l10n, auction.status).label}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.t('fulfillmentStatus')}: $fulfillmentLabel',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DashboardSpace.sm),
              Text(
                context.tr('auctionFulfillmentHeldCoins', {
                  'coins': CoinFormat.coins(auction.currentTotalCoins),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (hasActions) ...[
          const SizedBox(height: DashboardSpace.lg),
          _AuctionFulfillmentActionsBar(auction: auction),
        ],
      ],
    );
  }
}

class _AuctionAdminSection extends StatelessWidget {
  const _AuctionAdminSection({required this.state});
  final AuctionDetailLoaded state;

  Widget _actionButtonsRow(List<Widget> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (buttons.length == 1) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: buttons.first,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = DashboardSpace.sm;
        final minButtonWidth = 148.0;
        final fitsOneRow = constraints.maxWidth >=
            buttons.length * minButtonWidth +
                (buttons.length - 1) * spacing;

        if (fitsOneRow) {
          return Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: buttons[i]),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                SizedBox(
                  width: minButtonWidth,
                  child: buttons[i],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auction = state.auction;
    final canModerate = PermissionManager.canModerateAuctions(context);
    final canResolve = PermissionManager.canResolveAuctions(context);

    final moderationButtons = <Widget>[];

    if (canResolve && auction.canAdminForceResolve) {
      moderationButtons.add(
        ActionPanelButton(
          label: l10n.t('manuallyResolve'),
          icon: Icons.check_circle_rounded,
          onTap: () => _showResolveDialog(context),
        ),
      );
    }
    if (canModerate && auction.canAdminCancelOrBan) {
      moderationButtons.add(
        ActionPanelButton(
          label: l10n.t('forceCancel'),
          icon: Icons.cancel_outlined,
          variant: ActionPanelButtonVariant.destructive,
          onTap: () => _confirmCancel(context),
        ),
      );
      moderationButtons.add(
        ActionPanelButton(
          label: l10n.tOr('banAuction', 'Ban auction'),
          icon: Icons.block_outlined,
          variant: ActionPanelButtonVariant.destructive,
          onTap: () => _confirmBan(context),
        ),
      );
    }
    if (canModerate && auction.isAdminEditable) {
      moderationButtons.add(
        ActionPanelButton(
          label: l10n.tOr('edit_auction', 'Edit auction'),
          icon: Icons.edit_outlined,
          onTap: () => _showEditDialog(context, auction),
        ),
      );
    }
    if (canModerate && auction.canAdminUnban) {
      moderationButtons.add(
        ActionPanelButton(
          label: l10n.tOr('unban_auction', 'Unban auction'),
          icon: Icons.lock_open_rounded,
          onTap: () => _confirmUnban(context),
        ),
      );
    }

    if (moderationButtons.isEmpty && !auction.isCompleted) {
      return const SizedBox.shrink();
    }

    // Completed badge alone (no moderation buttons) still shows the panel.
    if (moderationButtons.isEmpty && auction.isCompleted) {
      return ActionPanel(
        title: l10n.t('actions'),
        isLoading: state.isActioning,
        children: [
          Container(
            padding: const EdgeInsets.all(DashboardSpace.lg),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: DashboardSpace.sm),
                Text(
                  l10n.t('completed'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ActionPanel(
      title: l10n.t('actions'),
      isLoading: state.isActioning,
      children: [
        if (auction.isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(DashboardSpace.lg),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: DashboardSpace.sm),
                Text(
                  l10n.t('completed'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DashboardSpace.md),
        ],
        _actionButtonsRow(moderationButtons),
      ],
    );
  }

  void _confirmCancel(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('forceCancelAuctionTitle')),
        content: const Text(
          'This will immediately cancel the auction. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('keepActive')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionDetailBloc>()
                  .add(AdminCancelDetailAuctionEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l10n.t('cancelAuction')),
          ),
        ],
      ),
    );
  }

  void _confirmBan(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tOr('banAuction', 'Ban auction')),
        content: Text(
          l10n.tOr(
            'banAuctionConfirm',
            'This will mark the auction as BANNED and remove it from active gift activity.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tOr('keep', 'Keep')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionDetailBloc>()
                  .add(AdminBanDetailAuctionEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l10n.tOr('ban', 'Ban')),
          ),
        ],
      ),
    );
  }

  void _confirmUnban(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tOr('unban_auction', 'Unban auction')),
        content: Text(
          l10n.tOr(
            'confirm_unban',
            'Restore this auction from BANNED status?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionDetailBloc>()
                  .add(AdminUnbanDetailAuctionEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            child: Text(l10n.tOr('unban_auction', 'Unban auction')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, AuctionEntity auction) async {
    final body = await showAuctionEditDialog(context, auction: auction);
    if (body == null || !context.mounted) return;
    context.read<AuctionDetailBloc>().add(AdminUpdateAuctionEvent(body));
  }

  void _showResolveDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ResolveAuctionDialog(
        onResolve: (winnerId) {
          context
              .read<AuctionDetailBloc>()
              .add(AdminResolveAuctionEvent(winnerId));
        },
      ),
    );
  }
}

class _ResolveAuctionDialog extends StatefulWidget {
  const _ResolveAuctionDialog({required this.onResolve});

  final ValueChanged<String> onResolve;

  @override
  State<_ResolveAuctionDialog> createState() => _ResolveAuctionDialogState();
}

class _ResolveAuctionDialogState extends State<_ResolveAuctionDialog> {
  UserEntity? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.t('manuallyResolveAuctionTitle')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.t('manuallyResolveAuctionHint')),
            const SizedBox(height: DashboardSpace.lg),
            AdminUserSearchField(
              selectedUser: _selectedUser,
              label: l10n.t('selectWinner'),
              onUserSelected: (user) => setState(() => _selectedUser = user),
            ),
            if (_selectedUser == null) ...[
              const SizedBox(height: DashboardSpace.md),
              Text(
                l10n.t('pleaseSelectWinner'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _selectedUser == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onResolve(_selectedUser!.id);
                },
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          child: Text(l10n.t('resolve')),
        ),
      ],
    );
  }
}

class _AuctionGiftTransactionsSection extends StatefulWidget {
  const _AuctionGiftTransactionsSection({
    required this.auction,
    required this.transactions,
  });

  final AuctionEntity auction;
  final List<GiftTransactionEntity> transactions;

  @override
  State<_AuctionGiftTransactionsSection> createState() =>
      _AuctionGiftTransactionsSectionState();
}

class _AuctionGiftTransactionsSectionState
    extends State<_AuctionGiftTransactionsSection> {
  final Map<String, String> _resolvedSenderNames = {};

  @override
  void initState() {
    super.initState();
    _loadSenderNames();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final items = widget.transactions.map((tx) {
      final senderDisplayName = _resolvedSenderNames[tx.senderId] ??
          _giftSenderDisplayName(tx, widget.auction);

      return ActivityFeedItem(
        avatarUrl: tx.senderAvatar,
        primaryText: senderDisplayName,
        secondaryText: tx.giftName,
        amount: '+${CoinFormat.coins(tx.contributionCoins)}',
        timestamp: DateFormat('MMM d, h:mm a').format(tx.createdAt.toLocal()),
        leading: tx.giftThumbnail != null
            ? Image.network(
                tx.giftThumbnail!,
                width: 14,
                height: 14,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : null,
      );
    }).toList();

    return ActivityFeed(
      title: l10n.t('giftTransactions'),
      count: widget.transactions.length,
      emptyMessage: l10n.t('noData'),
      children: items,
    );
  }

  Future<void> _loadSenderNames() async {
    final txBySenderId = <String, GiftTransactionEntity>{};
    for (final tx in widget.transactions) {
      final id = tx.senderId.trim();
      if (id.isNotEmpty) txBySenderId.putIfAbsent(id, () => tx);
    }

    final getUserById = sl<GetUserById>();
    final resolved = <String, String>{};

    for (final entry in txBySenderId.entries) {
      final id = entry.key;
      final tx = entry.value;
      final fallback = _giftSenderDisplayName(tx, widget.auction);

      if (!_looksLikeUsername(fallback)) {
        resolved[id] = fallback;
        continue;
      }

      final lookupId =
          tx.sender?['id']?.toString().trim().isNotEmpty == true
              ? tx.sender!['id']!.toString().trim()
              : id;

      try {
        final detail = await getUserById(lookupId);
        final fullName = detail.user.fullName?.trim();
        resolved[id] = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : fallback;
      } catch (_) {
        resolved[id] = fallback;
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedSenderNames
        ..clear()
        ..addAll(resolved);
    });
  }
}

bool _looksLikeUsername(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.startsWith('user_') || !trimmed.contains(' ');
}

String? _usernameFromUserMap(Map<String, dynamic>? user) {
  if (user == null) return null;

  for (final nestedKey in ['user', 'profile']) {
    final nested = user[nestedKey];
    if (nested is Map) {
      final nestedUsername = _usernameFromUserMap(
        Map<String, dynamic>.from(nested),
      );
      if (nestedUsername != null) return nestedUsername;
    }
  }

  final raw = user['username']?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return raw.startsWith('@') ? raw.substring(1) : raw;
}

String? _displayNameFromUserMap(Map<String, dynamic>? user) {
  if (user == null) return null;

  for (final nestedKey in ['user', 'profile']) {
    final nested = user[nestedKey];
    if (nested is Map) {
      final nestedName = _displayNameFromUserMap(
        Map<String, dynamic>.from(nested),
      );
      if (nestedName != null) return nestedName;
    }
  }

  final username = _usernameFromUserMap(user);
  final firstName = user['firstName']?.toString().trim();
  final lastName = user['lastName']?.toString().trim();
  if (firstName != null && firstName.isNotEmpty) {
    final combined = lastName != null && lastName.isNotEmpty
        ? '$firstName $lastName'
        : firstName;
    if (combined != username && !_looksLikeUsername(combined)) {
      return combined;
    }
  }

  for (final key in ['fullName', 'full_name', 'displayName', 'name']) {
    final value = user[key]?.toString().trim();
    if (value != null &&
        value.isNotEmpty &&
        value != username &&
        !_looksLikeUsername(value)) {
      return value;
    }
  }

  return null;
}

String _giftSenderDisplayName(
  GiftTransactionEntity tx,
  AuctionEntity auction,
) {
  final fromSender = _displayNameFromUserMap(tx.sender);
  if (fromSender != null) return fromSender;

  if (tx.senderId == auction.hostId) {
    final hostName = _displayNameFromUserMap(auction.host);
    if (hostName != null) return hostName;
  }
  if (tx.senderId == auction.winnerId) {
    final winnerName = _displayNameFromUserMap(auction.winner);
    if (winnerName != null) return winnerName;
  }

  final username = tx.sender?['username']?.toString().trim();
  if (username != null && username.isNotEmpty) return username;

  return tx.senderId;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = auctionStatusStyle(scheme, context.l10n, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardSpace.md,
        vertical: DashboardSpace.xs,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.auctionId,
    this.listPreview,
  });

  final String message;
  final String auctionId;
  final AuctionEntity? listPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DashboardSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: scheme.error),
            const SizedBox(height: DashboardSpace.lg),
            Text(
              l10n.t('failedToLoadAuction'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: DashboardSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DashboardSpace.xl),
            FilledButton.icon(
              onPressed: () => context
                  .read<AuctionDetailBloc>()
                  .add(LoadAuctionDetailsEvent(
                    auctionId,
                    listPreview: listPreview,
                  )),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.t('retry')),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
