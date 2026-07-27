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
  late final TextEditingController _mimeInputController;
  late bool _boolValue;
  late bool _isPublic;
  late List<String> _mimeTypes;
  late final bool _isMimeSetting;

  @override
  void initState() {
    super.initState();
    final s = widget.setting;
    _isMimeSetting = UploadSettingKeys.isMimeKey(s.key);
    _valueController = TextEditingController(text: s.value);
    _labelController = TextEditingController(text: s.label ?? '');
    _descriptionController = TextEditingController(text: s.description ?? '');
    _sortOrderController = TextEditingController(text: '${s.sortOrder}');
    _mimeInputController = TextEditingController();
    _boolValue = s.boolValue;
    _isPublic = s.isPublic;
    _mimeTypes = _parseMimeList(s.value);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    _mimeInputController.dispose();
    super.dispose();
  }

  List<String> _parseMimeList(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return [];
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return trimmed
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _validateValue(String? value) {
    final l10n = context.l10n;
    if (widget.setting.isBoolean || _isMimeSetting) return null;
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

  void _addMime() {
    final raw = _mimeInputController.text.trim().toLowerCase();
    if (raw.isEmpty) return;
    if (!raw.contains('/')) return;
    if (_mimeTypes.contains(raw)) {
      _mimeInputController.clear();
      return;
    }
    setState(() {
      _mimeTypes = [..._mimeTypes, raw];
      _mimeInputController.clear();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_isMimeSetting && _mimeTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tOr(
              'settingsMimeRequired',
              'Add at least one MIME type',
            ),
          ),
        ),
      );
      return;
    }

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ??
        widget.setting.sortOrder;
    final value = widget.setting.isBoolean
        ? (_boolValue ? 'true' : 'false')
        : _isMimeSetting
            ? jsonEncode(_mimeTypes)
            : _valueController.text.trim();

    final updated = widget.setting.copyWith(
      value: value,
      type: _isMimeSetting ? 'JSON' : widget.setting.type,
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

  Widget _buildValueField(AppLocalizations l10n) {
    if (widget.setting.isBoolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.tOr('settingValue', 'Value')),
        value: _boolValue,
        onChanged: (v) => setState(() => _boolValue = v),
      );
    }

    if (_isMimeSetting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tOr('settingsAllowedMime', 'Allowed MIME types'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_mimeTypes.isEmpty)
            Text(
              l10n.tOr(
                'settingsNoMimeTypes',
                'No MIME types yet. Add e.g. image/jpeg',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final mime in _mimeTypes)
                  InputChip(
                    label: Text(mime),
                    onDeleted: () => setState(() {
                      _mimeTypes = _mimeTypes.where((m) => m != mime).toList();
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mimeInputController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addMime(),
                  decoration: InputDecoration(
                    labelText: l10n.tOr(
                      'settingsAddMime',
                      'Add MIME (e.g. image/png)',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _addMime,
                child: Text(l10n.tOr('add', 'Add')),
              ),
            ],
          ),
        ],
      );
    }

    return TextFormField(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isSaving = context.watch<AdminSettingsBloc>().state.isSaving;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    final form = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
            _buildValueField(l10n),
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

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: form,
      ),
    );
  }
}
