import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';
import '../utils/settings_responsive.dart';

/// Horizontally scrollable Material 3 chips for admin settings tabs.
class SettingsAdminTabs extends StatelessWidget {
  const SettingsAdminTabs({
    super.key,
    this.canReadAdmin = true,
    this.canManageCurrencies = false,
  });

  final bool canReadAdmin;
  final bool canManageCurrencies;

  /// API-aligned tabs — legacy App Settings / General (all) duplicates removed.
  static const _allTabs = <AdminSettingsTab>[
    AdminSettingsTab.economy,
    AdminSettingsTab.branding,
    AdminSettingsTab.commission,
    AdminSettingsTab.currencies,
    AdminSettingsTab.auction,
    AdminSettingsTab.promotion,
    AdminSettingsTab.features,
    AdminSettingsTab.notifications,
    AdminSettingsTab.uploads,
    AdminSettingsTab.defaults,
  ];

  List<AdminSettingsTab> get _visibleTabs {
    if (canReadAdmin) return _allTabs;
    if (canManageCurrencies) return const [AdminSettingsTab.currencies];
    return const [];
  }

  static String tabLabel(BuildContext context, AdminSettingsTab tab) {
    return switch (tab) {
      AdminSettingsTab.economy =>
        SettingsAdminL10n.tabLabel(context, 'economy'),
      AdminSettingsTab.branding =>
        SettingsAdminL10n.tabLabel(context, 'branding'),
      AdminSettingsTab.commission =>
        SettingsAdminL10n.tabLabel(context, 'commission'),
      AdminSettingsTab.currencies =>
        SettingsAdminL10n.tabLabel(context, 'currencies'),
      AdminSettingsTab.auction =>
        SettingsAdminL10n.tabLabel(context, 'auction'),
      AdminSettingsTab.promotion =>
        SettingsAdminL10n.tabLabel(context, 'promotion'),
      AdminSettingsTab.features =>
        SettingsAdminL10n.tabLabel(context, 'features'),
      AdminSettingsTab.notifications =>
        SettingsAdminL10n.tabLabel(context, 'notifications'),
      AdminSettingsTab.uploads =>
        SettingsAdminL10n.tabLabel(context, 'uploads'),
      AdminSettingsTab.defaults =>
        SettingsAdminL10n.tabLabel(context, 'defaults'),
      AdminSettingsTab.appSettings ||
      AdminSettingsTab.general ||
      AdminSettingsTab.overview =>
        SettingsAdminL10n.tabLabel(context, 'economy'),
    };
  }

  static IconData tabIcon(AdminSettingsTab tab) => switch (tab) {
        AdminSettingsTab.economy => Icons.percent_outlined,
        AdminSettingsTab.branding => Icons.branding_watermark_outlined,
        AdminSettingsTab.commission => Icons.pie_chart_outline_outlined,
        AdminSettingsTab.currencies => Icons.payments_outlined,
        AdminSettingsTab.auction => Icons.gavel_outlined,
        AdminSettingsTab.promotion => Icons.campaign_outlined,
        AdminSettingsTab.features => Icons.flag_outlined,
        AdminSettingsTab.notifications => Icons.notifications_outlined,
        AdminSettingsTab.uploads => Icons.cloud_upload_outlined,
        AdminSettingsTab.defaults => Icons.restore_outlined,
        AdminSettingsTab.appSettings ||
        AdminSettingsTab.general ||
        AdminSettingsTab.overview =>
          Icons.settings_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tabs = _visibleTabs;
    if (tabs.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));

        return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) => prev.tab != next.tab,
      builder: (context, state) {
        var effectiveTab = switch (state.tab) {
          AdminSettingsTab.overview ||
          AdminSettingsTab.appSettings ||
          AdminSettingsTab.general =>
            AdminSettingsTab.economy,
          _ => state.tab,
        };
        if (!tabs.contains(effectiveTab)) {
          effectiveTab = tabs.first;
          if (state.tab != effectiveTab) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context
                  .read<AdminSettingsBloc>()
                  .add(ChangeAdminSettingsTabEvent(effectiveTab));
            });
          }
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(metrics.panelRadius),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _AdminTabChip(
                    label: tabLabel(context, tabs[i]),
                    icon: tabIcon(tabs[i]),
                    selected: effectiveTab == tabs[i],
                    onTap: () => context.read<AdminSettingsBloc>().add(
                          ChangeAdminSettingsTabEvent(tabs[i]),
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
        );
      },
    );
  }
}

class _AdminTabChip extends StatelessWidget {
  const _AdminTabChip({
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
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final bg = selected ? scheme.primary : scheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
