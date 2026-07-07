import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/gift_entity.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';

const double kGiftsTableHeaderHeight = 40;
const double _kRowVPad = 8;

class GiftsTableHeader extends StatelessWidget {
  const GiftsTableHeader({
    super.key,
    required this.l10n,
    required this.density,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
  });

  final AppLocalizations l10n;
  final GiftsTableDensity density;
  final bool allVisibleSelected;
  final bool someVisibleSelected;

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
        checkbox: Checkbox(
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
        ),
        giftName: Text(
          l10n.t('giftNameLabel').replaceAll(' *', ''),
          style: style,
        ),
        price: Text(l10n.t('giftPriceLabel').replaceAll(' *', ''), style: style),
        status: Text(l10n.t('activeLabel'), style: style),
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
    required this.onDelete,
  });

  final GiftEntity gift;
  final GiftsTableDensity density;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onEdit;
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
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
        );
    final published = gift.publishedAt;
    final publishedLabel = published != null
        ? widget.density == GiftsTableDensity.medium
            ? DateFormat('MMM d, yyyy').format(published.toLocal())
            : _dateFmt.format(published.toLocal())
        : '—';

    final bg = widget.isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _rowHorizontalPadding(widget.density),
            vertical: _kRowVPad,
          ),
          child: _GiftsTableRowLayout(
            density: widget.density,
            checkbox: Checkbox(
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            giftName: Row(
              children: [
                _GiftTableThumb(gift: gift, density: widget.density),
                SizedBox(
                  width: widget.density == GiftsTableDensity.narrow ? 8 : 10,
                ),
                Expanded(
                  child: Text(
                    gift.name,
                    maxLines: widget.density == GiftsTableDensity.narrow ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            price: Text(
              CoinFormat.coins(gift.priceCoins),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            status: _GiftStatusChip(isActive: gift.isActive),
            published: widget.density == GiftsTableDensity.narrow
                ? const SizedBox.shrink()
                : Text(
                    publishedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cellStyle?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
            actions: _GiftTableActions(
              gift: gift,
              l10n: l10n,
              scheme: scheme,
              compact: widget.density == GiftsTableDensity.narrow,
              onEdit: widget.onEdit,
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
    required this.allVisibleSelected,
    required this.someVisibleSelected,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final GiftsTableDensity density;
  final bool allVisibleSelected;
  final bool someVisibleSelected;

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
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
            left: BorderSide(color: scheme.outlineVariant),
            right: BorderSide(color: scheme.outlineVariant),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: GiftsTableHeader(
            l10n: l10n,
            density: density,
            allVisibleSelected: allVisibleSelected,
            someVisibleSelected: someVisibleSelected,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GiftsTableHeaderDelegate oldDelegate) {
    return oldDelegate.density != density ||
        oldDelegate.allVisibleSelected != allVisibleSelected ||
        oldDelegate.someVisibleSelected != someVisibleSelected;
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
          actionsWidth: 132,
          nameFlex: 7,
          priceFlex: 2,
          statusFlex: 2,
          publishedFlex: 3,
        ),
      GiftsTableDensity.medium => const _GiftsTableColumnSpec(
          actionsWidth: 118,
          nameFlex: 6,
          priceFlex: 2,
          statusFlex: 2,
          publishedFlex: 3,
        ),
      GiftsTableDensity.narrow => const _GiftsTableColumnSpec(
          actionsWidth: 96,
          nameFlex: 6,
          priceFlex: 2,
          statusFlex: 2,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: _kCheckboxWidth, child: checkbox),
        Expanded(flex: spec.nameFlex, child: _cell(giftName, cellPad)),
        Expanded(flex: spec.priceFlex, child: _cell(price, cellPad)),
        Expanded(flex: spec.statusFlex, child: _cell(status, cellPad)),
        if (showPublished)
          Expanded(
            flex: spec.publishedFlex,
            child: _cell(published, cellPad),
          ),
        SizedBox(width: spec.actionsWidth, child: _cell(actions, cellPad)),
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
      GiftsTableDensity.wide => 42.0,
      GiftsTableDensity.medium => 40.0,
      GiftsTableDensity.narrow => 34.0,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: gift.thumbnailUrl.isNotEmpty
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: CachedNetworkImage(
                  imageUrl: gift.thumbnailUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => _placeholder(scheme),
                  errorWidget: (_, __, ___) => _placeholder(scheme),
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

class _GiftStatusChip extends StatelessWidget {
  const _GiftStatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l10n.t('activeLabel') : l10n.t('inactive'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
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
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });

  final GiftEntity gift;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final toggleBtn = Tooltip(
      message: gift.isActive ? l10n.t('deactivate') : l10n.t('activate'),
      child: IconButton(
        onPressed: () => context.read<GiftsBloc>().add(
              ToggleGiftActiveEvent(gift.id, !gift.isActive),
            ),
        icon: Icon(
          gift.isActive
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          size: 16,
          color: gift.isActive ? scheme.tertiary : scheme.primary,
        ),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      ),
    );

    final deleteBtn = IconButton(
      onPressed: onDelete,
      icon: Icon(Icons.delete_outline_rounded, size: 16, color: scheme.error),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          toggleBtn,
          deleteBtn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded, size: 14),
          label: Text(l10n.t('edit'), style: const TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        toggleBtn,
        deleteBtn,
      ],
    );
  }
}
