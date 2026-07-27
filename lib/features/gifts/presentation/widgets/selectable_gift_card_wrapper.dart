import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift_entity.dart';
import '../bloc/gifts_bloc.dart';
import 'gift_card.dart';

/// Wraps [GiftCard] with a selection checkbox without modifying the card design.
///
/// Selection state is read via [BlocSelector] so only this card's overlay
/// rebuilds when its checkbox changes — the grid body stays stable while scrolling.
class SelectableGiftCard extends StatelessWidget {
  const SelectableGiftCard({
    super.key,
    required this.gift,
    required this.onSelectionChanged,
    required this.onEdit,
    this.onPreview,
    required this.onDelete,
    this.compact,
    this.dense,
    this.cacheWidth,
  });

  final GiftEntity gift;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback? onPreview;
  final VoidCallback onDelete;

  /// When set (from the grid), skips per-card [LayoutBuilder].
  final bool? compact;
  final bool? dense;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GiftCard(
          key: ValueKey('gift_card_${gift.id}'),
          gift: gift,
          compact: compact,
          dense: dense,
          cacheWidth: cacheWidth,
          onEdit: onEdit,
          onPreview: onPreview,
          onDelete: onDelete,
        ),
        PositionedDirectional(
          top: 8,
          start: 8,
          child: BlocSelector<GiftsBloc, GiftsState, bool>(
            selector: (state) =>
                state is GiftsLoaded &&
                state.selectedGiftIds.contains(gift.id),
            builder: (context, isSelected) {
              return _SelectionCheckboxOverlay(
                isSelected: isSelected,
                onChanged: onSelectionChanged,
                accentColor: scheme.primary,
              );
            },
          ),
        ),
        BlocSelector<GiftsBloc, GiftsState, bool>(
          selector: (state) =>
              state is GiftsLoaded && state.selectedGiftIds.contains(gift.id),
          builder: (context, isSelected) {
            if (!isSelected) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SelectionCheckboxOverlay extends StatefulWidget {
  const _SelectionCheckboxOverlay({
    required this.isSelected,
    required this.onChanged,
    required this.accentColor,
  });

  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final Color accentColor;

  @override
  State<_SelectionCheckboxOverlay> createState() =>
      _SelectionCheckboxOverlayState();
}

class _SelectionCheckboxOverlayState extends State<_SelectionCheckboxOverlay> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surface.withValues(alpha: _hovered ? 0.98 : 0.92);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        elevation: _hovered ? 3 : 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Checkbox(
          value: widget.isSelected,
          onChanged: widget.onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: widget.accentColor,
          side: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}

void toggleGiftSelection(BuildContext context, String giftId, bool selected) {
  final bloc = context.read<GiftsBloc>();
  if (selected) {
    bloc.add(SelectGiftEvent(giftId));
  } else {
    bloc.add(DeselectGiftEvent(giftId));
  }
}
