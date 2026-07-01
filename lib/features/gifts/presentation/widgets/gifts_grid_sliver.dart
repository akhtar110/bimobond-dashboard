import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/gifts_view_type.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_responsive.dart';
import 'edit_gift_dialog.dart';
import 'gifts_page_sliver_states.dart';
import 'gifts_table_view.dart';
import 'selectable_gift_card_wrapper.dart';

class GiftsContentSliver extends StatelessWidget {
  const GiftsContentSliver();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GiftsBloc, GiftsState>(
      buildWhen: (prev, curr) {
        if (prev is! GiftsLoaded || curr is! GiftsLoaded) {
          return prev.runtimeType != curr.runtimeType;
        }
        return prev.gifts != curr.gifts ||
            prev.selectedTab != curr.selectedTab ||
            prev.selectedSort != curr.selectedSort ||
            prev.viewType != curr.viewType ||
            prev.searchQuery != curr.searchQuery ||
            prev.fromDate != curr.fromDate ||
            prev.toDate != curr.toDate ||
            prev.minPriceFilter != curr.minPriceFilter ||
            prev.maxPriceFilter != curr.maxPriceFilter ||
            prev.selectedGiftIds != curr.selectedGiftIds ||
            prev.isPerformingBulkAction != curr.isPerformingBulkAction;
      },
      builder: (context, state) {
        if (state is! GiftsLoaded) return const SliverToBoxAdapter();

        final contentKey =
            'gifts-${state.viewType.name}-${state.selectedTab.name}-'
            '${state.searchQuery}-'
            '${state.fromDate?.millisecondsSinceEpoch}-'
            '${state.toDate?.millisecondsSinceEpoch}-'
            '${state.minPriceFilter}-'
            '${state.maxPriceFilter}-'
            '${state.selectedSort.name}-'
            '${state.displayed.length}';

        return state.viewType == GiftsViewType.grid
            ? GiftsSliverGrid(
                key: ValueKey('grid-$contentKey'),
                loaded: state,
              )
            : GiftsSliverList(
                key: ValueKey('list-$contentKey'),
                loaded: state,
              );
      },
    );
  }
}

class GiftsGridSliver extends GiftsContentSliver {
  const GiftsGridSliver();
}

class GiftsSliverGrid extends StatelessWidget {
  const GiftsSliverGrid({super.key, required this.loaded});
  final GiftsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final gifts = loaded.displayed;

    if (gifts.isEmpty) {
      return const GiftsSliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = giftsGridColumnCount(constraints.crossAxisExtent);
        final rowCount = (gifts.length / columns).ceil();
        final metrics = GiftsLayoutMetrics(
          getGiftsDeviceType(constraints.crossAxisExtent),
        );
        final gap = metrics.gridGap;
        final pad = metrics.pageHorizontalPadding;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, metrics.gridTopPadding, pad, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final start = rowIndex * columns;
                final end = (start + columns).clamp(0, gifts.length);
                final row = gifts.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? gap : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Expanded(
                          child: i < row.length
                              ? SelectableGiftCard(
                                  gift: row[i],
                                  isSelected: loaded.selectedGiftIds
                                      .contains(row[i].id),
                                  onSelectionChanged: (selected) =>
                                      toggleGiftSelection(
                                    context,
                                    row[i].id,
                                    selected ?? false,
                                  ),
                                  onEdit: () =>
                                      showEditGiftDialog(context, row[i]),
                                  onDelete: () => confirmDeleteGift(
                                    context,
                                    row[i].id,
                                    row[i].name,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }
}

class GiftsSliverList extends StatelessWidget {
  const GiftsSliverList({super.key, required this.loaded});
  final GiftsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final gifts = loaded.displayed;

    if (gifts.isEmpty) {
      return const GiftsSliverEmptyState(
        icon: Icons.card_giftcard_rounded,
        messageKey: 'noGiftsFound',
      );
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final pad = giftsPageHorizontalPadding(constraints.crossAxisExtent);
        final density =
            giftsTableDensityForWidth(constraints.crossAxisExtent);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: GiftsTableHeaderDelegate(
                  l10n: l10n,
                  scheme: scheme,
                  density: density,
                  allVisibleSelected: loaded.allVisibleSelected,
                  someVisibleSelected: loaded.someVisibleSelected,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final gift = gifts[index];
                    final isLast = index == gifts.length - 1;

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        border: Border(
                          left: BorderSide(color: scheme.outlineVariant),
                          right: BorderSide(color: scheme.outlineVariant),
                          bottom: BorderSide(
                            color: scheme.outlineVariant.withValues(
                              alpha: isLast ? 1 : 0.45,
                            ),
                          ),
                        ),
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              )
                            : null,
                      ),
                      child: GiftsTableRow(
                        gift: gift,
                        density: density,
                        isSelected:
                            loaded.selectedGiftIds.contains(gift.id),
                        onSelectionChanged: (selected) => toggleGiftSelection(
                          context,
                          gift.id,
                          selected ?? false,
                        ),
                        onEdit: () => showEditGiftDialog(context, gift),
                        onDelete: () =>
                            confirmDeleteGift(context, gift.id, gift.name),
                      ),
                    );
                  },
                  childCount: gifts.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void confirmDeleteGift(BuildContext context, String id, String name) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.t('deleteGiftTitle')),
      content: Text(context.tr('deleteGiftMessage', {'name': name})),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<GiftsBloc>().add(DeleteGiftEvent(id));
          },
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l10n.t('delete')),
        ),
      ],
    ),
  );
}
