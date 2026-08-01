import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/economy_settings_bloc.dart';
import '../bloc/settings_cubit.dart';
import '../utils/settings_responsive.dart';
import 'settings_admin_body.dart';
import 'settings_admin_tabs.dart';
import 'settings_section.dart';

/// Full admin module shell: tabs and tab body.
class SettingsPlatformTabs extends StatelessWidget {
  const SettingsPlatformTabs({
    super.key,
    required this.canManage,
    required this.canReadAdmin,
    this.canManageCurrencies = false,
  });

  final bool canManage;
  final bool canReadAdmin;
  final bool canManageCurrencies;

  @override
  Widget build(BuildContext context) {
    if (!canReadAdmin && !canManageCurrencies) {
      return const SizedBox.shrink();
    }

    // Rebuild labels when language changes.
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => di.sl<EconomySettingsBloc>(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));

          return SettingsSection(
            title: l10n.tOr('settingsAdminSection', 'Platform administration'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsAdminTabs(
                  canReadAdmin: canReadAdmin,
                  canManageCurrencies: canManageCurrencies,
                ),
                SizedBox(height: metrics.sectionGap + 4),
                SettingsAdminBody(canManage: canManage),
              ],
            ),
          );
        },
      ),
    );
  }
}
