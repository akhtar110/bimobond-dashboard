import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../search_history/presentation/widgets/search_history_date_range_dialog.dart';
import '../../domain/entities/user_history_entity.dart';
import '../bloc/user_history_bloc.dart';
import '../bloc/user_history_event.dart';
import '../bloc/user_history_state.dart';
import '../utils/user_history_labels.dart';

class UserHistoryFiltersBar extends StatelessWidget {
  const UserHistoryFiltersBar({super.key});

  static const double dateButtonWidth = 168;
  static const double typesButtonWidth = 180;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<UserHistoryBloc, UserHistoryState, UserHistoryQuery>(
      selector: (state) => state.query,
      builder: (context, query) {
        final hasDateRange = query.from != null && query.to != null;
        final dateLabel = hasDateRange
            ? '${_fmtDate(query.from!)} – ${_fmtDate(query.to!)}'
            : l10n.t('dateRange');

        final typesLabel = query.types.isEmpty
            ? l10n.tOr('userHistoryActivityTypes', 'Activity Types')
            : l10n.tOr(
                'userHistoryTypesSelected',
                '{count} selected',
              ).replaceAll('{count}', '${query.types.length}');

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: dateButtonWidth,
                height: ToolbarFilterStyle.controlHeight,
                child: _FilterActionButton(
                  label: dateLabel,
                  icon: Icons.date_range_rounded,
                  highlighted: hasDateRange,
                  onTap: () => _pickDateRange(context, query),
                  onClear: hasDateRange
                      ? () => context.read<UserHistoryBloc>().add(
                            const ChangeUserHistoryFilters(
                              clearDateRange: true,
                            ),
                          )
                      : null,
                ),
              ),
              SizedBox(
                width: typesButtonWidth,
                height: ToolbarFilterStyle.controlHeight,
                child: _TypesFilterButton(
                  label: typesLabel,
                  selected: query.types,
                  highlighted: query.types.isNotEmpty,
                ),
              ),
              if (query.hasActiveFilters)
                IconButton(
                  tooltip: l10n.tOr('clearFilters', 'Clear filters'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => context
                      .read<UserHistoryBloc>()
                      .add(const ClearUserHistoryFilters()),
                  icon: Icon(
                    Icons.filter_alt_off_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    UserHistoryQuery query,
  ) async {
    final result = await showSearchHistoryDateRangeDialog(
      context,
      initialFrom: query.from,
      initialTo: query.to,
    );
    if (result == null || !context.mounted) return;

    if (result.clear) {
      context.read<UserHistoryBloc>().add(
            const ChangeUserHistoryFilters(clearDateRange: true),
          );
      return;
    }

    if (result.range != null) {
      context.read<UserHistoryBloc>().add(
            ChangeUserHistoryFilters(dateRange: result.range),
          );
    }
  }

  static String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.label,
    required this.icon,
    required this.highlighted,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.08)
          : scheme.surface,
      borderRadius: ToolbarFilterStyle.radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: ToolbarFilterStyle.radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: ToolbarFilterStyle.radius,
            border: Border.all(
              color: highlighted ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: highlighted ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypesFilterButton extends StatelessWidget {
  const _TypesFilterButton({
    required this.label,
    required this.selected,
    required this.highlighted,
  });

  final String label;
  final List<String> selected;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final selectedSet = selected.toSet();

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        maximumSize: const WidgetStatePropertyAll(Size(320, 360)),
      ),
      builder: (context, controller, child) {
        return Material(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surface,
          borderRadius: ToolbarFilterStyle.radius,
          child: InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: ToolbarFilterStyle.radius,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: ToolbarFilterStyle.radius,
                border: Border.all(
                  color: highlighted ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color:
                        highlighted ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: highlighted ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        for (final type in UserHistoryTypes.filterOptions)
          CheckboxMenuButton(
            value: selectedSet.contains(type),
            onChanged: (checked) {
              final next = List<String>.from(selected);
              if (checked == true) {
                if (!next.contains(type)) next.add(type);
              } else {
                next.remove(type);
              }
              context.read<UserHistoryBloc>().add(
                    ChangeUserHistoryFilters(types: next),
                  );
            },
            child: Text(
              userHistoryTypeLabel(l10n, type),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: selected.isEmpty
              ? null
              : () => context.read<UserHistoryBloc>().add(
                    const ChangeUserHistoryFilters(clearTypes: true),
                  ),
          child: Text(l10n.tOr('clearAll', 'Clear all')),
        ),
      ],
    );
  }
}
