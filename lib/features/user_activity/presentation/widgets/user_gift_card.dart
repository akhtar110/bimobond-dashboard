import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_gift_transaction_entity.dart';

class UserGiftCard extends StatefulWidget {
  const UserGiftCard({
    super.key,
    required this.transaction,
    required this.isDark,
  });

  final UserGiftTransactionEntity transaction;
  final bool isDark;

  @override
  State<UserGiftCard> createState() => _UserGiftCardState();
}

class _UserGiftCardState extends State<UserGiftCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tx = widget.transaction;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
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
                  width: 64,
                  height: 64,
                  child: tx.giftThumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: tx.giftThumbnail!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _giftPlaceholder(),
                        )
                      : _giftPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.giftName ?? l10n.t('gift'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '\$${tx.priceUsd.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PartyRow(
                            label: l10n.t('sender'),
                            name: tx.senderName,
                            avatarUrl: tx.senderAvatar,
                            isDark: widget.isDark,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: widget.isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        Expanded(
                          child: _PartyRow(
                            label: l10n.t('receiver'),
                            name: tx.receiverName,
                            avatarUrl: tx.receiverAvatar,
                            isDark: widget.isDark,
                          ),
                        ),
                      ],
                    ),
                    if (tx.postId != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${l10n.t('post')}: ${tx.postId!.length > 12 ? '${tx.postId!.substring(0, 12)}…' : tx.postId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(tx.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _giftPlaceholder() {
    return ColoredBox(
      color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: const Icon(Icons.card_giftcard, size: 28),
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.label,
    required this.name,
    this.avatarUrl,
    required this.isDark,
  });

  final String label;
  final String name;
  final String? avatarUrl;
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
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
