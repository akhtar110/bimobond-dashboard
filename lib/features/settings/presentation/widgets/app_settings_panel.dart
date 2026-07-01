import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../bloc/app_settings_bloc.dart';
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
        final columns = <DataColumn>[
          const DataColumn(label: Text('Key')),
          const DataColumn(label: Text('Value')),
          const DataColumn(label: Text('Description')),
          if (widget.canManage) const DataColumn(label: Text('Actions')),
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
                  label: const Text('Add setting'),
                ),
              ),
            if (widget.canManage) const SizedBox(height: 16),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.settings.isEmpty)
              const EmptyStateCard(
                icon: Icons.tune_outlined,
                title: 'No settings',
                message: 'Create a setting to store platform configuration.',
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
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: state.isSaving
                                    ? null
                                    : () => _openEditor(
                                          context,
                                          existing: setting,
                                        ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
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
                            Text('Value: ${setting.value}'),
                            if (setting.description != null)
                              Text('Description: ${setting.description}'),
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
          title: 'App settings',
          description: widget.canManage
              ? 'Manage arbitrary key-value configuration'
              : 'Read-only view of platform settings',
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
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit setting' : 'Create setting'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                enabled: !isEdit,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'SETTING_KEY',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Delete setting?'),
        content: Text('Remove "$key" from platform configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppSettingsBloc>().add(DeleteAppSettingEvent(key));
    }
  }
}
