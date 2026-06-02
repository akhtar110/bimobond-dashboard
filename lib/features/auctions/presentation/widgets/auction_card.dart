import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/auction_entity.dart';

class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    this.onViewDetails,
    this.onCancel,
  });

  final AuctionEntity auction;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ItemImage(auction: auction),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(auction: auction, onCancel: onCancel),
                const SizedBox(height: 8),
                _HostRow(auction: auction, isDark: isDark, theme: theme),
                const SizedBox(height: 12),
                _ProgressSection(auction: auction, theme: theme, isDark: isDark),
                const SizedBox(height: 12),
                _TimestampRow(auction: auction, theme: theme),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onViewDetails,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(l10n.t('viewDetails')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item Image ───────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.auction});
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final url = auction.itemImageUrl;
    return SizedBox(
      height: 160,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => _placeholder(context),
              errorWidget: (context, url, error) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F5F7),
      child: const Center(
        child: Icon(Icons.gavel_rounded, size: 48, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

// ─── Header (name + status badge + menu) ─────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.auction, this.onCancel});
  final AuctionEntity auction;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            auction.itemName?.isNotEmpty == true
                ? auction.itemName!
                : l10n.t('noData'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _StatusBadge(status: auction.status),
        if (auction.isActive && onCancel != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 30,
            height: 30,
            child: PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(l10n.t('forceCancel'),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'cancel') onCancel?.call();
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Host row ─────────────────────────────────────────────────────────────────

class _HostRow extends StatelessWidget {
  const _HostRow(
      {required this.auction, required this.isDark, required this.theme});
  final AuctionEntity auction;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor:
              isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF0F0F0),
          backgroundImage: auction.hostAvatar != null
              ? NetworkImage(auction.hostAvatar!)
              : null,
          child: auction.hostAvatar == null
              ? const Icon(Icons.person_rounded, size: 14, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${l10n.t('owner')}: ${auction.hostName}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Progress ─────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection(
      {required this.auction, required this.theme, required this.isDark});
  final AuctionEntity auction;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = auction.progressPercent;
    final color = auction.isCompleted
        ? Colors.green
        : auction.isCancelled
            ? Colors.grey
            : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${auction.currentTotalUsd.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              'of \$${auction.targetPriceUsd.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor:
                isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE8E9EB),
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(pct * 100).toStringAsFixed(1)}% funded',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ─── Timestamp ────────────────────────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.auction, required this.theme});
  final AuctionEntity auction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Row(
      children: [
        Icon(Icons.access_time_rounded,
            size: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 4),
        Text(
          fmt.format(auction.startedAt.toLocal()),
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        if (auction.endedAt != null) ...[
          Text(
            ' → ${fmt.format(auction.endedAt!.toLocal())}',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

class AuctionCardSkeleton extends StatefulWidget {
  const AuctionCardSkeleton({super.key});

  @override
  State<AuctionCardSkeleton> createState() => _AuctionCardSkeletonState();
}

class _AuctionCardSkeletonState extends State<AuctionCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEEEEF0);
    final highlight =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF8F8FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161622) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 160, color: color),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(color, 180, 14),
                    const SizedBox(height: 10),
                    _shimmerBox(color, 120, 12),
                    const SizedBox(height: 12),
                    _shimmerBox(color, double.infinity, 6),
                    const SizedBox(height: 12),
                    _shimmerBox(color, 100, 38, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(Color color, double width, double height,
      {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
