import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';

int usersAppliedFilterCount({
  UsersUiFilter filter = UsersUiFilter.all,
  String locationQuery = '',
}) {
  var count = 0;
  if (filter != UsersUiFilter.all) count++;
  if (locationQuery.trim().isNotEmpty) count++;
  return count;
}

Future<void> showUsersFilterPopup({
  required BuildContext context,
  required UsersUiFilter statusFilter,
  required String locationQuery,
  required Rect anchorRect,
}) {
  final bloc = context.read<UsersBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<UsersBloc>.value(
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
        UsersFilterPopup(
          appliedStatus: statusFilter,
          appliedLocation: locationQuery,
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
            UsersFilterPopup(
              appliedStatus: statusFilter,
              appliedLocation: locationQuery,
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
                  UsersFilterPopup(
                    appliedStatus: statusFilter,
                    appliedLocation: locationQuery,
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

class UsersFilterPopup extends StatefulWidget {
  const UsersFilterPopup({
    super.key,
    required this.appliedStatus,
    required this.appliedLocation,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final UsersUiFilter appliedStatus;
  final String appliedLocation;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<UsersFilterPopup> createState() => _UsersFilterPopupState();
}

class _UsersFilterPopupState extends State<UsersFilterPopup> {
  late UsersUiFilter _status;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
    _locationController = TextEditingController(text: widget.appliedLocation);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _reset() {
    setState(() {
      _status = UsersUiFilter.all;
      _locationController.clear();
    });
  }

  void _apply(BuildContext context) {
    final bloc = context.read<UsersBloc>();
    final location = _locationController.text.trim();

    if (bloc.activeFilter != _status) {
      bloc.add(FilterUsersEvent(_status));
    }
    if (bloc.activeLocationQuery != location) {
      bloc.add(
        ApplyUsersListFiltersEvent(
          search: bloc.activeQuery,
          location: location,
        ),
      );
    }

    _close(context);
  }

  String _sectionTitle(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  List<GiftsActiveFilterItem> _activeItems(AppLocalizations l10n) {
    final items = <GiftsActiveFilterItem>[];
    if (_status != UsersUiFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'status',
          label: usersStatusLabel(l10n, _status),
          onRemove: () => setState(() => _status = UsersUiFilter.all),
        ),
      );
    }
    if (_locationController.text.trim().isNotEmpty) {
      items.add(
        GiftsActiveFilterItem(
          id: 'location',
          label: _locationController.text.trim(),
          onRemove: () => _locationController.clear(),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

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
                        for (final status in UsersUiFilter.values)
                          GiftsFilterChoiceChip(
                            label: usersStatusLabel(l10n, status),
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: _sectionTitle(l10n.t('location'), context),
                    child: TextField(
                      controller: _locationController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.t('filterUsersByPlace'),
                        prefixIcon: const Icon(Icons.place_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
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

String usersStatusLabel(AppLocalizations l10n, UsersUiFilter filter) {
  return switch (filter) {
    UsersUiFilter.all => l10n.t('all'),
    UsersUiFilter.verified => l10n.t('verified'),
    UsersUiFilter.banned => l10n.t('banned'),
  };
}
