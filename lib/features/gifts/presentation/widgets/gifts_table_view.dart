import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gift_type.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';
import 'bulk_gift_confirm_dialog.dart';
import 'gift_thumbnail_image.dart';

const double kGiftsTableHeaderHeight = 40;
const double _kRowVPadWide = 10;
const double _kRowVPadMedium = 8;
const double _kRowVPadNarrow = 7;

class GiftsTableHeader extends StatelessWidget {
  const GiftsTableHeader({
    super.key,
    required this.l10n,
    required this.density,
  });

  final AppLocalizations l10n;
  final GiftsTableDensity density;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 0.1,
        );

    return Container(
      height: kGiftsTableHeaderHeight,
      color: scheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(horizontal: _rowHorizontalPadding(density)),
      child: _GiftsTableRowLayout(
        density: density,
        checkbox: BlocSelector<GiftsBloc, GiftsState, (bool, bool)>(
          selector: (state) {
            if (state is! GiftsLoaded) return (false, false);
            return (state.allVisibleSelected, state.someVisibleSelected);
          },
          builder: (context, flags) {
            final allVisibleSelected = flags.$1;
            final someVisibleSelected = flags.$2;
            return Checkbox(
              tristate: true,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: allVisibleSelected
                  ? true
                  : someVisibleSelected
                      ? null
                      : false,
              onChanged: (_) =>
                  context.read<GiftsBloc>().add(SelectAllGiftsEvent()),
            );
          },
        ),
        giftName: Text(
          l10n.t('giftNameLabel').replaceAll(' *', ''),
          style: style,
        ),
        price: Text('coins', style: style),
        status: density == GiftsTableDensity.narrow
            ? const SizedBox.shrink()
            : Text(l10n.t('activeLabel'), style: style),
        published: density == GiftsTableDensity.narrow
            ? const SizedBox.shrink()
            : Text(l10n.t('publishedAt'), style: style),
        actions: Text(l10n.t('actions'), style: style),
      ),
    );
  }
}

class GiftsTableRow extends StatefulWidget {
  const GiftsTableRow({
    super.key,
    required this.gift,
    required this.density,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
    this.onPreview,
    required this.onDelete,
  });

  final GiftEntity gift;
  final GiftsTableDensity density;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback? onPreview;
  final VoidCallback onDelete;

  @override
  State<GiftsTableRow> createState() => _GiftsTableRowState();
}

class _GiftsTableRowState extends State<GiftsTableRow> {
  bool _hovered = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final gift = widget.gift;
    final density = widget.density;
    final fontSize = switch (density) {
      GiftsTableDensity.wide => 12.5,
      GiftsTableDensity.medium => 12.0,
      GiftsTableDensity.narrow => 11.5,
    };
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: fontSize,
          height: 1.25,
        );
    final published = gift.publishedAt;
    final publishedLabel = published != null
        ? density == GiftsTableDensity.medium
            ? DateFormat('MMM d').format(published.toLocal())
            : _dateFmt.format(published.toLocal())
        : '—';

    final bg = widget.isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surface;

    final rowVPad = switch (density) {
      GiftsTableDensity.wide => _kRowVPadWide,
      GiftsTableDensity.medium => _kRowVPadMedium,
      GiftsTableDensity.narrow => _kRowVPadNarrow,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _rowHorizontalPadding(density),
            vertical: rowVPad,
          ),
          child: _GiftsTableRowLayout(
            density: density,
            checkbox: Checkbox(
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            giftName: Row(
              children: [
                _GiftTableThumb(gift: gift, density: density),
                SizedBox(
                  width: density == GiftsTableDensity.narrow ? 6 : 10,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gift.name,
                        maxLines: density == GiftsTableDensity.narrow ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            cellStyle?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (density != GiftsTableDensity.narrow) ...[
                        const SizedBox(height: 2),
                        _GiftTableBadges(gift: gift),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            price: Text(
              '🪙 ${CoinFormat.coinsAmount(gift.priceCoins)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            status: density == GiftsTableDensity.narrow
                ? const SizedBox.shrink()
                : _GiftStatusChip(
                    isActive: gift.isActive,
                    compact: density == GiftsTableDensity.medium,
                  ),
            published: density == GiftsTableDensity.narrow
                ? const SizedBox.shrink()
                : Text(
                    publishedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: density == GiftsTableDensity.medium ? 10.5 : 11,
                    ),
                  ),
            actions: _GiftTableActions(
              gift: gift,
              l10n: l10n,
              scheme: scheme,
              density: density,
              onEdit: widget.onEdit,
              onPreview: widget.onPreview,
              onDelete: widget.onDelete,
            ),
          ),
        ),
      ),
    );
  }
}

class GiftsTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  GiftsTableHeaderDelegate({
    required this.l10n,
    required this.scheme,
    required this.density,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final GiftsTableDensity density;

  @override
  double get minExtent => kGiftsTableHeaderHeight;

  @override
  double get maxExtent => kGiftsTableHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: GiftsTableHeader(
            l10n: l10n,
            density: density,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GiftsTableHeaderDelegate oldDelegate) {
    return oldDelegate.density != density;
  }
}

double _rowHorizontalPadding(GiftsTableDensity density) => switch (density) {
      GiftsTableDensity.wide => 12,
      GiftsTableDensity.medium => 10,
      GiftsTableDensity.narrow => 8,
    };

double _cellHorizontalPadding(GiftsTableDensity density) => switch (density) {
      GiftsTableDensity.wide => 10,
      GiftsTableDensity.medium => 8,
      GiftsTableDensity.narrow => 4,
    };

class _GiftsTableColumnSpec {
  const _GiftsTableColumnSpec({
    required this.actionsWidth,
    required this.nameFlex,
    required this.priceFlex,
    required this.statusFlex,
    required this.publishedFlex,
  });

  final double actionsWidth;
  final int nameFlex;
  final int priceFlex;
  final int statusFlex;
  final int publishedFlex;
}

_GiftsTableColumnSpec _columnSpec(GiftsTableDensity density) =>
    switch (density) {
      GiftsTableDensity.wide => const _GiftsTableColumnSpec(
          actionsWidth: 156,
          nameFlex: 7,
          priceFlex: 2,
          statusFlex: 2,
          publishedFlex: 3,
        ),
      GiftsTableDensity.medium => const _GiftsTableColumnSpec(
          actionsWidth: 148,
          nameFlex: 6,
          priceFlex: 2,
          statusFlex: 2,
          publishedFlex: 2,
        ),
      GiftsTableDensity.narrow => const _GiftsTableColumnSpec(
          actionsWidth: 136,
          nameFlex: 7,
          priceFlex: 3,
          statusFlex: 0,
          publishedFlex: 0,
        ),
    };

const double _kCheckboxWidth = 36;

class _GiftsTableRowLayout extends StatelessWidget {
  const _GiftsTableRowLayout({
    required this.density,
    required this.checkbox,
    required this.giftName,
    required this.price,
    required this.status,
    required this.published,
    required this.actions,
  });

  final GiftsTableDensity density;
  final Widget checkbox;
  final Widget giftName;
  final Widget price;
  final Widget status;
  final Widget published;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final spec = _columnSpec(density);
    final showPublished = density != GiftsTableDensity.narrow;
    final cellPad = _cellHorizontalPadding(density);

    final showStatus =
        density != GiftsTableDensity.narrow && spec.statusFlex > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: density == GiftsTableDensity.narrow ? 32 : _kCheckboxWidth,
          child: checkbox,
        ),
        Expanded(flex: spec.nameFlex, child: _cell(giftName, cellPad)),
        Expanded(flex: spec.priceFlex, child: _cell(price, cellPad)),
        if (showStatus)
          Expanded(flex: spec.statusFlex, child: _cell(status, cellPad)),
        if (showPublished)
          Expanded(
            flex: spec.publishedFlex,
            child: _cell(published, cellPad),
          ),
        SizedBox(
          width: spec.actionsWidth,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: actions,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(Widget child, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _GiftTableThumb extends StatelessWidget {
  const _GiftTableThumb({
    required this.gift,
    required this.density,
  });

  final GiftEntity gift;
  final GiftsTableDensity density;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = switch (density) {
      GiftsTableDensity.wide => 44.0,
      GiftsTableDensity.medium => 38.0,
      GiftsTableDensity.narrow => 32.0,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: gift.thumbnailUrl.isNotEmpty
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: GiftThumbnailImage(
                  networkUrl: gift.thumbnailUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: (size *
                          MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  placeholder: _placeholder(scheme),
                  errorWidget: _placeholder(scheme),
                ),
              )
            : _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Icon(
        Icons.card_giftcard_rounded,
        size: 16,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _GiftTableBadges extends StatelessWidget {
  const _GiftTableBadges({required this.gift});

  final GiftEntity gift;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          gift.type == GiftType.audio
              ? Icons.audiotrack_rounded
              : Icons.image_rounded,
          size: 11,
          color: scheme.onSurfaceVariant,
        ),
        _TableMiniBadge(
          label: gift.size.apiValue,
          fg: scheme.onSurfaceVariant,
          bg: scheme.surfaceContainerHighest,
        ),
        if (gift.tag != null && gift.tag!.trim().isNotEmpty)
          _TableMiniBadge(
            label: gift.tag!,
            fg: scheme.onTertiaryContainer,
            bg: scheme.tertiaryContainer,
          ),
        if (gift.color != null && gift.color!.trim().isNotEmpty)
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _parseTableHexColor(gift.color) ?? scheme.outlineVariant,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant, width: 0.75),
            ),
          ),
      ],
    );
  }
}

