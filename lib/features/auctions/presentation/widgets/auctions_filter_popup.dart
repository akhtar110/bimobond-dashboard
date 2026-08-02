import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_panel_ui.dart';
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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

/// Glass shell filter panel for auctions (matching posts design style).
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

  void _setStatus(String? status) {
    setState(() => _status = status);
    context.read<AuctionsBloc>().add(FilterAuctionsEvent(status));
  }

  void _setType(AuctionTypeFilter type) {
    setState(() => _type = type);
    context.read<AuctionsBloc>().add(UpdateAuctionTypeFilterEvent(type));
  }

  void _reset() {
    setState(() {
      _status = null;
      _type = AuctionTypeFilter.all;
    });
    final bloc = context.read<AuctionsBloc>();
    bloc.add(FilterAuctionsEvent(null));
    bloc.add(UpdateAuctionTypeFilterEvent(AuctionTypeFilter.all));
  }

  List<({String id, String label})> _activeTags(AppLocalizations l10n) {
    final tags = <({String id, String label})>[];
    if (_status != null) {
      tags.add((id: 'status', label: auctionStatusLabel(l10n, _status!)));
    }
    if (_type != AuctionTypeFilter.all) {
      tags.add((id: 'type', label: auctionTypeLabel(l10n, _type)));
    }
    return tags;
  }

  void _removeTag(String id) {
    if (id == 'status') {
      _setStatus(null);
    } else if (id == 'type') {
      _setType(AuctionTypeFilter.all);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

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
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: PostsFilterGlassShell(
        borderRadius: radius,
        child: SizedBox(
          width: widget.width ?? 400,
          height: widget.maxHeight,
          child: Column(
            children: [
              if (widget.showDragHandle) const _AuctionsFilterDragHandle(),
              PostsFilterPanelHeader(onClose: () => _close(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: PostsFilterPanelTokens.spacing,
                  ),
                  children: [
                    PostsFilterActiveTags(
                      labels: _activeTags(l10n),
                      onRemove: _removeTag,
                    ),
                    PostsFilterSection(
                      title: l10n.t('status'),
                      icon: Icons.shield_outlined,
                      showDivider: false,
                      child: PostsFilterChipGrid(
                        children: [
                          for (final (status, label) in statusOptions)
                            PostsFilterChoiceChip(
                              label: label,
                              selected: _status == status,
                              onTap: () => _setStatus(status),
                            ),
                        ],
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('auctionType', 'Auction type'),
                      icon: Icons.category_outlined,
                      child: PostsFilterChipGrid(
                        children: [
                          PostsFilterChoiceChip(
                            label: l10n.t('all'),
                            selected: _type == AuctionTypeFilter.all,
                            onTap: () => _setType(AuctionTypeFilter.all),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.tOr('auctionTypeFixed', 'Fixed price'),
                            selected: _type == AuctionTypeFilter.fixed,
                            onTap: () => _setType(AuctionTypeFilter.fixed),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.tOr('auctionTypeTimed', 'Timed'),
                            selected: _type == AuctionTypeFilter.timed,
                            onTap: () => _setType(AuctionTypeFilter.timed),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.t('live'),
                            selected: _type == AuctionTypeFilter.live,
                            onTap: () => _setType(AuctionTypeFilter.live),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PostsFilterPanelTokens.spacing),
                  ],
                ),
              ),
              PostsFilterPanelFooter(
                onReset: _reset,
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Center(
        child: Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
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
