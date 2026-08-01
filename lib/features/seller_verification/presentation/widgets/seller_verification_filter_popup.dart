import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../bloc/seller_verification_bloc.dart';

int sellerVerificationAppliedFilterCount({String? statusFilter}) {
  return statusFilter != null ? 1 : 0;
}

Future<void> showSellerVerificationFilterPopup({
  required BuildContext context,
  required String? statusFilter,
  required Rect anchorRect,
}) {
  final bloc = context.read<SellerVerificationBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<SellerVerificationBloc>.value(
        value: bloc,
        child: child,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => wrap(
        SellerVerificationFilterPopup(
          appliedStatus: statusFilter,
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
            SellerVerificationFilterPopup(
              appliedStatus: statusFilter,
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
                  SellerVerificationFilterPopup(
                    appliedStatus: statusFilter,
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

class SellerVerificationFilterPopup extends StatefulWidget {
  const SellerVerificationFilterPopup({
    super.key,
    required this.appliedStatus,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final String? appliedStatus;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<SellerVerificationFilterPopup> createState() =>
      _SellerVerificationFilterPopupState();
}

class _SellerVerificationFilterPopupState
    extends State<SellerVerificationFilterPopup> {
  late String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _reset() => setState(() => _status = null);

  void _apply(BuildContext context) {
    final bloc = context.read<SellerVerificationBloc>();
    if (bloc.activeStatusFilter != _status) {
      bloc.add(FilterSellerVerificationsEvent(_status));
    }
    _close(context);
  }

  String _sectionTitle(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  List<GiftsActiveFilterItem> _activeItems(AppLocalizations l10n) {
    if (_status == null) return [];
    return [
      GiftsActiveFilterItem(
        id: 'status',
        label: sellerVerificationStatusLabel(l10n, _status!),
        onRemove: () => setState(() => _status = null),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    final statusOptions = <(String?, String)>[
      (null, l10n.t('all')),
      ('PENDING', l10n.tOr('pending', 'Pending')),
      ('APPROVED', l10n.tOr('approved', 'Approved')),
      ('REJECTED', l10n.tOr('rejected', 'Rejected')),
      ('REVOKED', l10n.tOr('revoked', 'Revoked')),
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
            if (widget.showDragHandle)
              Padding(
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
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tOr('filters', 'Filters'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('close'),
                    onPressed: () => _close(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
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

String sellerVerificationStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'PENDING' => l10n.tOr('pending', 'Pending'),
    'APPROVED' => l10n.tOr('approved', 'Approved'),
    'REJECTED' => l10n.tOr('rejected', 'Rejected'),
    'REVOKED' => l10n.tOr('revoked', 'Revoked'),
    _ => status,
  };
}
