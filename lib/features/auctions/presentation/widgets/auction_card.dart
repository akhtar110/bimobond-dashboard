import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/auction_entity.dart';
import '../utils/auctions_responsive.dart';

/// Status badge colors derived from the active [ColorScheme].
({Color fg, Color bg, String label}) auctionStatusStyle(
  ColorScheme scheme,
  AppLocalizations l10n,
  String status,
) {
  return switch (status.toUpperCase()) {
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
    'BANNED' => (
        fg: scheme.onErrorContainer,
        bg: scheme.errorContainer,
        label: l10n.tOr('banned', 'Banned'),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final bodyPadding = compact ? 10.0 : 14.0;
        final sectionGap = compact ? 8.0 : 12.0;
        final smallGap = compact ? 6.0 : 8.0;
        final borderRadius = compact ? 10.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: compact ? 8 : 12,
                offset: Offset(0, compact ? 2 : 3),
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
                cardWidth: constraints.maxWidth,
              ),
              Padding(
                padding: EdgeInsets.all(bodyPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderRow(
                      auction: auction,
                      onCancel: onCancel,
                      compact: compact,
                    ),
                    SizedBox(height: smallGap),
                    _HostRow(auction: auction, compact: compact),
                    SizedBox(height: sectionGap),
                    _ProgressSection(
                      auction: auction,
                      compact: compact,
                    ),
                    SizedBox(height: sectionGap),
                    _TimestampRow(auction: auction, compact: compact),
                    SizedBox(height: sectionGap),
                    FilledButton(
                      onPressed: onViewDetails,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(compact ? 34 : 38),
                        textStyle: TextStyle(
                          fontSize: compact ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            compact ? 8 : 10,
                          ),
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
      },
    );
  }
}

// ─── Item Image ───────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  const _ItemImage({
    required this.auction,
    this.previewImageUrl,
    required this.cardWidth,
  });
  final AuctionEntity auction;
  final String? previewImageUrl;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final url = previewImageUrl ?? auction.displayImageUrl;
    final imageHeight = auctionCardImageHeight(cardWidth);
    final compact = cardWidth < 220;
    return SizedBox(
      height: imageHeight,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => _placeholder(context, compact),
              errorWidget: (context, url, error) =>
                  _placeholder(context, compact),
            )
          : _placeholder(context, compact),
    );
  }

  Widget _placeholder(BuildContext context, bool compact) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.gavel_rounded,
          size: compact ? 36 : 48,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Header (name + status badge + menu) ─────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.auction,
    this.onCancel,
    this.compact = false,
  });
  final AuctionEntity auction;
  final VoidCallback? onCancel;
  final bool compact;

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
              fontSize: compact ? 13 : 15,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        _StatusBadge(status: auction.status, compact: compact),
        if (auction.isActive && onCancel != null) ...[
          SizedBox(width: compact ? 2 : 4),
          SizedBox(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            child: PopupMenuButton<String>(
              iconSize: compact ? 16 : 18,
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
  const _HostRow({required this.auction, this.compact = false});
  final AuctionEntity auction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final avatarRadius = compact ? 10.0 : 12.0;
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage: auction.hostAvatar != null
              ? NetworkImage(auction.hostAvatar!)
              : null,
          child: auction.hostAvatar == null
              ? Icon(
                  Icons.person_rounded,
                  size: compact ? 12 : 14,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            '${l10n.t('owner')}: ${auction.hostName}',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
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
  const _ProgressSection({required this.auction, this.compact = false});
  final AuctionEntity auction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = auction.progressFraction;
    final color = auctionProgressColor(scheme, auction);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CoinFormat.coinsAmount(auction.currentTotalCoins),
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              'of ${CoinFormat.coins(auction.effectiveTargetPriceCoins)}',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: compact ? 5 : 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        SizedBox(height: compact ? 3 : 4),
        Text(
          '${(pct * 100).toStringAsFixed(1)}% funded',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Timestamp ────────────────────────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.auction, this.compact = false});
  final AuctionEntity auction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('MMM d, yyyy');
    final fontSize = compact ? 10.0 : 11.0;
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: compact ? 11 : 12,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 3 : 4),
        Flexible(
          child: Text(
            fmt.format(auction.startedAt.toLocal()),
            style: TextStyle(fontSize: fontSize, color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (auction.endedAt != null)
          Flexible(
            child: Text(
              ' → ${fmt.format(auction.endedAt!.toLocal())}',
              style: TextStyle(
                fontSize: fontSize,
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

// ─── Status Badge ─────────────────────────────────────────────────────────────

class AuctionStatusBadge extends StatelessWidget {
  const AuctionStatusBadge({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = auctionStatusStyle(scheme, context.l10n, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: style.fg.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.fg,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.compact = false});
  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AuctionStatusBadge(status: status, compact: compact);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final imageHeight = auctionCardImageHeight(constraints.maxWidth);
        final bodyPadding = compact ? 10.0 : 14.0;

        return AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final color = Color.lerp(base, highlight, _anim.value)!;
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(compact ? 10 : 12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: imageHeight, color: color),
                  Padding(
                    padding: EdgeInsets.all(bodyPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(color, compact ? 140 : 180, compact ? 12 : 14),
                        SizedBox(height: compact ? 8 : 10),
                        _shimmerBox(color, compact ? 100 : 120, compact ? 10 : 12),
                        SizedBox(height: compact ? 8 : 12),
                        _shimmerBox(color, double.infinity, compact ? 5 : 6),
                        SizedBox(height: compact ? 8 : 12),
                        _shimmerBox(
                          color,
                          100,
                          compact ? 34 : 38,
                          radius: compact ? 8 : 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
