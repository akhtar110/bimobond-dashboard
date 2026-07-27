import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_responsive.dart';
import 'app_settings_panel.dart';
import 'auction_settings_tab.dart';
import 'branding_tab.dart';
import 'commission_tab.dart';
import 'currencies_tab.dart';
import 'defaults_tab.dart';
import 'economy_admin_tab.dart';
import 'features_settings_tab.dart';
import 'general_settings_tab.dart';
import 'notification_settings_tab.dart';
import 'promotion_settings_tab.dart';
import 'upload_settings_tab.dart';

/// Renders the active admin settings tab content.
class SettingsAdminBody extends StatelessWidget {
  const SettingsAdminBody({
    super.key,
    required this.canManage,
  });

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.tab != next.tab ||
          prev.isLoading != next.isLoading ||
          prev.error != next.error,
      builder: (context, state) {
        if (state.error != null &&
            state.settings.isEmpty &&
            state.currencies.isEmpty &&
            !state.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmptyStateCard(
                icon: Icons.error_outline,
                title: l10n.tOr('settingsLoadError', 'Failed to load settings'),
                message: state.error!,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.center,
                child: FilledButton.icon(
                  onPressed: () => context
                      .read<AdminSettingsBloc>()
                      .add(const LoadAdminSettingsEvent(refresh: true)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.tOr('retry', 'Retry')),
                ),
              ),
            ],
          );
        }

        final tab = state.tab == AdminSettingsTab.overview
            ? AdminSettingsTab.economy
            : state.tab;

        final content = switch (tab) {
          AdminSettingsTab.economy => const EconomyAdminTab(),
          AdminSettingsTab.appSettings => AppSettingsPanel(
              canManage: canManage,
              embedded: true,
            ),
          AdminSettingsTab.general => const GeneralSettingsTab(),
          AdminSettingsTab.branding => const BrandingTab(),
          AdminSettingsTab.commission => const CommissionTab(),
          AdminSettingsTab.currencies => const CurrenciesTab(),
          AdminSettingsTab.auction => const AuctionSettingsTab(),
          AdminSettingsTab.promotion => const PromotionSettingsTab(),
          AdminSettingsTab.features => const FeaturesSettingsTab(),
          AdminSettingsTab.notifications => const NotificationSettingsTab(),
          AdminSettingsTab.uploads => const UploadSettingsTab(),
          AdminSettingsTab.defaults => const DefaultsTab(),
          AdminSettingsTab.overview => const SizedBox.shrink(),
        };

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(metrics.panelRadius),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(metrics.panelPadding),
            child: state.isLoading &&
                    state.settings.isEmpty &&
                    state.currencies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : content,
          ),
        );
      },
    );
  }
}
