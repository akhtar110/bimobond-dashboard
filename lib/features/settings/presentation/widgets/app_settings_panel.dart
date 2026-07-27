import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
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
              _AppSettingsList(
                settings: state.settings,
                canManage: widget.canManage,
                isSaving: state.isSaving,
                onEdit: (setting) => _openEditor(context, existing: setting),
                onDelete: (key) => _confirmDelete(context, key),
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

/// Responsive settings list — no horizontal scroll; actions stay visible.
class _AppSettingsList extends StatelessWidget {
  const _AppSettingsList({
    required this.settings,
    required this.canManage,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AppSettingEntity> settings;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<AppSettingEntity> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < settings.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            _AppSettingRow(
              setting: settings[i],
              canManage: canManage,
              isSaving: isSaving,
              keyLabel: l10n.t('settingKey'),
              valueLabel: l10n.t('settingValue'),
              descriptionLabel: l10n.t('description'),
              onEdit: () => onEdit(settings[i]),
              onDelete: () => onDelete(settings[i].key),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppSettingRow extends StatelessWidget {
  const _AppSettingRow({
    required this.setting,
    required this.canManage,
    required this.isSaving,
    required this.keyLabel,
    required this.valueLabel,
    required this.descriptionLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final AppSettingEntity setting;
  final bool canManage;
  final bool isSaving;
  final String keyLabel;
  final String valueLabel;
  final String descriptionLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final actions = canManage
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.t('edit'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: isSaving ? null : onEdit,
              ),
              IconButton(
                tooltip: l10n.t('delete'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: scheme.error,
                ),
                onPressed: isSaving ? null : onDelete,
              ),
            ],
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        if (wide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _LabeledField(
                    label: keyLabel,
                    child: Text(
                      setting.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _LabeledField(
                    label: valueLabel,
                    child: Text(
                      setting.value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _LabeledField(
                    label: descriptionLabel,
                    child: Text(
                      setting.description?.trim().isNotEmpty == true
                          ? setting.description!
                          : '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: setting.description?.trim().isNotEmpty == true
                            ? null
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  actions,
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      setting.key,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  ?actions,
                ],
              ),
              const SizedBox(height: 8),
              _LabeledField(
                label: valueLabel,
                child: Text(
                  setting.value,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (setting.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _LabeledField(
                  label: descriptionLabel,
                  child: Text(
                    setting.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}
