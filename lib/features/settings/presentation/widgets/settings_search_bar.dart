import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/search_debounce.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_responsive.dart';
import 'settings_filter_panel.dart';

/// Search field with filter trigger for admin settings.
class SettingsSearchBar extends StatefulWidget {
  const SettingsSearchBar({super.key});

  @override
  State<SettingsSearchBar> createState() => _SettingsSearchBarState();
}

class _SettingsSearchBarState extends State<SettingsSearchBar> {
  final _controller = TextEditingController();
  final _debouncer = SearchDebouncer();

  void _dispatchSearch(String value, {bool immediate = false}) {
    void send() {
      if (!mounted) return;
      context.read<AdminSettingsBloc>().add(UpdateSettingsSearchEvent(value));
    }

    if (immediate) {
      _debouncer.cancel();
      send();
      return;
    }

    _debouncer.run(send);
  }

  int _activeFilterCount(AdminSettingsState state) {
    var count = 0;
    if (state.filterCategory != null && state.filterCategory!.isNotEmpty) {
      count++;
    }
    if (state.visibilityFilter != SettingsVisibilityFilter.all) count++;
    if (state.filterType != null && state.filterType!.isNotEmpty) count++;
    if (state.sort != SettingsSortOption.sortOrder) count++;
    return count;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));
    final compact = metrics.isCompact;

    return BlocListener<AdminSettingsBloc, AdminSettingsState>(
      listenWhen: (prev, next) =>
          prev.searchQuery != next.searchQuery && next.searchQuery.isEmpty,
      listener: (context, state) {
        if (_controller.text.isNotEmpty) _controller.clear();
      },
      child: BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.searchQuery != next.searchQuery ||
          prev.hasActiveFilters != next.hasActiveFilters ||
          prev.filterCategory != next.filterCategory ||
          prev.visibilityFilter != next.visibilityFilter ||
          prev.filterType != next.filterType ||
          prev.sort != next.sort,
      builder: (context, state) {
        final filterCount = _activeFilterCount(state);
        final filterLabel = filterCount > 0
            ? l10n
                .tOr('settingsFiltersWithCount', 'Filters ({count})')
                .replaceAll('{count}', '$filterCount')
            : l10n.tOr('filters', 'Filters');

        final searchField = TextField(
          controller: _controller,
          onChanged: _dispatchSearch,
          onSubmitted: (value) => _dispatchSearch(value, immediate: true),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.tOr('settingsSearchHint', 'Search settings…'),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _dispatchSearch('', immediate: true);
                  },
                );
              },
            ),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            isDense: true,
          ),
        );

        final filterBtn = Material(
          color: filterCount > 0
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => showSettingsFilterPanel(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: metrics.filterControlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: filterCount > 0
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: filterCount > 0
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      filterLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: filterCount > 0
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: filterBtn,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 10),
            filterBtn,
          ],
        );
      },
      ),
    );
  }
}
