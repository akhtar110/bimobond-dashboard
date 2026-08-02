import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_panel_ui.dart';
import '../bloc/seller_verification_bloc.dart';

int sellerVerificationAppliedFilterCount({String? statusFilter}) {
  return (statusFilter != null && statusFilter.toUpperCase() != 'ALL') ? 1 : 0;
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

/// Glass shell filter panel for seller verification (matching posts design style).
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

  void _setStatus(String? status) {
    setState(() => _status = status);
    context
        .read<SellerVerificationBloc>()
        .add(FilterSellerVerificationsEvent(status));
  }

  void _reset() {
    setState(() => _status = null);
    context
        .read<SellerVerificationBloc>()
        .add(const FilterSellerVerificationsEvent(null));
  }

  List<({String id, String label})> _activeTags(AppLocalizations l10n) {
    if (_status == null || _status!.toUpperCase() == 'ALL') return [];
    return [(id: 'status', label: sellerVerificationStatusLabel(l10n, _status!))];
  }

  void _removeTag(String id) {
    if (id == 'status') {
      _setStatus(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    final statusOptions = <(String?, String)>[
      (null, l10n.t('all')),
      ('PENDING', l10n.tOr('pending', 'Pending')),
      ('APPROVED', l10n.tOr('approved', 'Approved')),
      ('REJECTED', l10n.tOr('rejected', 'Rejected')),
      ('REVOKED', l10n.tOr('revoked', 'Revoked')),
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
              if (widget.showDragHandle)
                const _SellerVerificationFilterDragHandle(),
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

class _SellerVerificationFilterDragHandle extends StatelessWidget {
  const _SellerVerificationFilterDragHandle();

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

String sellerVerificationStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'PENDING' => l10n.tOr('pending', 'Pending'),
    'APPROVED' => l10n.tOr('approved', 'Approved'),
    'REJECTED' => l10n.tOr('rejected', 'Rejected'),
    'REVOKED' => l10n.tOr('revoked', 'Revoked'),
    _ => status,
  };
}
