import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final bodyPadding = compact
            ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
            : const EdgeInsets.fromLTRB(14, 12, 14, 14);
        final sectionGap = compact ? 6.0 : 8.0;
        final actionGap = compact ? 6.0 : 8.0;
        final borderRadius = compact ? 10.0 : 14.0;
        final actionSize = compact ? 32.0 : 36.0;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: compact ? 8 : 14,
                offset: Offset(0, compact ? 2 : 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GiftThumbnail(gift: gift, compact: compact),
              Padding(
                padding: bodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            gift.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  fontSize: compact ? 13 : null,
                                ),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: actionGap),
                        _ActiveBadge(isActive: gift.isActive, compact: compact),
                      ],
                    ),
                    SizedBox(height: sectionGap),
                    _PublishedDate(gift: gift, compact: compact),
                    SizedBox(height: sectionGap),
                    Wrap(
                      spacing: actionGap,
                      runSpacing: compact ? 4 : 6,
                      children: [
                        _PriceChip(priceCoins: gift.priceCoins, compact: compact),
                        if (gift.animationUrl != null &&
                            gift.animationUrl!.isNotEmpty)
                          _MiniChip(
                            icon: Icons.animation_rounded,
                            label: compact ? '' : 'Animated',
                            compact: compact,
                          ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit_rounded,
                              size: compact ? 12 : 14,
                            ),
                            label: Text(
                              l10n.t('edit'),
                              style: TextStyle(fontSize: compact ? 11 : 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 8 : 10,
                                vertical: compact ? 6 : 8,
                              ),
                              minimumSize: Size(0, compact ? 32 : 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  compact ? 6 : 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: actionGap),
                        _ToggleButton(gift: gift, size: actionSize),
                        SizedBox(width: actionGap),
                        SizedBox(
                          width: actionSize,
                          height: actionSize,
                          child: IconButton.outlined(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: compact ? 14 : 16,
                              color: scheme.error,
                            ),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  compact ? 6 : 8,
                                ),
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
      },
    );
  }
}

// ─── Published date ───────────────────────────────────────────────────────────

class _PublishedDate extends StatelessWidget {
  const _PublishedDate({required this.gift, this.compact = false});
  final GiftEntity gift;
  final bool compact;

  static final _fmt = DateFormat('MMM d, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = gift.publishedAt;

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: compact ? 11 : 12,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 4 : 5),
        Expanded(
          child: Text(
            date != null
                ? (compact
                    ? DateFormat('MMM d, yyyy').format(date.toLocal())
                    : 'Published ${_fmt.format(date.toLocal())}')
                : 'Publish date unavailable',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Price chip ───────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.priceCoins, this.compact = false});
  final double priceCoins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Text(
        CoinFormat.coins(priceCoins),
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
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
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 12, color: scheme.onSurfaceVariant),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _GiftThumbnail extends StatelessWidget {
  const _GiftThumbnail({required this.gift, this.compact = false});
  final GiftEntity gift;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: compact ? 1.1 : 4 / 3,
      child: gift.thumbnailUrl.isNotEmpty
          ? ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: CachedNetworkImage(
                imageUrl: gift.thumbnailUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => _placeholder(scheme, compact),
                errorWidget: (_, __, ___) => _placeholder(scheme, compact),
              ),
            )
          : _placeholder(scheme, compact),
    );
  }

  Widget _placeholder(ColorScheme scheme, bool compact) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.card_giftcard_rounded,
            size: compact ? 28 : 40,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
}

// ─── Active badge ─────────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive, this.compact = false});
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
    final bg =
        isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l10n.t('activeLabel') : l10n.t('inactive'),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Toggle button ────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.gift, this.size = 36});
  final GiftEntity gift;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Tooltip(
        message: gift.isActive ? l10n.t('deactivate') : l10n.t('activate'),
        child: IconButton.outlined(
          onPressed: () => context
              .read<GiftsBloc>()
              .add(ToggleGiftActiveEvent(gift.id, !gift.isActive)),
          icon: Icon(
            gift.isActive
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: size <= 32 ? 14 : 16,
            color: gift.isActive ? scheme.tertiary : scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final hi = scheme.surfaceContainerLow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final borderRadius = compact ? 10.0 : 14.0;
        final bodyPadding = compact
            ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
            : const EdgeInsets.fromLTRB(14, 12, 14, 14);

        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final c = Color.lerp(base, hi, _anim.value)!;
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: compact ? 1.1 : 4 / 3,
                    child: ColoredBox(color: c),
                  ),
                  Padding(
                    padding: bodyPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sh(c, compact ? 120 : 150, compact ? 12 : 14),
                        SizedBox(height: compact ? 6 : 8),
                        _sh(c, compact ? 90 : 110, compact ? 10 : 11),
                        SizedBox(height: compact ? 6 : 8),
                        _sh(c, compact ? 70 : 80, compact ? 22 : 26, r: 8),
                        SizedBox(height: compact ? 8 : 12),
                        _sh(c, double.infinity, compact ? 32 : 36, r: 8),
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

  Widget _sh(Color color, double w, double h, {double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}
