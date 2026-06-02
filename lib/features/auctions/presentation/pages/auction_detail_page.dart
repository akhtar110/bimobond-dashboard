import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/gift_transaction_entity.dart';
import '../bloc/auction_detail_bloc.dart';

class AuctionDetailPage extends StatefulWidget {
  const AuctionDetailPage({super.key, required this.auctionId});
  final String auctionId;

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuctionDetailBloc>().add(
          LoadAuctionDetailsEvent(widget.auctionId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(context.l10n.t('auctionDetails')),
        backgroundColor: isDark ? const Color(0xFF161622) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<AuctionDetailBloc, AuctionDetailState>(
        listener: (context, state) {
          if (state is AuctionDetailLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
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
                message: state.message, auctionId: widget.auctionId);
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

// ─── Main Detail Body ─────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state});
  final AuctionDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auction = state.auction;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LiveIndicator(
                      isLive: state.isLive, auction: auction),
                  const SizedBox(height: 20),
                  _ItemSection(
                      auction: auction, isDark: isDark, theme: theme),
                  const SizedBox(height: 20),
                  _ProgressSection(
                      auction: auction, theme: theme, isDark: isDark,
                      lastGiftName: state.lastGiftName),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _InfoCard(
                              auction: auction,
                              isDark: isDark,
                              theme: theme)),
                      const SizedBox(width: 16),
                      if (auction.winner != null ||
                          auction.isCompleted)
                        Expanded(
                            child: _WinnerCard(
                                auction: auction,
                                isDark: isDark,
                                theme: theme)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (auction.isActive || auction.isCompleted)
                    _AdminActionsCard(
                        state: state, isDark: isDark, theme: theme),
                  if (auction.giftTransactions?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    _GiftTransactionsCard(
                        transactions: auction.giftTransactions!,
                        isDark: isDark,
                        theme: theme),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Live Indicator ───────────────────────────────────────────────────────────

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.isLive, required this.auction});
  final bool isLive;
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        if (isLive) ...[
          _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            l10n.t('live').toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Real-time updates active',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ] else if (auction.isActive) ...[
          const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          const Text(
            'Connecting to live updates...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            const Color(0xFF16A34A),
            const Color(0xFF4ADE80),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

// ─── Item Section ─────────────────────────────────────────────────────────────

class _ItemSection extends StatelessWidget {
  const _ItemSection(
      {required this.auction, required this.isDark, required this.theme});
  final AuctionEntity auction;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 110,
            height: 110,
            child: auction.itemImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: auction.itemImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _ph(isDark),
                    errorWidget: (context, url, error) => _ph(isDark),
                  )
                : _ph(isDark),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auction.itemName?.isNotEmpty == true
                    ? auction.itemName!
                    : context.l10n.t('noData'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StatusBadge(status: auction.status),
                  const SizedBox(width: 10),
                  Text(
                    'Started ${DateFormat('MMM d, yyyy').format(auction.startedAt.toLocal())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              if (auction.endedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Ended ${DateFormat('MMM d, yyyy h:mm a').format(auction.endedAt!.toLocal())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ph(bool isDark) => Container(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F5F7),
        child: const Center(
          child: Icon(Icons.gavel_rounded, size: 36, color: Color(0xFF9CA3AF)),
        ),
      );
}

// ─── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.auction,
    required this.theme,
    required this.isDark,
    this.lastGiftName,
  });
  final AuctionEntity auction;
  final ThemeData theme;
  final bool isDark;
  final String? lastGiftName;

  @override
  Widget build(BuildContext context) {
    final pct = auction.progressPercent;
    final color = auction.isCompleted
        ? Colors.green
        : auction.isCancelled
            ? Colors.grey
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E8EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${auction.currentTotalUsd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    'raised of \$${auction.targetPriceUsd.toStringAsFixed(2)} goal',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: pct),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E9EB),
                  color: color,
                );
              },
            ),
          ),
          if (lastGiftName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.card_giftcard_rounded,
                    size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  'Latest: $lastGiftName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info Card (Host) ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.auction, required this.isDark, required this.theme});
  final AuctionEntity auction;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E8EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('owner'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? const Color(0xFF2A2A3A)
                    : const Color(0xFFF0F0F0),
                backgroundImage: auction.hostAvatar != null
                    ? NetworkImage(auction.hostAvatar!)
                    : null,
                child: auction.hostAvatar == null
                    ? const Icon(Icons.person_rounded, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.hostName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      auction.hostId,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (auction.postId != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.link_rounded,
              label: l10n.t('postId'),
              value: auction.postId!,
              theme: theme,
            ),
          ],
          if (auction.startingPriceUsd > 0) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.attach_money_rounded,
              label: l10n.t('startingPrice'),
              value: '\$${auction.startingPriceUsd.toStringAsFixed(2)}',
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.theme});
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Winner Card ──────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  const _WinnerCard(
      {required this.auction, required this.isDark, required this.theme});
  final AuctionEntity auction;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = auction.winner;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'Winner',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFD97706),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (winner != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A3A)
                      : const Color(0xFFF0F0F0),
                  backgroundImage:
                      winner['avatarUrl'] != null
                          ? NetworkImage(winner['avatarUrl'] as String)
                          : null,
                  child: winner['avatarUrl'] == null
                      ? const Icon(Icons.person_rounded, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.winnerName ?? l10n.t('notAvailable'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        auction.winnerId ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              auction.winnerId ?? l10n.t('loading'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Admin Actions Card ───────────────────────────────────────────────────────

class _AdminActionsCard extends StatelessWidget {
  const _AdminActionsCard(
      {required this.state, required this.isDark, required this.theme});
  final AuctionDetailLoaded state;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auction = state.auction;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E8EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('actions'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (state.isActioning) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (auction.isActive) ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: Colors.orange),
                    label: Text(l10n.t('forceCancel')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showResolveDialog(context),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(l10n.t('manuallyResolve')),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                if (auction.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t('completed'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('forceCancelAuctionTitle')),
        content: const Text(
            'This will immediately cancel the auction. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.t('keepActive'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionDetailBloc>()
                  .add(AdminCancelDetailAuctionEvent());
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.t('cancelAuction')),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('manuallyResolveAuctionTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('manuallyResolveAuctionHint')),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: l10n.t('winnerUserId'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.t('cancel'))),
          FilledButton(
            onPressed: () {
              final winnerId = ctrl.text.trim();
              if (winnerId.isEmpty) return;
              Navigator.pop(ctx);
              context
                  .read<AuctionDetailBloc>()
                  .add(AdminResolveAuctionEvent(winnerId));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.t('resolve')),
          ),
        ],
      ),
    );
  }
}

// ─── Gift Transactions ────────────────────────────────────────────────────────

class _GiftTransactionsCard extends StatelessWidget {
  const _GiftTransactionsCard({
    required this.transactions,
    required this.isDark,
    required this.theme,
  });
  final List<GiftTransactionEntity> transactions;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE6E8EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.t('giftTransactions'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFEEEEF0)),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF0F0F0),
                      backgroundImage: tx.senderAvatar != null
                          ? NetworkImage(tx.senderAvatar!)
                          : null,
                      child: tx.senderAvatar == null
                          ? const Icon(Icons.person_rounded,
                              size: 14, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.senderName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (tx.giftName != null)
                            Row(
                              children: [
                                if (tx.giftThumbnail != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Image.network(
                                      tx.giftThumbnail!,
                                      width: 14,
                                      height: 14,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                Text(
                                  tx.giftName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+\$${tx.contributionUsd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a')
                              .format(tx.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, bg, label) = switch (status) {
      'ACTIVE' => (
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          l10n.t('active')
        ),
      'COMPLETED' => (
          const Color(0xFF2563EB),
          const Color(0xFFDBEAFE),
          l10n.t('completed')
        ),
      'CANCELLED' => (
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
          l10n.t('cancelled')
        ),
      _ => (const Color(0xFF6B7280), const Color(0xFFF3F4F6), status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.auctionId});
  final String message;
  final String auctionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(l10n.t('failedToLoadAuction'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context
                  .read<AuctionDetailBloc>()
                  .add(LoadAuctionDetailsEvent(auctionId)),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.t('retry')),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
