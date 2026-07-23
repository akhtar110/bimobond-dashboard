import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/app_settings_bloc.dart';
import '../bloc/economy_settings_bloc.dart';
import '../bloc/settings_cubit.dart';
import '../utils/settings_responsive.dart';
import 'settings_admin_body.dart';
import 'settings_admin_tabs.dart';
import 'settings_section.dart';

/// Full admin module shell: legacy bloc providers, tabs, and tab body.
class SettingsPlatformTabs extends StatelessWidget {
  const SettingsPlatformTabs({
    super.key,
    required this.canManage,
    required this.canReadAdmin,
  });

  final bool canManage;
  final bool canReadAdmin;

  @override
  Widget build(BuildContext context) {
    if (!canReadAdmin) return const SizedBox.shrink();

    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final metrics = SettingsLayoutMetrics(getSettingsDeviceType(width));

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<EconomySettingsBloc>()),
        BlocProvider(create: (_) => di.sl<AppSettingsBloc>()),
      ],
      child: SettingsSection(
        title: l10n.tOr('settingsAdminSection', 'Platform administration'),
        description: l10n.tOr(
          'settingsAdminSectionDescription',
          'Manage economy, branding, currencies, feature flags, and more.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsAdminTabs(),
            SizedBox(height: metrics.sectionGap),
            SettingsAdminBody(canManage: canManage),
          ],
        ),
      ),
    );
  }
}
