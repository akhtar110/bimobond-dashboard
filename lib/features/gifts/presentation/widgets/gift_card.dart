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
    this.onPreview,
    this.onDelete,
    this.compact,
    this.dense,
    this.cacheWidth,
  });

  final GiftEntity gift;
  final VoidCallback? onEdit;
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;

  /// When provided by the grid, skips [LayoutBuilder] (cheaper during scroll).
  final bool? compact;
  final bool? dense;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final knownCompact = compact;
    final knownDense = dense;
    final knownCacheWidth = cacheWidth;
    if (knownCompact != null &&
        knownDense != null &&
        knownCacheWidth != null) {
      return _buildCard(
        context,
        compact: knownCompact,
        dense: knownDense,
        cacheWidth: knownCacheWidth,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return _buildCard(
          context,
          compact: knownCompact ?? width < 170,
          dense: knownDense ?? width < 210,
          cacheWidth: knownCacheWidth ??
              (width * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(80, 480),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool compact,
    required bool dense,
    required int cacheWidth,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyPadding = EdgeInsets.fromLTRB(
      compact ? 8 : 10,
      compact ? 6 : 8,
      compact ? 8 : 10,
      compact ? 6 : 8,
    );
    final gap = compact ? 4.0 : 5.0;
    final borderRadius = compact ? 10.0 : 12.0;
    final actionSize = compact ? 26.0 : 28.0;
    final actionGap = compact ? 4.0 : 5.0;

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
          _GiftThumbnail(
            gift: gift,
            compact: compact,
            cacheWidth: cacheWidth,
          ),
          Padding(
            padding: bodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gift.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    fontSize: compact ? 12 : 12.5,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    _PriceChip(
                      priceCoins: gift.priceCoins,
                      compact: compact,
                    ),
                    if (gift.animationUrl != null &&
                        gift.animationUrl!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.animation_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                    const SizedBox(width: 6),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _PublishedDate(
                          gift: gift,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dense ? 6 : 8),
                _GiftActionBar(
                  gift: gift,
                  actionSize: actionSize,
                  actionGap: actionGap,
                  onPreview: onPreview,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  previewTooltip: l10n.tOr('previewGift', 'Preview gift'),
                  editTooltip: l10n.t('edit'),
                  deleteTooltip: l10n.t('delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftActionBar extends StatelessWidget {
  const _GiftActionBar({
    required this.gift,
    required this.actionSize,
    required this.actionGap,
    required this.previewTooltip,
    required this.editTooltip,
    required this.deleteTooltip,
    this.onPreview,
    this.onEdit,
    this.onDelete,
  });

  final GiftEntity gift;
  final double actionSize;
  final double actionGap;
  final String previewTooltip;
  final String editTooltip;
  final String deleteTooltip;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final actions = <Widget>[
      if (onPreview != null)
        _ActionIconButton(
          size: actionSize,
          icon: Icons.preview_outlined,
          tooltip: previewTooltip,
          onPressed: onPreview,
        ),
      _ActionIconButton(
        size: actionSize,
        icon: Icons.edit_rounded,
        tooltip: editTooltip,
        onPressed: onEdit,
      ),
      _ToggleButton(gift: gift, size: actionSize),
      _ActionIconButton(
        size: actionSize,
        icon: Icons.delete_outline_rounded,
        tooltip: deleteTooltip,
        iconColor: scheme.error,
        onPressed: onDelete,
      ),
    ];

    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: actionGap + 2,
            vertical: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: actionGap),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Published date ───────────────────────────────────────────────────────────

class _PublishedDate extends StatelessWidget {
  const _PublishedDate({required this.gift, this.compact = false});
  final GiftEntity gift;
  final bool compact;

  static final _fmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = gift.publishedAt;
    if (date == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: compact ? 10 : 11,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 3 : 4),
        Expanded(
          child: Text(
            _fmt.format(date.toLocal()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: compact ? 9.5 : 10.5,
              color: scheme.onSurfaceVariant,
              height: 1.1,
              fontWeight: FontWeight.w500,
            ),
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
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '🪙 ${CoinFormat.coinsAmount(priceCoins)}',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _GiftThumbnail extends StatelessWidget {
  const _GiftThumbnail({
    required this.gift,
    this.compact = false,
    this.cacheWidth,
  });
  final GiftEntity gift;
  final bool compact;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      // Wider than tall so grid cards stay shorter.
      aspectRatio: compact ? 1.45 : 1.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            child: gift.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: gift.thumbnailUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: cacheWidth,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) =>
                        _placeholder(scheme, compact),
                    errorWidget: (context, url, error) =>
                        _placeholder(scheme, compact),
                  )
                : _placeholder(scheme, compact),
          ),
          Positioned(
            top: compact ? 5 : 6,
            right: compact ? 5 : 6,
            child: _ActiveBadge(isActive: gift.isActive, compact: true),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, bool compact) => Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          size: compact ? 24 : 28,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
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
    final bg = isActive
        ? scheme.primaryContainer.withValues(alpha: 0.95)
        : scheme.surface.withValues(alpha: 0.92);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.16)),
      ),
      child: Text(
        isActive ? l10n.t('activeLabel') : l10n.t('inactive'),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 8.5 : 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

// ─── Toggle button ────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.gift, this.size = 28});
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
            size: size <= 26 ? 13 : 14,
            color: gift.isActive ? scheme.tertiary : scheme.primary,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            minimumSize: Size(size, size),
            maximumSize: Size(size, size),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Tooltip(
        message: tooltip,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: size <= 26 ? 13 : 14,
            color: iconColor,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            minimumSize: Size(size, size),
            maximumSize: Size(size, size),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
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
        final compact = constraints.maxWidth < 170;
        final borderRadius = compact ? 10.0 : 12.0;
        final bodyPadding = EdgeInsets.fromLTRB(
          compact ? 8 : 10,
          compact ? 6 : 8,
          compact ? 8 : 10,
          compact ? 6 : 8,
        );

        return AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final c = Color.lerp(base, hi, _anim.value)!;
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: compact ? 1.45 : 1.55,
                    child: ColoredBox(color: c),
                  ),
                  Padding(
                    padding: bodyPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sh(c, compact ? 90 : 110, 12),
                        const SizedBox(height: 5),
                        _sh(c, compact ? 70 : 90, 16, r: 6),
                        const SizedBox(height: 7),
                        _sh(c, compact ? 108 : 124, 32, r: 8),
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
