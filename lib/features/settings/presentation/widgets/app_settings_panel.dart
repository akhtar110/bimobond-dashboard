import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/settings_cubit.dart';
import 'settings_section.dart';

class AppSettingsPanel extends StatefulWidget {
  const AppSettingsPanel({
    super.key,
    required this.canManage,
    this.embedded = false,
  });

  final bool canManage;
  final bool embedded;

  @override
  State<AppSettingsPanel> createState() => _AppSettingsPanelState();
}

class _AppSettingsPanelState extends State<AppSettingsPanel> {
  @override
  void initState() {
    super.initState();
    context.read<AppSettingsBloc>().add(const LoadAppSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<AppSettingsBloc, AppSettingsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        } else if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        context.select<SettingsCubit, Locale>((c) => c.state.locale);
        final l10n = context.l10n;

        final columns = <DataColumn>[
          DataColumn(label: Text(l10n.t('settingKey'))),
          DataColumn(label: Text(l10n.t('settingValue'))),
          DataColumn(label: Text(l10n.t('description'))),
          if (widget.canManage) DataColumn(label: Text(l10n.t('actions'))),
        ];

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.canManage)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _openEditor(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.t('addSetting')),
                ),
              ),
            if (widget.canManage) const SizedBox(height: 16),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.settings.isEmpty)
              EmptyStateCard(
                icon: Icons.tune_outlined,
                title: l10n.t('noSettings'),
                message: l10n.t('noSettingsMessage'),
              )
            else
              ResponsiveDataTable(
                columns: columns,
                rows: state.settings.map((setting) {
                  return DataRow(
                    cells: [
                      DataCell(Text(setting.key)),
                      DataCell(Text(setting.value)),
                      DataCell(Text(setting.description ?? '—')),
                      if (widget.canManage)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.t('edit'),
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: state.isSaving
                                    ? null
                                    : () => _openEditor(
                                          context,
                                          existing: setting,
                                        ),
                              ),
                              IconButton(
                                tooltip: l10n.t('delete'),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: scheme.error,
                                ),
                                onPressed: state.isSaving
                                    ? null
                                    : () => _confirmDelete(
                                          context,
                                          setting.key,
                                        ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }).toList(),
                mobileCards: [
                  for (final setting in state.settings)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              setting.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.tArgs(
                                'settingValueLabel',
                                {'value': setting.value},
                              ),
                            ),
                            if (setting.description != null)
                              Text(
                                l10n.tArgs(
                                  'settingDescriptionLabel',
                                  {'description': setting.description!},
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            if (state.isSaving) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(color: scheme.primary),
            ],
          ],
        );

        if (widget.embedded) return body;

        return SettingsSection(
          title: l10n.t('appSettingsTab'),
          description: widget.canManage
              ? l10n.t('appSettingsManageDescription')
              : l10n.t('appSettingsReadOnlyDescription'),
          child: body,
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    AppSettingEntity? existing,
  }) async {
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final isEdit = existing != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(
            isEdit
                ? dialogL10n.t('editSetting')
                : dialogL10n.t('createSetting'),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyCtrl,
                  enabled: !isEdit,
                  decoration: InputDecoration(
                    labelText: dialogL10n.t('settingKey'),
                    hintText: 'SETTING_KEY',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  decoration: InputDecoration(
                    labelText: dialogL10n.t('settingValue'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: dialogL10n.t('descriptionOptional'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                isEdit ? dialogL10n.t('save') : dialogL10n.t('create'),
              ),
            ),
          ],
        );
      },
    );

    if (saved != true || !context.mounted) return;

    final entity = AppSettingEntity(
      key: keyCtrl.text.trim(),
      value: valueCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );

    final bloc = context.read<AppSettingsBloc>();
    if (isEdit) {
      bloc.add(UpdateAppSettingEvent(entity));
    } else {
      bloc.add(CreateAppSettingEvent(entity));
    }
  }

  Future<void> _confirmDelete(BuildContext context, String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(dialogL10n.t('deleteSettingTitle')),
          content: Text(
            dialogL10n.tArgs('deleteSettingMessage', {'key': key}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dialogL10n.t('delete')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<AppSettingsBloc>().add(DeleteAppSettingEvent(key));
    }
  }
}
