import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../auctions/presentation/utils/auctions_responsive.dart';
import '../../../posts/presentation/widgets/posts_filter_button.dart';
import '../bloc/seller_verification_bloc.dart';
import 'seller_verification_filter_bar.dart';
import 'seller_verification_filter_popup.dart';

/// Responsive seller verification toolbar — matches auctions layout.
class SellerVerificationPageToolbar extends StatelessWidget {
  const SellerVerificationPageToolbar({super.key, required this.metrics});

  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final controlHeight = metrics.filterControlHeight;
    final gap = metrics.filterGap + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inline = metrics.toolbarInlineAt(width);

        return _SellerVerificationToolbarRow(
          metrics: metrics,
          controlHeight: controlHeight,
          gap: gap,
          availableWidth: width,
          inline: inline,
        );
      },
    );
  }
}

class _SellerVerificationToolbarRow extends StatelessWidget {
  const _SellerVerificationToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.availableWidth,
    required this.inline,
  });

  final AuctionsLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final double availableWidth;
  final bool inline;

  Widget _searchField() {
    return SellerVerificationFilterBar(
      metrics: metrics,
      height: controlHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SellerVerificationBloc, SellerVerificationState,
        String?>(
      selector: (state) => switch (state) {
        SellerVerificationLoaded(:final statusFilter) => statusFilter,
        _ => context.read<SellerVerificationBloc>().activeStatusFilter,
      },
      builder: (context, statusFilter) {
        final activeCount =
            sellerVerificationAppliedFilterCount(statusFilter: statusFilter);

        final filterButton = Builder(
          builder: (buttonContext) {
            return PostsFilterButton(
              activeCount: activeCount,
              height: controlHeight,
              iconOnly: true,
              onPressed: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                final size = box?.size ?? Size.zero;
                showSellerVerificationFilterPopup(
                  context: context,
                  statusFilter: statusFilter,
                  anchorRect: Rect.fromLTWH(
                    origin.dx,
                    origin.dy,
                    size.width,
                    size.height,
                  ),
                );
              },
            );
          },
        );

        if (inline) {
          final actionsWidth = controlHeight + gap;
          final searchWidth = (availableWidth - actionsWidth)
              .clamp(120.0, metrics.inlineSearchWidthFor(availableWidth));
          return SizedBox(
            height: controlHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: searchWidth,
                      minWidth: 120,
                      minHeight: controlHeight,
                      maxHeight: controlHeight,
                    ),
                    child: _searchField(),
                  ),
                ),
                SizedBox(width: gap),
                filterButton,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: controlHeight, child: _searchField()),
            SizedBox(height: gap),
            SizedBox(
              height: controlHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: filterButton,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dismissible chips for active seller verification filters.
class SellerVerificationActiveFilterChips extends StatelessWidget {
  const SellerVerificationActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SellerVerificationBloc, SellerVerificationState>(
      buildWhen: (prev, next) {
        if (prev is SellerVerificationLoaded && next is SellerVerificationLoaded) {
          return prev.statusFilter != next.statusFilter;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! SellerVerificationLoaded ||
            state.statusFilter == null ||
            state.statusFilter!.toUpperCase() == 'ALL') {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ActiveFilterChip(
                label: sellerVerificationStatusLabel(
                  l10n,
                  state.statusFilter!,
                ),
                onRemove: () => context.read<SellerVerificationBloc>().add(
                      const FilterSellerVerificationsEvent(null),
                    ),
              ),
              TextButton(
                onPressed: () {
                  context.read<SellerVerificationBloc>().add(
                        const FilterSellerVerificationsEvent(null),
                      );
                  context.read<SellerVerificationBloc>().add(
                        const UpdateSellerVerificationSearchEvent(''),
                      );
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.t('clearAllFilters'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
