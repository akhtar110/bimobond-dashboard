import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../bloc/auctions_bloc.dart';

/// Counts popup filters (excludes search, sort, date).
int auctionsAppliedFilterCount({
  String? statusFilter,
  AuctionTypeFilter typeFilter = AuctionTypeFilter.all,
}) {
  var count = 0;
  if (statusFilter != null) count++;
  if (typeFilter != AuctionTypeFilter.all) count++;
  return count;
}

/// Opens the adaptive filter panel for auctions.
Future<void> showAuctionsFilterPopup({
  required BuildContext context,
  required String? statusFilter,
  required AuctionTypeFilter typeFilter,
  required Rect anchorRect,
}) {
  final auctionsBloc = context.read<AuctionsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<AuctionsBloc>.value(
        value: auctionsBloc,
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => wrap(
        AuctionsFilterPopup(
          appliedStatus: statusFilter,
          appliedType: typeFilter,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          showDragHandle: true,
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            AuctionsFilterPopup(
              appliedStatus: statusFilter,
              appliedType: typeFilter,
              width: 420,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 400.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 6;
  final maxPanelHeight = media.height * 0.72;
  if (top + 360 > media.height - padding.bottom) {
    top = (anchorRect.top - 6 - maxPanelHeight).clamp(
      padding.top + 12.0,
      media.height - 360.0,
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.15),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  AuctionsFilterPopup(
                    appliedStatus: statusFilter,
                    appliedType: typeFilter,
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class AuctionsFilterPopup extends StatefulWidget {
  const AuctionsFilterPopup({
    super.key,
    required this.appliedStatus,
    required this.appliedType,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final String? appliedStatus;
  final AuctionTypeFilter appliedType;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<AuctionsFilterPopup> createState() => _AuctionsFilterPopupState();
}

class _AuctionsFilterPopupState extends State<AuctionsFilterPopup> {
  late String? _status;
  late AuctionTypeFilter _type;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
    _type = widget.appliedType;
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _reset() {
    setState(() {
      _status = null;
      _type = AuctionTypeFilter.all;
    });
  }

  void _apply(BuildContext context) {
    final bloc = context.read<AuctionsBloc>();
    if (bloc.activeStatusFilter != _status) {
      bloc.add(FilterAuctionsEvent(_status));
    }
    if (bloc.activeTypeFilter != _type) {
      bloc.add(UpdateAuctionTypeFilterEvent(_type));
    }
    _close(context);
  }

  String _sectionTitle(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  List<GiftsActiveFilterItem> _activeItems(AppLocalizations l10n) {
    final items = <GiftsActiveFilterItem>[];
    if (_status != null) {
      items.add(
        GiftsActiveFilterItem(
          id: 'status',
          label: auctionStatusLabel(l10n, _status!),
          onRemove: () => setState(() => _status = null),
        ),
      );
    }
    if (_type != AuctionTypeFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'type',
          label: auctionTypeLabel(l10n, _type),
          onRemove: () => setState(() => _type = AuctionTypeFilter.all),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    final statusOptions = <(String?, String)>[
      (null, l10n.t('all')),
      ('ACTIVE', l10n.t('active')),
      ('COMPLETED', l10n.t('completed')),
      ('SETTLED', l10n.tOr('settled', 'Settled')),
      ('DISPUTED', l10n.tOr('disputed', 'Disputed')),
      ('CANCELLED', l10n.t('cancelled')),
      ('BANNED', l10n.tOr('banned', 'Banned')),
    ];

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.width ?? 400,
        height: widget.maxHeight,
        child: Column(
          children: [
            if (widget.showDragHandle) const _AuctionsFilterDragHandle(),
            _AuctionsFilterHeader(onClose: () => _close(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  GiftsActiveFilters(items: _activeItems(l10n)),
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.t('status'), context),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final (status, label) in statusOptions)
                          GiftsFilterChoiceChip(
                            label: label,
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: _sectionTitle(
                      l10n.tOr('auctionType', 'Auction type'),
                      context,
                    ),
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: l10n.t('all'),
                          selected: _type == AuctionTypeFilter.all,
                          onTap: () =>
                              setState(() => _type = AuctionTypeFilter.all),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('auctionTypeFixed', 'Fixed price'),
                          selected: _type == AuctionTypeFilter.fixed,
                          onTap: () =>
                              setState(() => _type = AuctionTypeFilter.fixed),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('auctionTypeTimed', 'Timed'),
                          selected: _type == AuctionTypeFilter.timed,
                          onTap: () =>
                              setState(() => _type = AuctionTypeFilter.timed),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.t('live'),
                          selected: _type == AuctionTypeFilter.live,
                          onTap: () =>
                              setState(() => _type = AuctionTypeFilter.live),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: () => _close(context),
              onApply: () => _apply(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuctionsFilterDragHandle extends StatelessWidget {
  const _AuctionsFilterDragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _AuctionsFilterHeader extends StatelessWidget {
  const _AuctionsFilterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.tOr('filters', 'Filters'),
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.t('close'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

String auctionStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'ACTIVE' => l10n.t('active'),
    'COMPLETED' => l10n.t('completed'),
    'SETTLED' => l10n.tOr('settled', 'Settled'),
    'DISPUTED' => l10n.tOr('disputed', 'Disputed'),
    'CANCELLED' => l10n.t('cancelled'),
    'BANNED' => l10n.tOr('banned', 'Banned'),
    _ => status,
  };
}

String auctionTypeLabel(AppLocalizations l10n, AuctionTypeFilter type) {
  return switch (type) {
    AuctionTypeFilter.all => l10n.t('all'),
    AuctionTypeFilter.fixed => l10n.tOr('auctionTypeFixed', 'Fixed price'),
    AuctionTypeFilter.timed => l10n.tOr('auctionTypeTimed', 'Timed'),
    AuctionTypeFilter.live => l10n.t('live'),
  };
}