class _TableMiniBadge extends StatelessWidget {
  const _TableMiniBadge({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
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

Color? _parseTableHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  final cleaned = hex.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) return null;
  return Color(int.parse('FF$cleaned', radix: 16));
}

class _GiftStatusChip extends StatelessWidget {
  const _GiftStatusChip({
    required this.isActive,
    this.compact = false,
  });
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l10n.t('activeLabel') : l10n.t('inactive'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10 : 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _GiftTableActions extends StatelessWidget {
  const _GiftTableActions({
    required this.gift,
    required this.l10n,
    required this.scheme,
    required this.density,
    required this.onEdit,
    this.onPreview,
    required this.onDelete,
  });

  final GiftEntity gift;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final GiftsTableDensity density;
  final VoidCallback onEdit;
  final VoidCallback? onPreview;
  final VoidCallback onDelete;

  Future<void> _handleToggle(BuildContext context) async {
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
    final buttonSize = switch (density) {
      GiftsTableDensity.wide => 30.0,
      GiftsTableDensity.medium => 28.0,
      GiftsTableDensity.narrow => 26.0,
    };
    final gap = density == GiftsTableDensity.narrow ? 3.0 : 4.0;
    final iconSize = buttonSize <= 26 ? 13.0 : 15.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onPreview != null) ...[
          _TableActionIconButton(
            size: buttonSize,
            iconSize: iconSize,
            tooltip: l10n.tOr('previewGift', 'Preview gift'),
            icon: Icons.preview_outlined,
            onPressed: onPreview,
          ),
          SizedBox(width: gap),
        ],
        _TableActionIconButton(
          size: buttonSize,
          iconSize: iconSize,
          tooltip: l10n.t('edit'),
          icon: Icons.edit_rounded,
          onPressed: onEdit,
        ),
        SizedBox(width: gap),
        Tooltip(
          message: gift.isActive ? l10n.t('deactivate') : l10n.t('activate'),
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton.outlined(
              onPressed: () => _handleToggle(context),
              icon: Icon(
                gift.isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: iconSize,
                color: gift.isActive ? scheme.tertiary : scheme.primary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: buttonSize,
                height: buttonSize,
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
        _TableActionIconButton(
          size: buttonSize,
          iconSize: iconSize,
          tooltip: l10n.t('delete'),
          icon: Icons.delete_outline_rounded,
          iconColor: scheme.error,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _TableActionIconButton extends StatelessWidget {
  const _TableActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.size,
    required this.iconSize,
    this.iconColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(icon, size: iconSize, color: iconColor),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
        ),
      ),
    );
  }
}
