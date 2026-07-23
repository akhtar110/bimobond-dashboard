import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_button.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_header.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../utils/fe_display_filters.dart';
import 'fe_catalog_item_preview.dart' show feEffectRenderTypeLabel;

/// Search + Filter button row (Gifts-style) for Filters / Effects tabs.
class FeFiltersPanel extends StatelessWidget {
  const FeFiltersPanel({
    super.key,
    required this.query,
    required this.showRenderType,
    this.showStatusFilter = true,
  });

  final FiltersEffectsListQuery query;
  final bool showRenderType;
  final bool showStatusFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showFilterButton = showStatusFilter || showRenderType;
    final activeCount = showFilterButton
        ? feAppliedFilterCount(
            query: query,
            includeRenderType: showRenderType,
          )
        : 0;
    const height = 48.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _FeSearchField(
              hint: l10n.tOr('feSearchHint', 'Search filters or effects…'),
              initialValue: query.search,
              height: height,
              onChanged: (q) => context.read<FiltersEffectsBloc>().add(
                FiltersEffectsSearchChanged(q),
              ),
            ),
          ),
          if (showFilterButton) ...[
            const SizedBox(width: 12),
            Builder(
              builder: (buttonContext) {
                return GiftsFilterButton(
                  activeCount: activeCount,
                  height: height,
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    final origin =
                        box?.localToGlobal(Offset.zero) ?? Offset.zero;
                    final size = box?.size ?? Size.zero;
                    showFeFilterPopup(
                      context: buttonContext,
                      query: query,
                      showRenderType: showRenderType,
                      showStatusFilter: showStatusFilter,
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
            ),
          ],
        ],
      ),
    );
  }
}

class _FeSearchField extends StatefulWidget {
  const _FeSearchField({
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.height = 48,
  });

  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double height;

  @override
  State<_FeSearchField> createState() => _FeSearchFieldState();
}

class _FeSearchFieldState extends State<_FeSearchField> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _FeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _ctrl.text &&
        widget.initialValue != oldWidget.initialValue) {
      _ctrl.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      widget.onChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

Future<void> showFeFilterPopup({
  required BuildContext context,
  required FiltersEffectsListQuery query,
  required bool showRenderType,
  required Rect anchorRect,
  bool showStatusFilter = true,
}) {
  final bloc = context.read<FiltersEffectsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<FiltersEffectsBloc>.value(
    value: bloc,
    child: child,
  );

  Widget popup({
    double? width,
    required double maxHeight,
    BorderRadius? borderRadius,
  }) =>
      _FeFilterPopup(
        query: query,
        bloc: bloc,
        showRenderType: showRenderType,
        showStatusFilter: showStatusFilter,
        width: width,
        maxHeight: maxHeight,
        borderRadius: borderRadius,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: wrap(
          popup(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            popup(
              width: 380,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 380.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 8;
  final maxPanelHeight = media.height * 0.68;
  if (top + 320 > media.height - padding.bottom) {
    top = (anchorRect.top - 8 - maxPanelHeight)
        .clamp(padding.top + 12.0, media.height - 320.0);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: wrap(
                popup(width: panelWidth, maxHeight: maxPanelHeight),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _FeFilterPopup extends StatefulWidget {
  const _FeFilterPopup({
    required this.query,
    required this.bloc,
    required this.showRenderType,
    this.showStatusFilter = true,
    this.width,
    this.maxHeight = 480,
    this.borderRadius,
  });

  final FiltersEffectsListQuery query;
  final FiltersEffectsBloc bloc;
  final bool showRenderType;
  final bool showStatusFilter;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;

  @override
  State<_FeFilterPopup> createState() => _FeFilterPopupState();
}

class _FeFilterPopupState extends State<_FeFilterPopup> {
  late FiltersEffectsStatusFilter _status;
  late String? _renderType;

  @override
  void initState() {
    super.initState();
    _status = widget.query.status;
    _renderType = widget.query.renderType;
  }

  void _reset() {
    setState(() {
      _status = FiltersEffectsStatusFilter.all;
      _renderType = null;
    });
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _apply() {
    widget.bloc.add(
      FiltersEffectsFilterChanged(
        status: _status,
        renderType: _renderType,
        clearRenderType: _renderType == null,
      ),
    );
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    final isEffects = widget.showRenderType;

    final activeItems = <GiftsActiveFilterItem>[
      if (widget.showStatusFilter &&
          _status != FiltersEffectsStatusFilter.all)
        GiftsActiveFilterItem(
          id: 'status',
          label: switch (_status) {
            FiltersEffectsStatusFilter.active =>
              l10n.tOr('feActive', 'Active'),
            FiltersEffectsStatusFilter.inactive =>
              l10n.tOr('feInactive', 'Inactive'),
            FiltersEffectsStatusFilter.all =>
              l10n.tOr('feStatusAll', 'All statuses'),
          },
          onRemove: () =>
              setState(() => _status = FiltersEffectsStatusFilter.all),
        ),
      if (isEffects && _renderType != null && _renderType!.trim().isNotEmpty)
        GiftsActiveFilterItem(
          id: 'renderType',
          label: feEffectRenderTypeLabel(context, _renderType!),
          onRemove: () => setState(() => _renderType = null),
        ),
    ];

    final renderOptions = CameraEffectRenderTypeApi.values;

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: widget.width ?? 380,
        height: widget.maxHeight,
        child: Column(
          children: [
            GiftsFilterHeader(onResetAll: _reset, onClose: _close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (widget.showStatusFilter)
                    GiftsFilterSection(
                      title: l10n.tOr('status', 'Status').toUpperCase(),
                      child: GiftsFilterChipWrap(
                        children: [
                          GiftsFilterChoiceChip(
                            label: l10n.tOr('feStatusAll', 'All statuses'),
                            selected: _status == FiltersEffectsStatusFilter.all,
                            onTap: () => setState(
                              () => _status = FiltersEffectsStatusFilter.all,
                            ),
                          ),
                          GiftsFilterChoiceChip(
                            label: l10n.tOr('feActive', 'Active'),
                            selected:
                                _status == FiltersEffectsStatusFilter.active,
                            onTap: () => setState(
                              () => _status = FiltersEffectsStatusFilter.active,
                            ),
                          ),
                          GiftsFilterChoiceChip(
                            label: l10n.tOr('feInactive', 'Inactive'),
                            selected:
                                _status == FiltersEffectsStatusFilter.inactive,
                            onTap: () => setState(
                              () => _status =
                                  FiltersEffectsStatusFilter.inactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isEffects)
                    GiftsFilterSection(
                      title: l10n
                          .tOr('feRenderTypeFilter', 'Render type')
                          .toUpperCase(),
                      child: GiftsFilterChipWrap(
                        children: [
                          GiftsFilterChoiceChip(
                            label: l10n.tOr(
                              'feAllRenderTypes',
                              'All render types',
                            ),
                            selected: _renderType == null,
                            onTap: () => setState(() => _renderType = null),
                          ),
                          for (final type in renderOptions)
                            GiftsFilterChoiceChip(
                              label: feEffectRenderTypeLabel(context, type),
                              selected: _renderType != null &&
                                  CameraEffectRenderTypeApi.fromResponse(
                                        _renderType!,
                                      ) ==
                                      type,
                              onTap: () => setState(() => _renderType = type),
                            ),
                        ],
                      ),
                    ),
                  GiftsActiveFilters(items: activeItems),
                ],
              ),
            ),
            GiftsFilterFooter(
              onReset: _reset,
              onCancel: _close,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
