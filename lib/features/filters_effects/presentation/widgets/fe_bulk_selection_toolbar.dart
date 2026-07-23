import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../utils/filters_effects_responsive.dart';

class FeBulkSelectionToolbar extends StatelessWidget {
  const FeBulkSelectionToolbar({
    super.key,
    required this.metrics,
    required this.activeTab,
  });

  final FiltersEffectsLayoutMetrics metrics;
  final FiltersEffectsTab activeTab;

  bool get _isFiltersTab => activeTab == FiltersEffectsTab.filters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<FiltersEffectsBloc, FiltersEffectsState,
        _FeSelectionToolbarData>(
      selector: (state) {
        if (state is! FiltersEffectsLoaded) {
          return const _FeSelectionToolbarData.hidden();
        }
        if (_isFiltersTab) {
          if (!state.hasFilterSelection) {
            return const _FeSelectionToolbarData.hidden();
          }
          return _FeSelectionToolbarData(
            selectedCount: state.selectedFilterCount,
            allVisibleSelected: state.allVisibleFiltersSelected,
            someVisibleSelected: state.someVisibleFiltersSelected,
            isSubmitting: state.isBulkDeleting,
          );
        }
        if (activeTab != FiltersEffectsTab.effects ||
            !state.hasEffectSelection) {
          return const _FeSelectionToolbarData.hidden();
        }
        return _FeSelectionToolbarData(
          selectedCount: state.selectedEffectCount,
          allVisibleSelected: state.allVisibleEffectsSelected,
          someVisibleSelected: state.someVisibleEffectsSelected,
          isSubmitting: state.isBulkDeleting,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        final countLabelKey = _isFiltersTab
            ? 'feFiltersSelectedCount'
            : 'feEffectsSelectedCount';

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.isCompact ? 6 : 10,
            vertical: metrics.isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: data.isSubmitting,
                child: Opacity(
                  opacity: data.isSubmitting ? 0.55 : 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow =
                          metrics.isCompact || constraints.maxWidth < 720;
                      return Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  tristate: true,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: data.allVisibleSelected
                                      ? true
                                      : data.someVisibleSelected
                                          ? null
                                          : false,
                                  onChanged: (_) => _selectAll(context),
                                ),
                                Flexible(
                                  child: Text(
                                    context.tr(countLabelKey, {
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
                                    label: l10n.t('selectAllVisible'),
                                    onPressed: () => _selectAll(context),
                                  ),
                                  _ToolbarLink(
                                    icon: Icons.clear_all_rounded,
                                    label: l10n.t('clearSelection'),
                                    onPressed: () => _clearSelection(context),
                                  ),
                                ] else ...[
                                  IconButton(
                                    tooltip: l10n.t('selectAllVisible'),
                                    icon: const Icon(
                                      Icons.select_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => _selectAll(context),
                                  ),
                                  IconButton(
                                    tooltip: l10n.t('clearSelection'),
                                    icon: const Icon(
                                      Icons.clear_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => _clearSelection(context),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _DeleteButton(
                            l10n: l10n,
                            compact: narrow,
                            isFiltersTab: _isFiltersTab,
                            selectedCount: data.selectedCount,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (data.isSubmitting)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _selectAll(BuildContext context) {
    final bloc = context.read<FiltersEffectsBloc>();
    if (_isFiltersTab) {
      bloc.add(const SelectAllVisibleFiltersEvent());
    } else {
      bloc.add(const SelectAllVisibleEffectsEvent());
    }
  }

  void _clearSelection(BuildContext context) {
    final bloc = context.read<FiltersEffectsBloc>();
    if (_isFiltersTab) {
      bloc.add(const ClearFilterSelectionEvent());
    } else {
      bloc.add(const ClearEffectSelectionEvent());
    }
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
  final VoidCallback onPressed;

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

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.l10n,
    required this.compact,
    required this.isFiltersTab,
    required this.selectedCount,
  });

  final AppLocalizations l10n;
  final bool compact;
  final bool isFiltersTab;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmDelete(context),
            tooltip: l10n.t('delete'),
            style: IconButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          )
        : FilledButton.tonalIcon(
            onPressed: () => _confirmDelete(context),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text(
              l10n.t('delete'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (selectedCount <= 0) return;

    final title = isFiltersTab
        ? l10n.tOr('feBulkDeleteFiltersTitle', 'Delete selected filters')
        : l10n.tOr('feBulkDeleteEffectsTitle', 'Delete selected effects');
    final messageKey = isFiltersTab
        ? 'feBulkDeleteFiltersMessage'
        : 'feBulkDeleteEffectsMessage';

    await showFeConfirmDialog(
      context,
      title: title,
      message: context.tr(messageKey, {'count': '$selectedCount'}),
      onConfirm: () {
        final bloc = context.read<FiltersEffectsBloc>();
        if (isFiltersTab) {
          bloc.add(const BulkDeleteSelectedFiltersEvent());
        } else {
          bloc.add(const BulkDeleteSelectedEffectsEvent());
        }
      },
    );
  }
}

class _FeSelectionToolbarData {
  const _FeSelectionToolbarData({
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.isSubmitting,
  }) : visible = true;

  const _FeSelectionToolbarData.hidden()
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
}
