import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gifts_bloc.dart';
import '../utils/gifts_responsive.dart';
import 'gifts_filter_button.dart';
import 'gifts_filter_controls.dart';
import 'gifts_filter_models.dart';
import 'gifts_filter_popup.dart';

/// Search stays visible; filters open from a Pinterest-style Filter button.
class GiftsFiltersPanel extends StatelessWidget {
  const GiftsFiltersPanel({
    super.key,
    required this.loaded,
    required this.screenWidth,
    this.onStatusFilterSelected,
  });

  final GiftsLoaded loaded;
  final double screenWidth;

  /// Called when a status filter is applied (e.g. clear group tab).
  final ValueChanged<GiftFilterTab>? onStatusFilterSelected;

  @override
  Widget build(BuildContext context) {
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(screenWidth));
    final bloc = context.read<GiftsBloc>();
    final activeCount = giftsAppliedFilterCount(loaded);
    final controlHeight = metrics.filterControlHeight;

    return SizedBox(
      height: controlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GiftsSearchField(
              searchQuery: loaded.searchQuery,
              height: controlHeight,
              compact: metrics.isMobile,
              onChanged: (q) => bloc.add(SearchGiftsEvent(q)),
            ),
          ),
          SizedBox(width: metrics.isMobile ? 8 : 12),
          _FilterButtonHost(
            activeCount: activeCount,
            height: controlHeight,
            loaded: loaded,
            onStatusFilterSelected: onStatusFilterSelected,
          ),
        ],
      ),
    );
  }
}

class _FilterButtonHost extends StatelessWidget {
  const _FilterButtonHost({
    required this.activeCount,
    required this.height,
    required this.loaded,
    this.onStatusFilterSelected,
  });

  final int activeCount;
  final double height;
  final GiftsLoaded loaded;
  final ValueChanged<GiftFilterTab>? onStatusFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return GiftsFilterButton(
          activeCount: activeCount,
          height: height,
          onPressed: () {
            final box = buttonContext.findRenderObject() as RenderBox?;
            final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
            final size = box?.size ?? Size.zero;
            final anchor = Rect.fromLTWH(
              origin.dx,
              origin.dy,
              size.width,
              size.height,
            );

            showGiftsFilterPopup(
              context: buttonContext,
              loaded: loaded,
              anchorRect: anchor,
              onStatusFilterSelected: onStatusFilterSelected,
            );
          },
        );
      },
    );
  }
}
