import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_responsive.dart';

Future<void> showSettingEditDialog(
  BuildContext context,
  AppSettingEntity setting,
) {
  final bloc = context.read<AdminSettingsBloc>();
  return showSettingsAdaptiveForm<void>(
    context: context,
    builder: (ctx) => BlocProvider<AdminSettingsBloc>.value(
      value: bloc,
      child: SettingEditDialog(setting: setting),
    ),
  );
}

class SettingEditDialog extends StatefulWidget {
  const SettingEditDialog({super.key, required this.setting});

  final AppSettingEntity setting;

  @override
  State<SettingEditDialog> createState() => _SettingEditDialogState();
}

class _SettingEditDialogState extends State<SettingEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;
  late bool _boolValue;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    final s = widget.setting;
    _valueController = TextEditingController(text: s.value);
    _labelController = TextEditingController(text: s.label ?? '');
    _descriptionController = TextEditingController(text: s.description ?? '');
    _sortOrderController = TextEditingController(text: '${s.sortOrder}');
    _boolValue = s.boolValue;
    _isPublic = s.isPublic;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  String? _validateValue(String? value) {
    final l10n = context.l10n;
    if (widget.setting.isBoolean) return null;
    if (value == null || value.trim().isEmpty) {
      return l10n.tOr('settingsValueRequired', 'Value is required');
    }
    if (widget.setting.isNumber &&
        double.tryParse(value.trim()) == null) {
      return l10n.tOr('settingsInvalidNumber', 'Enter a valid number');
    }
    if (widget.setting.isJson) {
      try {
        jsonDecode(value);
      } catch (_) {
        return l10n.tOr('settingsInvalidJson', 'Enter valid JSON');
      }
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ??
        widget.setting.sortOrder;
    final value = widget.setting.isBoolean
        ? (_boolValue ? 'true' : 'false')
        : _valueController.text.trim();

    final updated = widget.setting.copyWith(
      value: value,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sortOrder: sortOrder,
      isPublic: _isPublic,
    );

    context.read<AdminSettingsBloc>().add(UpdateAdminSettingEvent(updated));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final isSaving = context.watch<AdminSettingsBloc>().state.isSaving;

    final form = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tOr('editSettingTitle', 'Edit setting'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.setting.key,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.tOr('settingsLabelField', 'Label'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.tOr('description', 'Description'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.setting.isBoolean)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.tOr('settingValue', 'Value')),
                value: _boolValue,
                onChanged: (v) => setState(() => _boolValue = v),
              )
            else
              TextFormField(
                controller: _valueController,
                validator: _validateValue,
                maxLines: widget.setting.isJson ? 6 : 1,
                keyboardType: widget.setting.isNumber
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                inputFormatters: widget.setting.isNumber
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.tOr('settingValue', 'Value'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sortOrderController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.tOr('settingsSortOrderField', 'Sort order'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tOr('settingsPublicField', 'Public')),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.tOr('cancel', 'Cancel')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: isSaving ? null : _save,
                  child: Text(l10n.tOr('save', 'Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (compact) {
      return Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: form,
      );
    }

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: form,
      ),
    );
  }
}
