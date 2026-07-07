import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../data/datasources/filters_effects_remote_datasource.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../widgets/fe_catalog_item_preview.dart';
import '../widgets/fe_filter_form_fields.dart';
import '../widgets/fe_form_preview_panel.dart';

void showFilterFormDialog(
  BuildContext context, {
  CameraFilterEntity? editing,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: FilterFormDialog(editing: editing),
    ),
  );
}

class FilterFormDialog extends StatefulWidget {
  const FilterFormDialog({super.key, this.editing});

  final CameraFilterEntity? editing;

  @override
  State<FilterFormDialog> createState() => _FilterFormDialogState();
}

class _FilterFormDialogState extends State<FilterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugCtrl;
  late final TextEditingController _labelKeyCtrl;
  late final TextEditingController _customLabelCtrl;
  late final TextEditingController _thumbnailCtrl;
  late final TextEditingController _sortOrderCtrl;
  late String? _previewColorHex;
  late String _engineKey;
  late String _engineType;
  late bool _isOriginal;
  late bool _isBeautyDefault;
  late bool _isActive;

  bool get _isEditing => widget.editing != null;

  String get _previewLabel {
    final custom = _customLabelCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    final key = _labelKeyCtrl.text.trim();
    if (key.isNotEmpty) return key;
    final slug = _slugCtrl.text.trim();
    return slug.isNotEmpty ? slug : '—';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _slugCtrl = TextEditingController(text: e?.slug ?? '');
    _labelKeyCtrl = TextEditingController(text: e?.labelKey ?? '');
    _customLabelCtrl = TextEditingController(text: e?.customLabel ?? '');
    _thumbnailCtrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _sortOrderCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _previewColorHex = e?.previewColorHex?.trim().isNotEmpty == true
        ? e!.previewColorHex!.trim().toUpperCase()
        : null;
    _engineKey = e?.engineKey ?? kCameraAwesomeEngineKeys.first;
    _engineType = e?.engineType ?? 'CAMERAAWESOME';
    _isOriginal = e?.isOriginal ?? false;
    _isBeautyDefault = e?.isBeautyDefault ?? false;
    _isActive = e?.isActive ?? true;

    for (final ctrl in [_slugCtrl, _labelKeyCtrl, _customLabelCtrl, _thumbnailCtrl]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _labelKeyCtrl.dispose();
    _customLabelCtrl.dispose();
    _thumbnailCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<FiltersEffectsBloc>();
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
    final previewHex = _previewColorHex?.trim();

    if (_isEditing) {
      bloc.add(
        UpdateCameraFilterEvent(
          widget.editing!.id,
          UpdateFilterRequest(
            slug: _slugCtrl.text.trim(),
            engineKey: _engineKey,
            engineType: _engineType,
            labelKey: _labelKeyCtrl.text.trim().isEmpty
                ? null
                : _labelKeyCtrl.text.trim(),
            customLabel: _customLabelCtrl.text.trim().isEmpty
                ? null
                : _customLabelCtrl.text.trim(),
            thumbnailUrl: _thumbnailCtrl.text.trim().isEmpty
                ? null
                : _thumbnailCtrl.text.trim(),
            previewColorHex:
                previewHex == null || previewHex.isEmpty ? null : previewHex,
            isOriginal: _isOriginal,
            isBeautyDefault: _isBeautyDefault,
            sortOrder: sortOrder,
            isActive: _isActive,
          ),
        ),
      );
    } else {
      bloc.add(
        CreateCameraFilterEvent(
          CreateFilterRequest(
            slug: _slugCtrl.text.trim(),
            engineKey: _engineKey,
            engineType: _engineType,
            labelKey: _labelKeyCtrl.text.trim().isEmpty
                ? null
                : _labelKeyCtrl.text.trim(),
            customLabel: _customLabelCtrl.text.trim().isEmpty
                ? null
                : _customLabelCtrl.text.trim(),
            thumbnailUrl: _thumbnailCtrl.text.trim().isEmpty
                ? null
                : _thumbnailCtrl.text.trim(),
            previewColorHex:
                previewHex == null || previewHex.isEmpty ? null : previewHex,
            isOriginal: _isOriginal,
            isBeautyDefault: _isBeautyDefault,
            sortOrder: sortOrder,
            isActive: _isActive,
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      title: Text(
        _isEditing
            ? l10n.tOr('feEditFilter', 'Edit filter')
            : l10n.tOr('feCreateFilter', 'Create filter'),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SizedBox(
        width: 860,
        height: maxHeight.clamp(480, 720),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: FeFilterFormTheme(
                child: Form(
                  key: _formKey,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FeFormColorPicker(
                              selectedHex: _previewColorHex,
                              allowClear: true,
                              onSelected: (hex) =>
                                  setState(() => _previewColorHex = hex),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _slugCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.tOr('feFieldSlug', 'Slug'),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.tOr('feRequired', 'Required')
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            FeFilterEngineKeyField(
                              value: _engineKey,
                              onChanged: (v) => setState(() => _engineKey = v),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _labelKeyCtrl,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.tOr('feFieldLabelKey', 'Label key'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _customLabelCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.tOr(
                                  'feFieldCustomLabel',
                                  'Custom label',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _thumbnailCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.tOr(
                                  'feFieldThumbnailUrl',
                                  'Thumbnail URL',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _sortOrderCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.tOr('feFieldSortOrder', 'Sort order'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              contentPadding: EdgeInsetsDirectional.zero,
                              title: Text(l10n.tOr('feFlagOriginal', 'Original')),
                              value: _isOriginal,
                              onChanged: (v) => setState(() => _isOriginal = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsetsDirectional.zero,
                              title: Text(
                                l10n.tOr('feFlagBeautyDefault', 'Beauty default'),
                              ),
                              value: _isBeautyDefault,
                              onChanged: (v) =>
                                  setState(() => _isBeautyDefault = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsetsDirectional.zero,
                              title: Text(l10n.tOr('feActive', 'Active')),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.t('cancel')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(l10n.tOr('feSave', 'Save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(width: 16),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 9,
              child: FeFormPreviewPane(
                mode: FeCatalogPreviewMode.filter,
                label: _previewLabel,
                previewColorHex: _previewColorHex,
                engineKey: _engineKey,
                thumbnailUrl: _thumbnailCtrl.text.trim(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
