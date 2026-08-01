import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/auctions_bloc.dart';

/// Compact sort control for the auctions toolbar.
class AuctionsSortDropdown extends StatelessWidget {
  const AuctionsSortDropdown({super.key, required this.height});

  final double height;

  static const defaultSort = AuctionSortOption.newestFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<AuctionsBloc, AuctionsState, AuctionSortOption>(
      selector: (state) => switch (state) {
        AuctionsLoaded(:final sortOption) => sortOption,
        _ => context.read<AuctionsBloc>().activeSortOption,
      },
      builder: (context, sort) {
        final isActive = sort != defaultSort;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('sortBy'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<AuctionSortOption>(
              tooltip: l10n.t('sortBy'),
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                final bloc = context.read<AuctionsBloc>();
                if (bloc.activeSortOption == value) return;
                bloc.add(UpdateAuctionSortEvent(value));
              },
              itemBuilder: (context) => [
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.newestFirst,
                  label: l10n.tOr('auctionSortMostRecent', 'Most recent'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.oldestFirst,
                  label: l10n.tOr('auctionSortOldest', 'Oldest auctions'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.highestBid,
                  label: l10n.t('sortHighestBid'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.lowestBid,
                  label: l10n.t('sortLowestBid'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.targetPrice,
                  label: l10n.tOr('auctionSortTargetPrice', 'Target price'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: AuctionSortOption.endingSoon,
                  label: l10n.t('sortEndingSoon'),
                ),
              ],
              child: Container(
                height: height,
                width: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.swap_vert_rounded, size: 18, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<AuctionSortOption> _sortItem(
    BuildContext context, {
    required AuctionSortOption sort,
    required AuctionSortOption value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = sort == value;
    return PopupMenuItem<AuctionSortOption>(
      value: value,
      height: 36,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? scheme.primary : null,
        ),
      ),
    );
  }
}

String auctionSortLabel(AppLocalizations l10n, AuctionSortOption sort) {
  return switch (sort) {
    AuctionSortOption.newestFirst =>
      l10n.tOr('auctionSortMostRecent', 'Most recent'),
    AuctionSortOption.oldestFirst =>
      l10n.tOr('auctionSortOldest', 'Oldest auctions'),
    AuctionSortOption.highestBid => l10n.t('sortHighestBid'),
    AuctionSortOption.lowestBid => l10n.t('sortLowestBid'),
    AuctionSortOption.targetPrice =>
      l10n.tOr('auctionSortTargetPrice', 'Target price'),
    AuctionSortOption.endingSoon => l10n.t('sortEndingSoon'),
  };
}
