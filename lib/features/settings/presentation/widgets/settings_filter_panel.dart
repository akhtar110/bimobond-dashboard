import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../bloc/admin_settings_bloc.dart';

/// Opens the settings filter panel as a centered popup dialog.
Future<void> showSettingsFilterPanel(BuildContext context) {
  final bloc = context.read<AdminSettingsBloc>();

  Widget wrap(Widget child) => BlocProvider<AdminSettingsBloc>.value(
        value: bloc,
        child: child,
      );

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
          child: wrap(
            SettingsFilterPanel(maxHeight: maxHeight),
          ),
        ),
      );
    },
  );
}

class SettingsFilterPanel extends StatefulWidget {
  const SettingsFilterPanel({
    super.key,
    this.maxHeight,
    this.borderRadius,
  });

  final double? maxHeight;
  final BorderRadius? borderRadius;

  @override
  State<SettingsFilterPanel> createState() => _SettingsFilterPanelState();
}

class _SettingsFilterPanelState extends State<SettingsFilterPanel> {
  String? _category;
  SettingsVisibilityFilter _visibility = SettingsVisibilityFilter.all;
  String? _type;
  SettingsSortOption _sort = SettingsSortOption.sortOrder;

  @override
  void initState() {
    super.initState();
    final state = context.read<AdminSettingsBloc>().state;
    _category = state.filterCategory;
    _visibility = state.visibilityFilter;
    _type = state.filterType;
    _sort = state.sort;
  }

  void _apply() {
    context.read<AdminSettingsBloc>().add(
          ApplySettingsFiltersEvent(
            category: _category,
            visibility: _visibility,
            type: _type,
            sort: _sort,
          ),
        );
    Navigator.of(context).pop();
  }

  void _reset() {
    context.read<AdminSettingsBloc>().add(const ClearSettingsFiltersEvent());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AdminSettingsBloc>().state;
    final categories = state.categories.isNotEmpty
        ? state.categories
        : AppSettingCategories.all;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tOr('settingsFiltersTitle', 'Filters'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.tOr('close', 'Close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tOr('settingsFilterCategory', 'Category').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.tOr('settingsFilterAll', 'All')),
                      ),
                      for (final cat in categories)
                        DropdownMenuItem<String?>(
                          value: cat,
                          child: Text(cat),
                        ),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n
                        .tOr('settingsFilterVisibility', 'Visibility')
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<SettingsVisibilityFilter>(
                    segments: [
                      ButtonSegment(
                        value: SettingsVisibilityFilter.all,
                        label: Text(l10n.tOr('settingsFilterAll', 'All')),
                      ),
                      ButtonSegment(
                        value: SettingsVisibilityFilter.publicOnly,
                        label: Text(l10n.tOr('settingsFilterPublic', 'Public')),
                      ),
                      ButtonSegment(
                        value: SettingsVisibilityFilter.privateOnly,
                        label: Text(l10n.tOr('settingsFilterPrivate', 'Private')),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (values) =>
                        setState(() => _visibility = values.first),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tOr('settingsFilterType', 'Type').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _type,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.tOr('settingsFilterAll', 'All')),
                      ),
                      for (final t in const ['STRING', 'NUMBER', 'BOOLEAN', 'JSON'])
                        DropdownMenuItem<String?>(
                          value: t,
                          child: Text(t),
                        ),
                    ],
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tOr('settingsFilterSort', 'Sort').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SettingsSortOption>(
                    value: _sort,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: SettingsSortOption.sortOrder,
                        child: Text(
                          l10n.tOr('settingsSortOrder', 'Sort order'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: SettingsSortOption.alphabetical,
                        child: Text(
                          l10n.tOr('settingsSortAlphabetical', 'Alphabetical'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: SettingsSortOption.category,
                        child: Text(
                          l10n.tOr('settingsSortCategory', 'Category'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: SettingsSortOption.recentlyUpdated,
                        child: Text(
                          l10n.tOr('settingsSortUpdated', 'Recently updated'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(l10n.tOr('resetFilters', 'Reset')),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.tOr('cancel', 'Cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _apply,
                  child: Text(l10n.tOr('apply', 'Apply')),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: panel,
      );
    }

    return panel;
  }
}
