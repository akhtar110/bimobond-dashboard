import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/admin_settings_bloc.dart';
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

  static const _allTabs = <AdminSettingsTab>[
    AdminSettingsTab.economy,
    AdminSettingsTab.appSettings,
    AdminSettingsTab.general,
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
    final l10n = context.l10n;
    return switch (tab) {
      AdminSettingsTab.economy => l10n.tOr('economyTab', 'Economy'),
      AdminSettingsTab.appSettings =>
        l10n.tOr('appSettingsTab', 'App settings'),
      AdminSettingsTab.general => l10n.tOr('settingsTabGeneral', 'General'),
      AdminSettingsTab.branding => l10n.tOr('settingsTabBranding', 'Branding'),
      AdminSettingsTab.commission =>
        l10n.tOr('settingsTabCommission', 'Commission'),
      AdminSettingsTab.currencies =>
        l10n.tOr('settingsTabCurrencies', 'Currencies'),
      AdminSettingsTab.auction => l10n.tOr('settingsTabAuction', 'Auction'),
      AdminSettingsTab.promotion =>
        l10n.tOr('settingsTabPromotion', 'Promotion'),
      AdminSettingsTab.features => l10n.tOr('settingsTabFeatures', 'Features'),
      AdminSettingsTab.notifications =>
        l10n.tOr('settingsTabNotifications', 'Notifications'),
      AdminSettingsTab.uploads => l10n.tOr('settingsTabUploads', 'Uploads'),
      AdminSettingsTab.defaults => l10n.tOr('settingsTabDefaults', 'Defaults'),
      AdminSettingsTab.overview => l10n.tOr('settingsTabOverview', 'Overview'),
    };
  }

  static IconData tabIcon(AdminSettingsTab tab) => switch (tab) {
        AdminSettingsTab.economy => Icons.percent_outlined,
        AdminSettingsTab.appSettings => Icons.tune_outlined,
        AdminSettingsTab.general => Icons.settings_outlined,
        AdminSettingsTab.branding => Icons.branding_watermark_outlined,
        AdminSettingsTab.commission => Icons.pie_chart_outline_outlined,
        AdminSettingsTab.currencies => Icons.payments_outlined,
        AdminSettingsTab.auction => Icons.gavel_outlined,
        AdminSettingsTab.promotion => Icons.campaign_outlined,
        AdminSettingsTab.features => Icons.flag_outlined,
        AdminSettingsTab.notifications => Icons.notifications_outlined,
        AdminSettingsTab.uploads => Icons.cloud_upload_outlined,
        AdminSettingsTab.defaults => Icons.restore_outlined,
        AdminSettingsTab.overview => Icons.dashboard_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));

    final tabs = _visibleTabs;
    if (tabs.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) => prev.tab != next.tab,
      builder: (context, state) {
        var effectiveTab = state.tab == AdminSettingsTab.overview
            ? AdminSettingsTab.economy
            : state.tab;
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
            color: scheme.surface,
            borderRadius: BorderRadius.circular(metrics.panelRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: SizedBox(
            height: metrics.tabStripHeight + 16,
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
          ),
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
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final bg = selected ? scheme.primaryContainer : scheme.surfaceContainerHighest;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
