import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/app_setting_entity.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_admin_l10n.dart';

Future<void> showCreateSettingDialog(BuildContext context) {
  final bloc = context.read<AdminSettingsBloc>();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BlocProvider<AdminSettingsBloc>.value(
      value: bloc,
      child: const CreateSettingDialog(),
    ),
  );
}

class CreateSettingDialog extends StatefulWidget {
  const CreateSettingDialog({super.key});

  @override
  State<CreateSettingDialog> createState() => _CreateSettingDialogState();
}

class _CreateSettingDialogState extends State<CreateSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  final _labelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String _type = 'STRING';
  late String _category;
  bool _boolValue = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    final categories = SettingsAdminL10n.resolveCategories(
      context.read<AdminSettingsBloc>().state.categories,
    );
    _category = categories.contains(AppSettingCategories.features)
        ? AppSettingCategories.features
        : categories.first;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _labelController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  bool get _isBoolean => _type == 'BOOLEAN';
  bool get _isNumber => _type == 'NUMBER';
  bool get _isJson => _type == 'JSON';

  String? _validateKey(String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.tOr('settingsKeyRequired', 'Key is required');
    }
    if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(value.trim())) {
      return l10n.tOr(
        'settingsKeyFormat',
        'Use UPPER_SNAKE_CASE (A-Z, 0-9, _)',
      );
    }
    return null;
  }

  String? _validateValue(String? value) {
    final l10n = context.l10n;
    if (_isBoolean) return null;
    if (value == null || value.trim().isEmpty) {
      return l10n.tOr('settingsValueRequired', 'Value is required');
    }
    if (_isNumber && double.tryParse(value.trim()) == null) {
      return l10n.tOr('settingsInvalidNumber', 'Enter a valid number');
    }
    if (_isJson) {
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

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final value = _isBoolean
        ? (_boolValue ? 'true' : 'false')
        : _valueController.text.trim();

    final setting = AppSettingEntity(
      key: _keyController.text.trim().toUpperCase(),
      value: value,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _type,
      category: _category,
      sortOrder: sortOrder,
      isPublic: _isPublic,
    );

    context.read<AdminSettingsBloc>().add(CreateAdminSettingEvent(setting));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSaving = context.select<AdminSettingsBloc, bool>(
      (b) => b.state.isSaving,
    );
    final apiCategories = context.select<AdminSettingsBloc, List<String>>(
      (b) => b.state.categories,
    );
    final categories = SettingsAdminL10n.resolveCategories(apiCategories);
    final selectedCategory =
        categories.contains(_category) ? _category : categories.first;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('newSetting', 'New setting')),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _keyController,
                  validator: _validateKey,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('settingKey', 'Key'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('type_$_type'),
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('settingsTypeField', 'Type'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    for (final t in const [
                      'STRING',
                      'NUMBER',
                      'BOOLEAN',
                      'JSON',
                    ])
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          SettingsAdminL10n.settingTypeLabel(context, t),
                        ),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _type = v);
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('category_$selectedCategory'),
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('settingsFilterCategory', 'Category'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    for (final cat in categories)
                      DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          SettingsAdminL10n.categoryLabel(context, cat),
                        ),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _category = v);
                        },
                ),
                const SizedBox(height: 12),
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
                if (_isBoolean)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.tOr('settingValue', 'Value')),
                    value: _boolValue,
                    onChanged:
                        isSaving ? null : (v) => setState(() => _boolValue = v),
                  )
                else
                  TextFormField(
                    controller: _valueController,
                    validator: _validateValue,
                    maxLines: _isJson ? 6 : 1,
                    keyboardType: _isNumber
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    inputFormatters: _isNumber
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.\-]'),
                            ),
                          ]
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
                  onChanged:
                      isSaving ? null : (v) => setState(() => _isPublic = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.tOr('cancel', 'Cancel')),
        ),
        FilledButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.tOr('create', 'Create')),
        ),
      ],
    );
  }
}
