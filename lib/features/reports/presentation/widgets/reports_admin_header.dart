import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../reports_center_tab.dart';
import '../utils/moderation_filter_labels.dart';
import '../utils/reports_center_breakpoints.dart';
import '../utils/reports_center_theme.dart';
import 'reports_center_nav.dart';

class ReportsAdminHeader extends StatelessWidget {
  const ReportsAdminHeader({
    super.key,
    required this.selected,
    required this.onTabSelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    this.statusFilter,
    this.onStatusFilterChanged,
    this.typeFilter,
    this.onTypeFilterChanged,
    this.showModerationFilters = false,
    this.showTabStrip = true,
    this.showMenuButton = false,
    this.onMenuTap,
    this.hideSearch = false,
    this.availableWidth,
  });

  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onTabSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final String? statusFilter;
  final ValueChanged<String?>? onStatusFilterChanged;
  final String? typeFilter;
  final ValueChanged<String?>? onTypeFilterChanged;
  final bool showModerationFilters;
  final bool showTabStrip;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final bool hideSearch;
  final double? availableWidth;

  String _selectedLabel(BuildContext context) {
    final entry = reportsNavEntries.firstWhere((e) => e.tab == selected);
    return context.l10n.t(entry.labelKey);
  }

  IconData _selectedIcon() {
    final entry = reportsNavEntries.firstWhere((e) => e.tab == selected);
    return entry.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = availableWidth ?? MediaQuery.sizeOf(context).width;
    final stacked = width < ReportsCenterBreakpoints.stackedHeaderMax;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        decoration: ReportsCenterTheme.headerSurface(scheme),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            showMenuButton ? 6 : 20,
            stacked ? 10 : 12,
            16,
            stacked ? 10 : 12,
          ),
          child: stacked
              ? _StackedHeader(
                  selected: selected,
                  onTabSelected: onTabSelected,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  onRefresh: onRefresh,
                  statusFilter: statusFilter,
                  onStatusFilterChanged: onStatusFilterChanged,
                  typeFilter: typeFilter,
                  onTypeFilterChanged: onTypeFilterChanged,
                  showModerationFilters: showModerationFilters,
                  showTabStrip: showTabStrip,
                  showMenuButton: showMenuButton,
                  onMenuTap: onMenuTap,
                  hideSearch: hideSearch,
                  selectedLabel: _selectedLabel(context),
                  selectedIcon: _selectedIcon(),
                )
              : _InlineHeader(
                  selected: selected,
                  onTabSelected: onTabSelected,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  onRefresh: onRefresh,
                  statusFilter: statusFilter,
                  onStatusFilterChanged: onStatusFilterChanged,
                  typeFilter: typeFilter,
                  onTypeFilterChanged: onTypeFilterChanged,
                  showModerationFilters: showModerationFilters,
                  showTabStrip: showTabStrip,
                  showMenuButton: showMenuButton,
                  onMenuTap: onMenuTap,
                  hideSearch: hideSearch,
                  selectedLabel: _selectedLabel(context),
                  selectedIcon: _selectedIcon(),
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: ReportsCenterTheme.accentWash(scheme, scheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              Text(
                context.l10n.t('reportsCenterSubtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ReportsCenterTheme.muted(theme, scheme).copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({
    required this.selected,
    required this.onTabSelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.typeFilter,
    required this.onTypeFilterChanged,
    required this.showModerationFilters,
    required this.showTabStrip,
    required this.showMenuButton,
    required this.onMenuTap,
    required this.hideSearch,
    required this.selectedLabel,
    required this.selectedIcon,
  });

  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onTabSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final String? statusFilter;
  final ValueChanged<String?>? onStatusFilterChanged;
  final String? typeFilter;
  final ValueChanged<String?>? onTypeFilterChanged;
  final bool showModerationFilters;
  final bool showTabStrip;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final bool hideSearch;
  final String selectedLabel;
  final IconData selectedIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showMenuButton) ...[
          IconButton(
            tooltip: context.l10n.t('reportSections'),
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 4),
        ],
        if (showTabStrip)
          Flexible(
            flex: 4,
            child: _TabStrip(selected: selected, onSelected: onTabSelected),
          )
        else
          Expanded(
            flex: 3,
            child: _SectionTitle(
              label: selectedLabel,
              icon: selectedIcon,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _ActionCluster(
              searchController: searchController,
              onSearchChanged: onSearchChanged,
              onRefresh: onRefresh,
              statusFilter: statusFilter,
              onStatusFilterChanged: onStatusFilterChanged,
              typeFilter: typeFilter,
              onTypeFilterChanged: onTypeFilterChanged,
              showModerationFilters: showModerationFilters,
              hideSearch: hideSearch,
              expandedSearch: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedHeader extends StatelessWidget {
  const _StackedHeader({
    required this.selected,
    required this.onTabSelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.typeFilter,
    required this.onTypeFilterChanged,
    required this.showModerationFilters,
    required this.showTabStrip,
    required this.showMenuButton,
    required this.onMenuTap,
    required this.hideSearch,
    required this.selectedLabel,
    required this.selectedIcon,
  });

  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onTabSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final String? statusFilter;
  final ValueChanged<String?>? onStatusFilterChanged;
  final String? typeFilter;
  final ValueChanged<String?>? onTypeFilterChanged;
  final bool showModerationFilters;
  final bool showTabStrip;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final bool hideSearch;
  final String selectedLabel;
  final IconData selectedIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                tooltip: context.l10n.t('reportSections'),
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded),
              ),
            ] else
              const SizedBox(width: 4),
            Expanded(
              child: showTabStrip
                  ? _TabStrip(selected: selected, onSelected: onTabSelected)
                  : _SectionTitle(
                      label: selectedLabel,
                      icon: selectedIcon,
                    ),
            ),
            _RefreshButton(onRefresh: onRefresh, compact: true),
          ],
        ),
        const SizedBox(height: 10),
        _ActionCluster(
          searchController: searchController,
          onSearchChanged: onSearchChanged,
          onRefresh: onRefresh,
          statusFilter: statusFilter,
          onStatusFilterChanged: onStatusFilterChanged,
          typeFilter: typeFilter,
          onTypeFilterChanged: onTypeFilterChanged,
          showModerationFilters: showModerationFilters,
          hideSearch: hideSearch,
          expandedSearch: true,
          hideRefresh: true,
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.selected,
    required this.onSelected,
  });

  final ReportsCenterTab selected;
  final ValueChanged<ReportsCenterTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: reportsNavEntries.map((entry) {
          final isSelected = entry.tab == selected;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: _TabChip(
              label: context.l10n.t(entry.labelKey),
              icon: isSelected ? entry.selectedIcon : entry.icon,
              selected: isSelected,
              onTap: () => onSelected(entry.tab),
              scheme: scheme,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final selected = widget.selected;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.1)
        : _hovered
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow.withValues(alpha: 0.6);
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: ReportsCenterTheme.fast,
        curve: ReportsCenterTheme.ease,
        height: ReportsCenterTheme.headerControlHeight,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 16, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusPill),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: selected ? ReportsCenterTheme.shadowSm(scheme) : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusPill),
          onTap: widget.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.typeFilter,
    required this.onTypeFilterChanged,
    required this.showModerationFilters,
    required this.hideSearch,
    required this.expandedSearch,
    this.hideRefresh = false,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final String? statusFilter;
  final ValueChanged<String?>? onStatusFilterChanged;
  final String? typeFilter;
  final ValueChanged<String?>? onTypeFilterChanged;
  final bool showModerationFilters;
  final bool hideSearch;
  final bool expandedSearch;
  final bool hideRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final statusItems = ModerationFilterLabels.statusOptions(l10n);
    final typeItems = ModerationFilterLabels.typeOptions(l10n);

    final searchField = hideSearch
        ? null
        : SizedBox(
            width: expandedSearch ? double.infinity : 280,
            height: ReportsCenterTheme.headerControlHeight,
            child: _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              hint: l10n.t('searchPlaceholder'),
            ),
          );

    if (expandedSearch) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (searchField != null)
            SizedBox(width: double.infinity, child: searchField),
          if (showModerationFilters) ...[
            _FilterChipDropdown<String?>(
              value: statusFilter,
              hint: ModerationFilterLabels.allStatus(l10n),
              items: statusItems,
              onChanged: onStatusFilterChanged,
            ),
            _FilterChipDropdown<String?>(
              value: typeFilter,
              hint: ModerationFilterLabels.allTypes(l10n),
              items: typeItems,
              onChanged: onTypeFilterChanged,
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showModerationFilters) ...[
          _FilterChipDropdown<String?>(
            value: statusFilter,
            hint: ModerationFilterLabels.allStatus(l10n),
            items: statusItems,
            onChanged: onStatusFilterChanged,
          ),
          const SizedBox(width: 8),
          _FilterChipDropdown<String?>(
            value: typeFilter,
            hint: ModerationFilterLabels.allTypes(l10n),
            items: typeItems,
            onChanged: onTypeFilterChanged,
          ),
          const SizedBox(width: 8),
        ],
        if (searchField != null) ...[
          searchField,
          const SizedBox(width: 8),
        ],
        if (!hideRefresh) _RefreshButton(onRefresh: onRefresh, compact: false),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: ReportsCenterTheme.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusPill),
        border: Border.all(
          color: _focused
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.35),
          width: _focused ? 1.5 : 1,
        ),
        color: scheme.surfaceContainerLow,
        boxShadow: _focused ? ReportsCenterTheme.shadowSm(scheme) : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: _focused ? scheme.primary : scheme.onSurfaceVariant,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
    );
  }
}

class _FilterChipDropdown<T> extends StatelessWidget {
  const _FilterChipDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<({String label, T? value})> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = value != null;

    return Container(
      height: ReportsCenterTheme.headerControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusPill),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(hint, style: const TextStyle(fontSize: 12)),
          ),
          borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusMd),
          icon: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.onRefresh,
    required this.compact,
  });

  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (compact) {
      return IconButton(
        tooltip: l10n.t('refresh'),
        visualDensity: VisualDensity.compact,
        onPressed: onRefresh,
        icon: Icon(Icons.refresh_rounded, color: scheme.primary),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text(l10n.t('refresh')),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: Size(0, ReportsCenterTheme.headerControlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportsCenterTheme.radiusPill),
        ),
      ),
    );
  }
}
