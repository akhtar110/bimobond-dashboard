import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';

/// Selection bar with select-all / clear controls — matches [UsersSelectionHeader].
class CategoriesSelectionHeader extends StatelessWidget {
  const CategoriesSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<CategoriesBloc, CategoriesState, _SelectionBarData>(
      selector: (state) {
        if (state is! CategoriesLoaded || !state.isSelectionMode) {
          return const _SelectionBarData.hidden();
        }
        return _SelectionBarData(
          selectedCount: state.selectedCount,
          allVisibleSelected: state.allVisibleSelected,
          someVisibleSelected: state.someVisibleSelected,
          isSubmitting: state.isSubmitting,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: IgnorePointer(
            ignoring: data.isSubmitting,
            child: Opacity(
              opacity: data.isSubmitting ? 0.55 : 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 720;
                  final bloc = context.read<CategoriesBloc>();

                  return Row(
                    children: [
                      Checkbox(
                        tristate: true,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: data.allVisibleSelected
                            ? true
                            : data.someVisibleSelected
                                ? null
                                : false,
                        onChanged: data.isSubmitting
                            ? null
                            : (_) => bloc.add(
                                  SelectAllVisibleCategoriesEvent(),
                                ),
                      ),
                      Flexible(
                        child: Text(
                          context.tr('categoriesSelectedCount', {
                            'count': '${data.selectedCount}',
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!narrow) ...[
                        _ToolbarLink(
                          icon: Icons.select_all_rounded,
                          label: l10n.t('selectAllCategories'),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(
                                    SelectAllVisibleCategoriesEvent(
                                      toggle: false,
                                    ),
                                  ),
                        ),
                        _ToolbarLink(
                          icon: Icons.clear_all_rounded,
                          label: l10n.t('clearSelection'),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(ClearCategorySelectionEvent()),
                        ),
                      ] else ...[
                        IconButton(
                          tooltip: l10n.t('selectAllCategories'),
                          icon: const Icon(Icons.select_all_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(
                                    SelectAllVisibleCategoriesEvent(
                                      toggle: false,
                                    ),
                                  ),
                        ),
                        IconButton(
                          tooltip: l10n.t('clearSelection'),
                          icon: const Icon(Icons.clear_all_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: data.isSubmitting
                              ? null
                              : () => bloc.add(ClearCategorySelectionEvent()),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarLink extends StatelessWidget {
  const _ToolbarLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class _SelectionBarData {
  const _SelectionBarData({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.isSubmitting,
  }) : visible = true;

  const _SelectionBarData.hidden()
      : selectedCount = 0,
        allVisibleSelected = false,
        someVisibleSelected = false,
        isSubmitting = false,
        visible = false;

  final int selectedCount;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final bool isSubmitting;
  final bool visible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SelectionBarData &&
          visible == other.visible &&
          selectedCount == other.selectedCount &&
          allVisibleSelected == other.allVisibleSelected &&
          someVisibleSelected == other.someVisibleSelected &&
          isSubmitting == other.isSubmitting;

  @override
  int get hashCode => Object.hash(
        visible,
        selectedCount,
        allVisibleSelected,
        someVisibleSelected,
        isSubmitting,
      );
}
