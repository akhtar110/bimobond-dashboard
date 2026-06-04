import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';
import '../bloc/gifts_bloc.dart';

// ─── Main card ────────────────────────────────────────────────────────────────

class GiftCard extends StatelessWidget {
  const GiftCard({
    super.key,
    required this.gift,
    this.onEdit,
    this.onDelete,
  });

  final GiftEntity gift;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E3440)
              : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GiftThumbnail(gift: gift),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        gift.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActiveBadge(isActive: gift.isActive),
                  ],
                ),
                const SizedBox(height: 8),

                // Published date
                _PublishedDate(gift: gift),
                const SizedBox(height: 8),

                // Price chip + animated badge
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PriceChip(theme: theme, priceUsd: gift.priceUsd),
                    if (gift.animationUrl != null &&
                        gift.animationUrl!.isNotEmpty)
                      _MiniChip(
                        icon: Icons.animation_rounded,
                        label: 'Animated',
                        isDark: isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: Text(l10n.t('edit'),
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ToggleButton(gift: gift),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton.outlined(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Published date ───────────────────────────────────────────────────────────

class _PublishedDate extends StatelessWidget {
  const _PublishedDate({required this.gift});
  final GiftEntity gift;

  static final _fmt = DateFormat('MMM d, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final date = gift.createdAt;

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            date != null
                ? 'Published ${_fmt.format(date.toLocal())}'
                : 'Publish date unavailable',
            style: TextStyle(
              fontSize: 11,
              color: muted,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Price chip ───────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.theme, required this.priceUsd});
  final ThemeData theme;
  final double priceUsd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '\$${priceUsd.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ─── Mini chip ────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _GiftThumbnail extends StatelessWidget {
  const _GiftThumbnail({required this.gift});
  final GiftEntity gift;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: gift.thumbnailUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: gift.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(isDark),
              errorWidget: (_, __, ___) => _placeholder(isDark),
            )
          : _placeholder(isDark),
    );
  }

  Widget _placeholder(bool isDark) => Container(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F5F7),
        child: const Center(
          child: Icon(Icons.card_giftcard_rounded,
              size: 40, color: Color(0xFF9CA3AF)),
        ),
      );
}

// ─── Active badge ─────────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l10n.t('activeLabel') : l10n.t('inactive'),
        style: TextStyle(
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Toggle button ────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.gift});
  final GiftEntity gift;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: 36,
      height: 36,
      child: Tooltip(
        message: gift.isActive ? l10n.t('deactivate') : l10n.t('activate'),
        child: IconButton.outlined(
          onPressed: () => context
              .read<GiftsBloc>()
              .add(ToggleGiftActiveEvent(gift.id, !gift.isActive)),
          icon: Icon(
            gift.isActive
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 16,
            color: gift.isActive ? Colors.orange : Colors.green,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class GiftCardSkeleton extends StatefulWidget {
  const GiftCardSkeleton({super.key});

  @override
  State<GiftCardSkeleton> createState() => _GiftCardSkeletonState();
}

class _GiftCardSkeletonState extends State<GiftCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEEEEF0);
    final hi = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF8F8FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c = Color.lerp(base, hi, _anim.value)!;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161622) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2E3440)
                  : const Color(0xFFE8ECF0),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 4 / 3, child: ColoredBox(color: c)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sh(c, 150, 14),
                    const SizedBox(height: 8),
                    _sh(c, 110, 11),
                    const SizedBox(height: 8),
                    _sh(c, 80, 26, r: 8),
                    const SizedBox(height: 12),
                    _sh(c, double.infinity, 36, r: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sh(Color color, double w, double h, {double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}
