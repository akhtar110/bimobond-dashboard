import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_user_by_id.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/gift_transaction_entity.dart';
import '../bloc/auction_detail_bloc.dart';
import '../bloc/auctions_bloc.dart';
import '../widgets/auction_card.dart';

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

  /// Propagates a status change to the app-level [AuctionsBloc] so the list
  /// page recalculates tabs/counts without a full reload.
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
        title: Text(context.l10n.t('auctionDetails')),
        backgroundColor: scheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
                  _ItemSection(auction: auction, theme: theme),
                  const SizedBox(height: 20),
                  _ProgressSection(
                      auction: auction,
                      theme: theme,
                      lastGiftName: state.lastGiftName),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _InfoCard(
                              auction: auction, theme: theme)),
                      const SizedBox(width: 16),
                      if (auction.winner != null ||
                          auction.isCompleted)
                        Expanded(
                            child: _WinnerCard(
                                auction: auction, theme: theme)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (auction.isActive || auction.isCompleted)
                    _AdminActionsCard(state: state, theme: theme),
                  if (auction.giftTransactions?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    _GiftTransactionsCard(
                        auction: auction,
                        transactions: auction.giftTransactions!,
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (isLive) ...[
          _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            l10n.t('live').toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Real-time updates active',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ] else if (auction.isActive) ...[
          Icon(Icons.wifi_off_rounded,
              size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Connecting to live updates...',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 10,
        height: 10,
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

// ─── Item Section ─────────────────────────────────────────────────────────────

class _ItemSection extends StatelessWidget {
  const _ItemSection({required this.auction, required this.theme});
  final AuctionEntity auction;
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
                    placeholder: (context, url) => _ph(context),
                    errorWidget: (context, url, error) => _ph(context),
                  )
                : _ph(context),
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

  Widget _ph(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.gavel_rounded,
          size: 36,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.auction,
    required this.theme,
    this.lastGiftName,
  });
  final AuctionEntity auction;
  final ThemeData theme;
  final String? lastGiftName;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final pct = auction.progressPercent;
    final color = auctionProgressColor(scheme, auction);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: color,
                );
              },
            ),
          ),
          if (lastGiftName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.card_giftcard_rounded,
                    size: 14, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Latest: $lastGiftName',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.primary,
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
  const _InfoCard({required this.auction, required this.theme});
  final AuctionEntity auction;
  final ThemeData theme;

  String? _hostField(String key) {
    final value = auction.host?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final dateFmt = DateFormat('MMM d, yyyy · h:mm a');

    final fullName = _hostField('fullName');
    final username = _hostField('username');
    final email = _hostField('email');
    final displayName = fullName ?? auction.hostName;
    final giftCount = auction.giftTransactions?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage: auction.hostAvatar != null
                    ? NetworkImage(auction.hostAvatar!)
                    : null,
                child: auction.hostAvatar == null
                    ? Icon(Icons.person_rounded,
                        color: scheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (username != null)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    if (email != null)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            l10n.t('auctionDetails'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.tag_rounded,
            label: l10n.tOr('auctionId', 'Auction ID'),
            value: auction.id,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: l10n.t('status'),
            value: auctionStatusStyle(scheme, l10n, auction.status).label,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.attach_money_rounded,
            label: l10n.t('startingPrice'),
            value: '\$${auction.startingPriceUsd.toStringAsFixed(2)}',
            theme: theme,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.flag_rounded,
            label: l10n.t('auctionTargetPrice'),
            value: '\$${auction.targetPriceUsd.toStringAsFixed(2)}',
            theme: theme,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.t('auctionStartDate'),
            value: dateFmt.format(auction.startedAt.toLocal()),
            theme: theme,
          ),
          if (auction.endedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.event_busy_outlined,
              label: l10n.t('auctionEndDate'),
              value: dateFmt.format(auction.endedAt!.toLocal()),
              theme: theme,
            ),
          ],
          if (giftCount > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.card_giftcard_outlined,
              label: l10n.t('giftTransactions'),
              value: '$giftCount',
              theme: theme,
            ),
          ],
          if (auction.postId != null || auction.post != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.image_outlined,
              label: l10n.tOr('linkedPost', 'Linked post'),
              value: l10n.tOr('yes', 'Yes'),
              theme: theme,
            ),
          ],
          if (auction.liveId != null && auction.liveId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.live_tv_outlined,
              label: l10n.tOr('liveSession', 'Live session'),
              value: l10n.tOr('yes', 'Yes'),
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
  const _WinnerCard({required this.auction, required this.theme});
  final AuctionEntity auction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final winner = auction.winner;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.tertiary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 16, color: scheme.tertiary),
              const SizedBox(width: 6),
              Text(
                'Winner',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onTertiaryContainer,
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
                  backgroundColor: scheme.surfaceContainerHighest,
                  backgroundImage:
                      winner['avatarUrl'] != null
                          ? NetworkImage(winner['avatarUrl'] as String)
                          : null,
                  child: winner['avatarUrl'] == null
                      ? Icon(Icons.person_rounded,
                          color: scheme.onSurfaceVariant)
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
  const _AdminActionsCard({required this.state, required this.theme});
  final AuctionDetailLoaded state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final auction = state.auction;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
                    icon: Icon(Icons.cancel_outlined,
                        size: 16, color: scheme.tertiary),
                    label: Text(l10n.t('forceCancel')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.tertiary,
                      side: BorderSide(color: scheme.tertiary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showResolveDialog(context),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(l10n.t('manuallyResolve')),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
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
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t('completed'),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
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

  void _showResolveDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ResolveAuctionDialog(
        onResolve: (winnerId) {
          context.read<AuctionDetailBloc>().add(AdminResolveAuctionEvent(winnerId));
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
            const SizedBox(height: 16),
            AdminUserSearchField(
              selectedUser: _selectedUser,
              label: l10n.t('selectWinner'),
              onUserSelected: (user) => setState(() => _selectedUser = user),
            ),
            if (_selectedUser == null) ...[
              const SizedBox(height: 10),
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

// ─── Gift Transactions ────────────────────────────────────────────────────────

class _GiftTransactionsCard extends StatefulWidget {
  const _GiftTransactionsCard({
    required this.auction,
    required this.transactions,
    required this.theme,
  });
  final AuctionEntity auction;
  final List<GiftTransactionEntity> transactions;
  final ThemeData theme;

  @override
  State<_GiftTransactionsCard> createState() => _GiftTransactionsCardState();
}

class _GiftTransactionsCardState extends State<_GiftTransactionsCard> {
  final Map<String, String> _resolvedSenderNames = {};

  @override
  void initState() {
    super.initState();
    _loadSenderNames();
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

  @override
  Widget build(BuildContext context) {
    final transactions = widget.transactions;
    final theme = widget.theme;
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
                Divider(height: 1, color: scheme.outlineVariant),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final senderDisplayName = _resolvedSenderNames[tx.senderId] ??
                  _giftSenderDisplayName(tx, widget.auction);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: tx.senderAvatar != null
                          ? NetworkImage(tx.senderAvatar!)
                          : null,
                      child: tx.senderAvatar == null
                          ? Icon(Icons.person_rounded,
                              size: 14, color: scheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderDisplayName,
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: scheme.primary,
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

bool _looksLikeUsername(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.startsWith('user_') || !trimmed.contains(' ');
}

String? _displayNameFromUserMap(Map<String, dynamic>? user) {
  if (user == null) return null;

  final nested = user['user'];
  if (nested is Map) {
    final nestedName = _displayNameFromUserMap(
      Map<String, dynamic>.from(nested),
    );
    if (nestedName != null) return nestedName;
  }

  final username = user['username']?.toString().trim();
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

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = auctionStatusStyle(scheme, context.l10n, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: style.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        style.label,
        style: TextStyle(
            color: style.fg, fontSize: 11, fontWeight: FontWeight.w700),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: scheme.error),
            const SizedBox(height: 16),
            Text(l10n.t('failedToLoadAuction'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant)),
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
