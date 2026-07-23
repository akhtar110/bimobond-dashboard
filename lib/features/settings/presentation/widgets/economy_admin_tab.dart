import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import 'economy_settings_cards.dart';
import 'setting_edit_dialog.dart';
import 'setting_item_card.dart';

/// Legacy economy cards plus admin-managed economy keys.
class EconomyAdminTab extends StatelessWidget {
  const EconomyAdminTab({super.key});

  static const _extraKeys = ['DEFAULT_CURRENCY_CODE', 'MIN_WITHDRAWAL_COINS'];

  @override
  Widget build(BuildContext context) {
    final canManage = PermissionManager.canWriteSettings(context);
    final l10n = context.l10n;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.settings != next.settings || prev.isLoading != next.isLoading,
      builder: (context, state) {
        final extra = state.settingsByKeys(_extraKeys);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EconomySettingsCards(
              canManage: canManage,
              embedded: true,
            ),
            if (extra.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.tOr('settingsEconomyExtras', 'Economy configuration'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < extra.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SettingItemCard(
                  setting: extra[i],
                  canWrite: canManage,
                  onEdit: canManage
                      ? () => showSettingEditDialog(context, extra[i])
                      : null,
                  onDelete: null,
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
