import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/localization.dart';
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
                color: widget.isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
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
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
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
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              status: auction.status,
                              isDark: widget.isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '\$${auction.currentTotalUsd.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              ' / \$${auction.targetPriceUsd.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
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
                            backgroundColor: widget.isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _UserAvatarChip(
                              label: auction.hostName,
                              avatarUrl: auction.hostAvatar,
                              caption: l10n.t('host'),
                              isDark: widget.isDark,
                            ),
                            if (auction.winnerId != null) ...[
                              const SizedBox(width: 16),
                              _UserAvatarChip(
                                label: auction.winnerName ?? '—',
                                avatarUrl: auction.winnerAvatar,
                                caption: l10n.t('winner'),
                                isDark: widget.isDark,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.t('started')}: ${dateFormat.format(auction.startedAt)}'
                          '${auction.endedAt != null ? '\n${isEnded ? l10n.t('ended') : l10n.t('ended')}: ${dateFormat.format(auction.endedAt!)}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
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

  Widget _placeholder() {
    return ColoredBox(
      color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: const Icon(Icons.gavel_outlined, size: 32),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isDark});

  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        label = 'ACTIVE';
      case 'COMPLETED':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        label = 'ENDED';
      case 'CANCELLED':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        label = 'CANCELLED';
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
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
    required this.isDark,
  });

  final String label;
  final String? avatarUrl;
  final String caption;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage:
              avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, size: 16, color: Colors.grey.shade400)
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
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
