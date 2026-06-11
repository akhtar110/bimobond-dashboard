import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/auction_entity.dart';

/// Status badge colors derived from the active [ColorScheme].
({Color fg, Color bg, String label}) auctionStatusStyle(
  ColorScheme scheme,
  AppLocalizations l10n,
  String status,
) {
  return switch (status) {
    'ACTIVE' => (
        fg: scheme.primary,
        bg: scheme.primaryContainer,
        label: l10n.t('active'),
      ),
    'COMPLETED' => (
        fg: scheme.secondary,
        bg: scheme.secondaryContainer,
        label: l10n.t('completed'),
      ),
    'CANCELLED' => (
        fg: scheme.error,
        bg: scheme.errorContainer,
        label: l10n.t('cancelled'),
      ),
    _ => (
        fg: scheme.onSurfaceVariant,
        bg: scheme.surfaceContainerHigh,
        label: status,
      ),
  };
}

Color auctionProgressColor(ColorScheme scheme, AuctionEntity auction) {
  if (auction.isCancelled) return scheme.outline;
  if (auction.isCompleted) return scheme.primary;
  return scheme.primary;
}

class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    this.previewImageUrl,
    this.onViewDetails,
    this.onCancel,
  });

  final AuctionEntity auction;
  final String? previewImageUrl;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ItemImage(
            auction: auction,
            previewImageUrl: previewImageUrl,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(auction: auction, onCancel: onCancel),
                const SizedBox(height: 8),
                _HostRow(auction: auction),
                const SizedBox(height: 12),
                _ProgressSection(auction: auction),
                const SizedBox(height: 12),
                _TimestampRow(auction: auction),
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
  const _ItemImage({
    required this.auction,
    this.previewImageUrl,
  });
  final AuctionEntity auction;
  final String? previewImageUrl;

  @override
  Widget build(BuildContext context) {
    final url = previewImageUrl ?? auction.displayImageUrl;
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
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

// ─── Header (name + status badge + menu) ─────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.auction, this.onCancel});
  final AuctionEntity auction;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            auction.itemName?.isNotEmpty == true
                ? auction.itemName!
                : l10n.t('noData'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: scheme.onSurface,
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
                      Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.t('forceCancel'),
                        style: const TextStyle(fontSize: 13),
                      ),
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
  const _HostRow({required this.auction});
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage: auction.hostAvatar != null
              ? NetworkImage(auction.hostAvatar!)
              : null,
          child: auction.hostAvatar == null
              ? Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${l10n.t('owner')}: ${auction.hostName}',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
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
  const _ProgressSection({required this.auction});
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = auction.progressPercent;
    final color = auctionProgressColor(scheme, auction);

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
                color: scheme.onSurfaceVariant,
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
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(pct * 100).toStringAsFixed(1)}% funded',
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Timestamp ────────────────────────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.auction});
  final AuctionEntity auction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('MMM d, yyyy');
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 12,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          fmt.format(auction.startedAt.toLocal()),
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        if (auction.endedAt != null) ...[
          Text(
            ' → ${fmt.format(auction.endedAt!.toLocal())}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    final style = auctionStatusStyle(scheme, context.l10n, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.fg,
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final base = scheme.surfaceContainerLow;
    final highlight = scheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
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
