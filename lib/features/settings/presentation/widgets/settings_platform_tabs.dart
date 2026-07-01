import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../bloc/app_settings_bloc.dart';
import '../bloc/economy_settings_bloc.dart';
import 'app_settings_panel.dart';
import 'economy_settings_cards.dart';
import 'settings_section.dart';

/// Economy + app configuration behind a responsive two-tab switcher.
class SettingsPlatformTabs extends StatefulWidget {
  const SettingsPlatformTabs({super.key, required this.canManage});

  final bool canManage;

  @override
  State<SettingsPlatformTabs> createState() => _SettingsPlatformTabsState();
}

class _SettingsPlatformTabsState extends State<SettingsPlatformTabs> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<EconomySettingsBloc>()),
        BlocProvider(create: (_) => di.sl<AppSettingsBloc>()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scheme = Theme.of(context).colorScheme;
          final compact = width < 560;
          final useStackedTabs = width < 400;

          return SettingsSection(
            title: 'Platform configuration',
            description: 'Economy rules and global key-value settings',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 10 : 14,
                      compact ? 10 : 12,
                      compact ? 10 : 14,
                      0,
                    ),
                    child: _SettingsTabSelector(
                      selectedIndex: _selectedIndex,
                      compact: compact,
                      stacked: useStackedTabs,
                      onSelect: _selectTab,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Visibility(
                    visible: _selectedIndex == 0,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 16,
                        0,
                        compact ? 10 : 16,
                        compact ? 14 : 18,
                      ),
                      child: EconomySettingsCards(
                        canManage: widget.canManage,
                        embedded: true,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _selectedIndex == 1,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 16,
                        0,
                        compact ? 10 : 16,
                        compact ? 14 : 18,
                      ),
                      child: AppSettingsPanel(
                        canManage: widget.canManage,
                        embedded: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsTabSelector extends StatelessWidget {
  const _SettingsTabSelector({
    required this.selectedIndex,
    required this.compact,
    required this.stacked,
    required this.onSelect,
  });

  final int selectedIndex;
  final bool compact;
  final bool stacked;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsTabChip(
            label: 'Economy',
            icon: Icons.percent_outlined,
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 8),
          _SettingsTabChip(
            label: 'App settings',
            icon: Icons.tune_outlined,
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
        ],
      );
    }

    if (compact) {
      return SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(
            value: 0,
            icon: Icon(Icons.percent_outlined, size: 18),
            label: Text('Economy'),
          ),
          ButtonSegment<int>(
            value: 1,
            icon: Icon(Icons.tune_outlined, size: 18),
            label: Text('App'),
          ),
        ],
        selected: {selectedIndex},
        onSelectionChanged: (values) => onSelect(values.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _SettingsTabChip(
                label: 'Economy settings',
                icon: Icons.percent_outlined,
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SettingsTabChip(
                label: 'App settings',
                icon: Icons.tune_outlined,
                selected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTabChip extends StatelessWidget {
  const _SettingsTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final bg = selected ? scheme.primaryContainer : scheme.surface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
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
