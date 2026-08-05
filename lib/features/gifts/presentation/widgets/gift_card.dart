import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gift_type.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_schedule_label.dart';
import 'bulk_gift_confirm_dialog.dart';
import 'gift_thumbnail_image.dart';

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
                        gift.animationUrl!.isNotEmpty &&
                        gift.type != GiftType.audio) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.animation_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                    if (gift.type == GiftType.audio) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.audiotrack_rounded,
                        size: 13,
                        color: scheme.primary,
                      ),
                    ],
                    const SizedBox(width: 6),
                    Expanded(
                      child: _PublishedDate(
                        gift: gift,
                        compact: true,
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

// ─── Meta badges (used on thumbnail overlays) ───────────────────────────────

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: fg,
        ),
      ),
    );
  }
}

/// Parses a `#RRGGBB` (or `RRGGBB`) hex string into a [Color].
Color? _parseGiftHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  final cleaned = hex.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) return null;
  return Color(int.parse('FF$cleaned', radix: 16));
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

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = giftScheduleLabelFor(l10n, gift);
    final color = label.status == GiftScheduleStatus.publishesTomorrow ||
            label.status == GiftScheduleStatus.scheduled
        ? scheme.tertiary
        : scheme.onSurfaceVariant;
    final icon = switch (label.status) {
      GiftScheduleStatus.availableNow => Icons.bolt_rounded,
      GiftScheduleStatus.publishesTomorrow ||
      GiftScheduleStatus.scheduled =>
        Icons.schedule_rounded,
      GiftScheduleStatus.published => Icons.calendar_today_outlined,
    };

    // Card shows date only (no "Published on" prefix).
    final text = label.status == GiftScheduleStatus.published &&
            gift.publishedAt != null
        ? _dateFmt.format(gift.publishedAt!.toLocal())
        : label.text;

    return Row(
      children: [
        Icon(icon, size: compact ? 10 : 11, color: color),
        SizedBox(width: compact ? 3 : 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: compact ? 9.5 : 10.5,
              color: color,
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
    final accent = _parseGiftHexColor(gift.color);
    final isAudio = gift.type == GiftType.audio;
    return AspectRatio(
      // Wider than tall so grid cards stay shorter.
      aspectRatio: compact ? 1.45 : 1.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: isAudio && accent != null
                ? accent
                : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            child: isAudio && accent != null
                ? Center(
                    child: Icon(
                      Icons.audiotrack_rounded,
                      size: compact ? 28 : 32,
                      color: accent.computeLuminance() > 0.55
                          ? Colors.black87
                          : Colors.white,
                    ),
                  )
                : (gift.thumbnailUrl.isNotEmpty
                    ? GiftThumbnailImage(
                        key: ValueKey('gift-card-img-${gift.id}-${gift.thumbnailUrl}'),
                        networkUrl: gift.thumbnailUrl,
                        fit: BoxFit.contain,
                        memCacheWidth: cacheWidth,
                        placeholder: _placeholder(scheme, compact),
                        errorWidget: _placeholder(scheme, compact),
                      )
                    : _placeholder(scheme, compact)),
          ),
          if (accent != null && !isAudio)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent),
            ),
          Positioned(
            top: compact ? 5 : 6,
            left: compact ? 5 : 6,
            child: _TypeSizeBadge(gift: gift, compact: compact),
          ),
          Positioned(
            top: compact ? 5 : 6,
            right: compact ? 5 : 6,
            child: _ActiveBadge(isActive: gift.isActive, compact: true),
          ),
          if (gift.tag != null && gift.tag!.trim().isNotEmpty)
            Positioned(
              bottom: compact ? 5 : 6,
              left: compact ? 5 : 6,
              child: _MiniBadge(
                label: gift.tag!,
                fg: scheme.onTertiaryContainer,
                bg: scheme.tertiaryContainer,
              ),
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

class _TypeSizeBadge extends StatelessWidget {
  const _TypeSizeBadge({required this.gift, required this.compact});

  final GiftEntity gift;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAudio = gift.type == GiftType.audio;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 2.5,
      ),
      decoration: BoxDecoration(
        color: (isAudio ? scheme.secondaryContainer : scheme.primaryContainer)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAudio ? Icons.audiotrack_rounded : Icons.image_rounded,
            size: compact ? 10 : 11,
            color: isAudio
                ? scheme.onSecondaryContainer
                : scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 3),
          Text(
            gift.size.apiValue,
            style: TextStyle(
              fontSize: compact ? 8 : 8.5,
              fontWeight: FontWeight.w800,
              color: isAudio
                  ? scheme.onSecondaryContainer
                  : scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
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

  Future<void> _handleToggle(BuildContext context) async {
    final l10n = context.l10n;
    final isAr = l10n.locale.languageCode == 'ar';
    final willActivate = !gift.isActive;

    final title = willActivate
        ? l10n.tOr('activateGift', isAr ? 'تفعيل الهدية' : 'Activate Gift')
        : l10n.tOr('deactivateGift', isAr ? 'إلغاء تفعيل الهدية' : 'Deactivate Gift');

    final message = willActivate
        ? l10n.tOr('confirmActivateGiftMessage', isAr ? 'هل أنت متأكد من تفعيل هذه الهدية؟' : 'Are you sure you want to activate this gift?')
        : l10n.tOr('confirmDeactivateGiftMessage', isAr ? 'هل أنت متأكد من إلغاء تفعيل هذه الهدية؟' : 'Are you sure you want to deactivate this gift?');

    final confirmed = await confirmGiftAdminAction(
      context,
      title: title,
      message: message,
      destructive: !willActivate,
    );

    if (confirmed && context.mounted) {
      context
          .read<GiftsBloc>()
          .add(ToggleGiftActiveEvent(gift.id, willActivate));
    }
  }

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
          onPressed: () => _handleToggle(context),
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
