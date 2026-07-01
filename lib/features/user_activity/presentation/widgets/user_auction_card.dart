import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../auctions/domain/entities/auction_entity.dart';

class UserAuctionCard extends StatefulWidget {
  const UserAuctionCard({
    super.key,
    required this.auction,
    required this.isDark,
    this.onTap,
  });

  final AuctionEntity auction;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  State<UserAuctionCard> createState() => _UserAuctionCardState();
}

class _UserAuctionCardState extends State<UserAuctionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final auction = widget.auction;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final progress = auction.progressPercent;
    final isEnded = !auction.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(
                      alpha: _hovered ? 0.08 : 0.04,
                    ),
                    blurRadius: _hovered ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: auction.itemImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: auction.itemImageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _placeholder(scheme),
                            )
                          : _placeholder(scheme),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                auction.itemName ?? l10n.t('untitledAuction'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              status: auction.status,
                              scheme: scheme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              CoinFormat.coinsAmount(auction.currentTotalCoins),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              ' / ${CoinFormat.coinsAmount(auction.targetPriceCoins)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _UserAvatarChip(
                              label: auction.hostName,
                              avatarUrl: auction.hostAvatar,
                              caption: l10n.t('host'),
                              scheme: scheme,
                            ),
                            if (auction.winnerId != null) ...[
                              const SizedBox(width: 16),
                              _UserAvatarChip(
                                label: auction.winnerName ?? '—',
                                avatarUrl: auction.winnerAvatar,
                                caption: l10n.t('winner'),
                                scheme: scheme,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.t('started')}: ${dateFormat.format(auction.startedAt)}'
                          '${auction.endedAt != null ? '\n${isEnded ? l10n.t('ended') : l10n.t('ended')}: ${dateFormat.format(auction.endedAt!)}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.gavel_outlined,
        size: 32,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.scheme});

  final String status;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String label;

    switch (status) {
      case 'ACTIVE':
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        label = 'ACTIVE';
      case 'COMPLETED':
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        label = 'ENDED';
      case 'CANCELLED':
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        label = 'CANCELLED';
      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _UserAvatarChip extends StatelessWidget {
  const _UserAvatarChip({
    required this.label,
    this.avatarUrl,
    required this.caption,
    required this.scheme,
  });

  final String label;
  final String? avatarUrl;
  final String caption;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage:
              avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, size: 16, color: scheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
