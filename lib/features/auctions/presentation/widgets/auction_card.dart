import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/auction_entity.dart';

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
        final width = constraints.maxWidth;
        final compact = width < 170;
        final dense = width < 210;
        final bodyPadding = EdgeInsets.fromLTRB(
          compact ? 8 : 10,
          compact ? 6 : 8,
          compact ? 8 : 10,
          compact ? 6 : 8,
        );
        final gap = compact ? 4.0 : 5.0;
        final borderRadius = compact ? 10.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ItemImage(
                auction: auction,
                previewImageUrl: previewImageUrl,
                compact: compact,
              ),
              Padding(
                padding: bodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderRow(
                      auction: auction,
                      onCancel: onCancel,
                      compact: compact,
                    ),
                    SizedBox(height: gap),
                    Row(
                      children: [
                        Expanded(
                          child: _HostRow(auction: auction, compact: true),
                        ),
                        const SizedBox(width: 4),
                        _TimestampRow(auction: auction, compact: true),
                      ],
                    ),
                    SizedBox(height: gap),
                    _ProgressSection(auction: auction, compact: true),
                    SizedBox(height: dense ? 6 : 8),
                    FilledButton(
                      onPressed: onViewDetails,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(compact ? 32 : 34),
                        textStyle: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
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
              fontSize: compact ? 12 : 12.5,
              letterSpacing: -0.1,
              height: 1.15,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        AuctionStatusBadge(status: auction.status, compact: compact),
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

// ─── Item Image ───────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  const _ItemImage({
    required this.auction,
    this.previewImageUrl,
    this.compact = false,
  });
  final AuctionEntity auction;
  final String? previewImageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = previewImageUrl ?? auction.displayImageUrl;

    return AspectRatio(
      // Wider than tall so grid cards stay shorter — same as GiftCard.
      aspectRatio: compact ? 1.45 : 1.55,
      child: ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        child: url != null && url.isNotEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, imageUrl) =>
                        _placeholder(scheme, compact),
                    errorWidget: (context, imageUrl, error) =>
                        _placeholder(scheme, compact),
                  );
                },
              )
            : _placeholder(scheme, compact),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, bool compact) => Center(
        child: Icon(
          Icons.gavel_rounded,
          size: compact ? 24 : 28,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
      );
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
    final avatarRadius = compact ? 9.0 : 11.0;
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
                  size: compact ? 11 : 13,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            '${l10n.t('owner')}: ${auction.hostName}',
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
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
          children: [
            Flexible(
              child: Text(
                '🪙 ${CoinFormat.coinsAmount(auction.currentTotalCoins)}',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '/ 🪙 ${CoinFormat.coinsAmount(auction.effectiveTargetPriceCoins)}',
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: compact ? 4 : 5,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        SizedBox(height: compact ? 3 : 4),
        Text(
          '${(pct * 100).toStringAsFixed(1)}% funded',
          style: TextStyle(
            fontSize: compact ? 9.5 : 10.5,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
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
    final fmt = DateFormat('MMM d');
    final fontSize = compact ? 9.5 : 10.5;
    final ended = auction.endedAt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: compact ? 10 : 11,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 3 : 4),
        Text(
          ended != null
              ? '${fmt.format(auction.startedAt.toLocal())} → ${fmt.format(ended.toLocal())}'
              : fmt.format(auction.startedAt.toLocal()),
          style: TextStyle(
            fontSize: fontSize,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class AuctionStatusBadge extends StatelessWidget {
  const AuctionStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = auctionStatusStyle(scheme, context.l10n, status);
    final fg = style.fg;
    final bg = style.bg.withValues(alpha: compact ? 0.95 : 1);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: fg,
          fontSize: compact ? 8.5 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final bodyPadding = EdgeInsets.fromLTRB(
          compact ? 8 : 10,
          compact ? 6 : 8,
          compact ? 8 : 10,
          compact ? 6 : 8,
        );

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
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: compact ? 1.45 : 1.55,
                    child: ColoredBox(color: color),
                  ),
                  Padding(
                    padding: bodyPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(color, compact ? 90 : 110, 12),
                        const SizedBox(height: 5),
                        _shimmerBox(color, compact ? 80 : 100, 11),
                        const SizedBox(height: 5),
                        _shimmerBox(color, double.infinity, 4),
                        const SizedBox(height: 7),
                        _shimmerBox(color, compact ? 72 : 84, 32, radius: 8),
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
