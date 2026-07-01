import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_user_by_id.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/gift_transaction_entity.dart';
import '../bloc/auction_detail_bloc.dart';
import '../bloc/auctions_bloc.dart';
import '../utils/auction_detail_labels.dart';
import '../widgets/auction_card.dart';
import '../widgets/auction_detail_dashboard_widgets.dart';

class AuctionDetailPage extends StatefulWidget {
  const AuctionDetailPage({super.key, required this.auctionId});
  final String auctionId;

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  String? _lastKnownStatus;

  @override
  void initState() {
    super.initState();
    context.read<AuctionDetailBloc>().add(
          LoadAuctionDetailsEvent(widget.auctionId),
        );
  }

  void _syncToListBloc(BuildContext context, AuctionEntity auction) {
    try {
      context
          .read<AuctionsBloc>()
          .add(AuctionStatusUpdatedEvent(auction));
    } catch (_) {
      // AuctionsBloc may not be in the tree in edge-case navigation paths.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
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
        listener: (context, state) {
          if (state is AuctionDetailLoaded) {
            final newStatus = state.auction.status;
            if (newStatus != _lastKnownStatus &&
                (state.auction.isCancelled || state.auction.isCompleted)) {
              _syncToListBloc(context, state.auction);
            }
            _lastKnownStatus = newStatus;

            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: scheme.primary,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: scheme.error,
                ),
              );
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
            );
          }
          if (state is AuctionDetailLoaded) {
            return _DetailBody(state: state);
          }
          return const SizedBox.shrink();
        },
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
    final showActions = auction.isActive || auction.isCompleted;
    final showTransactions = auction.giftTransactions?.isNotEmpty == true;
    const gap = DashboardSpace.xl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = dashboardLayoutTier(constraints.maxWidth);
        final useFixedHeight =
            (tier == DashboardLayoutTier.desktop ||
                    tier == DashboardLayoutTier.largeDesktop) &&
                showTransactions &&
                constraints.maxHeight.isFinite;

        Widget column({
          required List<Widget> children,
          bool expanded = false,
        }) {
          final col = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
          if (expanded) {
            return Expanded(child: col);
          }
          return col;
        }

        Widget scrollColumn(List<Widget> children) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
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
        final admin = showActions
            ? _AuctionAdminSection(state: state)
            : null;
        final gifts = showTransactions
            ? _AuctionGiftTransactionsSection(
                auction: auction,
                transactions: auction.giftTransactions!,
                expanded: useFixedHeight,
              )
            : null;

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

        if (tier == DashboardLayoutTier.desktop ||
            tier == DashboardLayoutTier.largeDesktop) {
          final col1 = spaced([
            hero,
            progress,
            if (admin != null) admin,
          ]);
          final col2 = spaced([stats, host]);
          final col3Sections = <Widget>[
            if (winner != null) winner,
            if (gifts != null) gifts,
          ];

          if (useFixedHeight) {
            final tierPadding = dashboardHorizontalPadding(tier);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                tierPadding,
                DashboardSpace.xl,
                tierPadding,
                DashboardSpace.xxl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DashboardBreakpoints.maxContentWidth,
                  ),
                  child: SizedBox(
                    height: constraints.maxHeight -
                        DashboardSpace.xl -
                        DashboardSpace.xxl,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: scrollColumn([col1])),
                        const SizedBox(width: gap),
                        Expanded(flex: 4, child: scrollColumn([col2])),
                        const SizedBox(width: gap),
                        Expanded(
                          flex: 4,
                          child: column(
                            expanded: true,
                            children: col3Sections.length == 1
                                ? [Expanded(child: col3Sections.first)]
                                : [
                                    if (winner != null) winner,
                                    if (winner != null && gifts != null)
                                      const SizedBox(height: gap),
                                    if (gifts != null)
                                      Expanded(child: gifts),
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

          return DashboardShell(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: col1),
                const SizedBox(width: gap),
                Expanded(flex: 4, child: col2),
                const SizedBox(width: gap),
                Expanded(
                  flex: 4,
                  child: spaced(col3Sections),
                ),
              ],
            ),
          );
        }

        if (tier == DashboardLayoutTier.tablet) {
          final left = spaced([
            hero,
            progress,
            stats,
            if (admin != null) admin,
          ]);
          final right = spaced([
            host,
            if (winner != null) winner,
            if (gifts != null) gifts,
          ]);

          return DashboardShell(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: gap),
                Expanded(child: right),
              ],
            ),
          );
        }

        return DashboardShell(
          child: spaced([
            hero,
            progress,
            stats,
            host,
            if (winner != null) winner,
            if (admin != null) admin,
            if (gifts != null) gifts,
          ]),
        );
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
    final giftCount = auction.giftTransactions?.length ?? 0;
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
              Row(
                children: [
                  _QuickStat(
                    label: AuctionDetailLabels.raised(l10n),
                    value:
                        CoinFormat.coinsAmount(auction.currentTotalCoins),
                    highlight: true,
                  ),
                  const SizedBox(width: DashboardSpace.xl),
                  _QuickStat(
                    label: AuctionDetailLabels.goal(l10n),
                    value: CoinFormat.coinsProgress(
                      current: auction.currentTotalCoins,
                      target: auction.targetPriceCoins,
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
    final giftCount = auction.giftTransactions?.length ?? 0;

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
              value: CoinFormat.coins(auction.targetPriceCoins),
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
              value: (auction.postId != null || auction.post != null)
                  ? l10n.tOr('yes', 'Yes')
                  : l10n.tOr('no', 'No'),
            ),
            MetricCard(
              icon: Icons.live_tv_outlined,
              label: l10n.tOr('liveSession', 'Live session'),
              value: (auction.liveId != null && auction.liveId!.isNotEmpty)
                  ? l10n.tOr('yes', 'Yes')
                  : l10n.tOr('no', 'No'),
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
    final pct = auction.progressPercent;
    final color = auctionProgressColor(scheme, auction);
    final remaining = (auction.targetPriceCoins - auction.currentTotalCoins)
        .clamp(0, double.infinity);

    return DashboardCard(
      backgroundColor: Color.alphaBlend(
        scheme.primaryContainer.withValues(alpha: 0.25),
        scheme.surface,
      ),
      child: DashboardSection(
        title: AuctionDetailLabels.progressTitle(l10n),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ProgressHighlight(
                    label: AuctionDetailLabels.raised(l10n),
                    value: CoinFormat.coins(auction.currentTotalCoins),
                    color: color,
                  ),
                ),
                Expanded(
                  child: _ProgressHighlight(
                    label: AuctionDetailLabels.remaining(l10n, context),
                    value: CoinFormat.coins(remaining),
                  ),
                ),
                Expanded(
                  child: _ProgressHighlight(
                    label: AuctionDetailLabels.goal(l10n),
                    value: CoinFormat.coins(auction.targetPriceCoins),
                  ),
                ),
                Container(
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
                ),
              ],
            ),
            const SizedBox(height: DashboardSpace.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder<double>(
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
                  Text(
                    AuctionDetailLabels.latestGift(l10n, lastGiftName!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
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

class _AuctionAdminSection extends StatelessWidget {
  const _AuctionAdminSection({required this.state});
  final AuctionDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auction = state.auction;

    if (!auction.isActive && auction.isCompleted) {
      return ActionPanel(
        title: l10n.t('actions'),
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
                Icon(Icons.check_circle_rounded,
                    size: 18, color: scheme.onPrimaryContainer),
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

    if (!auction.isActive) return const SizedBox.shrink();

    return ActionPanel(
      title: l10n.t('actions'),
      isLoading: state.isActioning,
      children: [
        ActionPanelButton(
          label: l10n.t('manuallyResolve'),
          icon: Icons.check_circle_rounded,
          onTap: () => _showResolveDialog(context),
        ),
        const SizedBox(height: DashboardSpace.md),
        ActionPanelButton(
          label: l10n.t('forceCancel'),
          icon: Icons.cancel_outlined,
          variant: ActionPanelButtonVariant.destructive,
          onTap: () => _confirmCancel(context),
        ),
        const SizedBox(height: DashboardSpace.md),
        ActionPanelButton(
          label: l10n.tOr('banAuction', 'Ban auction'),
          icon: Icons.block_outlined,
          variant: ActionPanelButtonVariant.destructive,
          onTap: () => _confirmBan(context),
        ),
        const SizedBox(height: DashboardSpace.md),
        ActionPanelButton(
          label: l10n.tOr('editAuction', 'Edit auction'),
          icon: Icons.edit_outlined,
          onTap: () => _showEditDialog(context, auction),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban auction'),
        content: const Text(
          'This will mark the auction as BANNED and remove it from active bidding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
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
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AuctionEntity auction) {
    final controller = TextEditingController(text: auction.itemName ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit auction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Item name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuctionDetailBloc>().add(
                    AdminUpdateAuctionEvent(itemName: controller.text.trim()),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
    this.expanded = false,
  });

  final AuctionEntity auction;
  final List<GiftTransactionEntity> transactions;
  final bool expanded;

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
      expanded: widget.expanded,
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
  const _ErrorBody({required this.message, required this.auctionId});
  final String message;
  final String auctionId;

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
                  .add(LoadAuctionDetailsEvent(auctionId)),
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
