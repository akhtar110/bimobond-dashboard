import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_active_filters.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../gifts/presentation/widgets/gifts_filter_models.dart';
import '../../../gifts/presentation/widgets/gifts_filter_section.dart';
import '../bloc/categories_bloc.dart';

int categoriesAppliedFilterCount({
  CategoryFilter filter = CategoryFilter.all,
  CategoryTypeFilter typeFilter = CategoryTypeFilter.all,
  CategoryHasChildrenFilter hasChildrenFilter = CategoryHasChildrenFilter.all,
}) {
  var count = 0;
  if (filter != CategoryFilter.all) count++;
  if (typeFilter != CategoryTypeFilter.all) count++;
  if (hasChildrenFilter != CategoryHasChildrenFilter.all) count++;
  return count;
}

Future<void> showCategoriesFilterPopup({
  required BuildContext context,
  required CategoryFilter statusFilter,
  required CategoryTypeFilter typeFilter,
  required CategoryHasChildrenFilter hasChildrenFilter,
  required Rect anchorRect,
}) {
  final bloc = context.read<CategoriesBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<CategoriesBloc>.value(
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
        CategoriesFilterPopup(
          appliedStatus: statusFilter,
          appliedType: typeFilter,
          appliedHasChildren: hasChildrenFilter,
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
            CategoriesFilterPopup(
              appliedStatus: statusFilter,
              appliedType: typeFilter,
              appliedHasChildren: hasChildrenFilter,
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
                  CategoriesFilterPopup(
                    appliedStatus: statusFilter,
                    appliedType: typeFilter,
                    appliedHasChildren: hasChildrenFilter,
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

class CategoriesFilterPopup extends StatefulWidget {
  const CategoriesFilterPopup({
    super.key,
    required this.appliedStatus,
    required this.appliedType,
    required this.appliedHasChildren,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final CategoryFilter appliedStatus;
  final CategoryTypeFilter appliedType;
  final CategoryHasChildrenFilter appliedHasChildren;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<CategoriesFilterPopup> createState() => _CategoriesFilterPopupState();
}

class _CategoriesFilterPopupState extends State<CategoriesFilterPopup> {
  late CategoryFilter _status;
  late CategoryTypeFilter _type;
  late CategoryHasChildrenFilter _hasChildren;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
    _type = widget.appliedType;
    _hasChildren = widget.appliedHasChildren;
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _reset() {
    setState(() {
      _status = CategoryFilter.all;
      _type = CategoryTypeFilter.all;
      _hasChildren = CategoryHasChildrenFilter.all;
    });
  }

  void _apply(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    if (bloc.activeStatusFilter != _status) {
      bloc.add(ChangeCategoryFilterEvent(_status));
    }
    if (bloc.activeTypeFilter != _type) {
      bloc.add(UpdateCategoryTypeFilterEvent(_type));
    }
    if (bloc.activeHasChildrenFilter != _hasChildren) {
      bloc.add(UpdateCategoryHasChildrenFilterEvent(_hasChildren));
    }
    _close(context);
  }

  String _sectionTitle(String text, BuildContext context) {
    if (context.isRtl) return text;
    return text.toUpperCase();
  }

  List<GiftsActiveFilterItem> _activeItems(AppLocalizations l10n) {
    final items = <GiftsActiveFilterItem>[];
    if (_status != CategoryFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'status',
          label: categoryStatusLabel(l10n, _status),
          onRemove: () => setState(() => _status = CategoryFilter.all),
        ),
      );
    }
    if (_type != CategoryTypeFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'type',
          label: categoryTypeLabel(l10n, _type),
          onRemove: () => setState(() => _type = CategoryTypeFilter.all),
        ),
      );
    }
    if (_hasChildren != CategoryHasChildrenFilter.all) {
      items.add(
        GiftsActiveFilterItem(
          id: 'children',
          label: categoryHasChildrenLabel(l10n, _hasChildren),
          onRemove: () =>
              setState(() => _hasChildren = CategoryHasChildrenFilter.all),
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
                        for (final status in CategoryFilter.values)
                          GiftsFilterChoiceChip(
                            label: categoryStatusLabel(l10n, status),
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: _sectionTitle(
                      l10n.tOr('categoryType', 'Category type'),
                      context,
                    ),
                    child: GiftsFilterChipWrap(
                      children: [
                        for (final type in CategoryTypeFilter.values)
                          GiftsFilterChoiceChip(
                            label: categoryTypeLabel(l10n, type),
                            selected: _type == type,
                            onTap: () => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ),
                  GiftsFilterSection(
                    title: _sectionTitle(
                      l10n.tOr('hasChildren', 'Children'),
                      context,
                    ),
                    child: GiftsFilterChipWrap(
                      children: [
                        GiftsFilterChoiceChip(
                          label: l10n.t('filterAll'),
                          selected: _hasChildren == CategoryHasChildrenFilter.all,
                          onTap: () => setState(
                            () => _hasChildren = CategoryHasChildrenFilter.all,
                          ),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('hasChildrenYes', 'Has children'),
                          selected:
                              _hasChildren == CategoryHasChildrenFilter.yes,
                          onTap: () => setState(
                            () => _hasChildren = CategoryHasChildrenFilter.yes,
                          ),
                        ),
                        GiftsFilterChoiceChip(
                          label: l10n.tOr('hasChildrenNo', 'No children'),
                          selected:
                              _hasChildren == CategoryHasChildrenFilter.no,
                          onTap: () => setState(
                            () => _hasChildren = CategoryHasChildrenFilter.no,
                          ),
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

String categoryStatusLabel(AppLocalizations l10n, CategoryFilter filter) {
  return switch (filter) {
    CategoryFilter.all => l10n.t('filterAll'),
    CategoryFilter.active => l10n.t('active'),
    CategoryFilter.inactive => l10n.t('inactive'),
  };
}

String categoryTypeLabel(AppLocalizations l10n, CategoryTypeFilter filter) {
  return switch (filter) {
    CategoryTypeFilter.all => l10n.t('filterAll'),
    CategoryTypeFilter.rootOnly => l10n.t('rootCategoriesOnly'),
    CategoryTypeFilter.subOnly => l10n.t('subcategoriesOnly'),
  };
}

String categoryHasChildrenLabel(
  AppLocalizations l10n,
  CategoryHasChildrenFilter filter,
) {
  return switch (filter) {
    CategoryHasChildrenFilter.all => l10n.t('filterAll'),
    CategoryHasChildrenFilter.yes =>
      l10n.tOr('hasChildrenYes', 'Has children'),
    CategoryHasChildrenFilter.no => l10n.tOr('hasChildrenNo', 'No children'),
  };
}
