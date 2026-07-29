import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/settings/presentation/bloc/settings_cubit.dart';
import '../../../localization/localization.dart';
import '../../../widgets/web_dashboard_layout.dart';
import '../../bloc/sidebar_bloc.dart';
import '../../models/sidebar_menu_group.dart' as models;
import 'sidebar_menu_item.dart';

class SidebarMenuGroup extends StatelessWidget {
  const SidebarMenuGroup({
    super.key,
    required this.group,
    required this.items,
    required this.currentIndex,
    required this.collapsed,
    required this.searchQuery,
    required this.onDestinationSelected,
    this.tabVisible,
  });

  final models.SidebarMenuGroupConfig group;
  final List<DashboardNavItem> items;
  final int currentIndex;
  final bool collapsed;
  final String searchQuery;
  final ValueChanged<int> onDestinationSelected;
  final bool Function(int tabIndex)? tabVisible;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final visibleIndices = _visibleIndices();
    if (visibleIndices.isEmpty) return const SizedBox.shrink();

    final groupExpanded = context.select(
      (SidebarBloc b) => b.state.isGroupExpanded(group.id),
    );
    final title = l10n.tOr(group.titleL10nKey, group.fallbackTitle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
            child: InkWell(
              onTap: () => context
                  .read<SidebarBloc>()
                  .add(ToggleMenuGroupEvent(group.id)),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: groupExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              for (final index in visibleIndices)
                SidebarMenuItem(
                  key: ValueKey(items[index].label),
                  item: items[index],
                  selected: index == currentIndex,
                  collapsed: collapsed,
                  searchQuery: searchQuery,
                  onTap: () => onDestinationSelected(index),
                ),
            ],
          ),
          crossFadeState: collapsed || groupExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  List<int> _visibleIndices() {
    final query = searchQuery.trim().toLowerCase();
    return [
      for (final index in group.itemIndices)
        if (index >= 0 &&
            index < items.length &&
            (tabVisible == null || tabVisible!(index)) &&
            (query.isEmpty ||
                items[index].label.toLowerCase().contains(query)))
          index,
    ];
  }
}
