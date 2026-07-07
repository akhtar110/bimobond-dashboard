import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../utils/fe_preview_color_utils.dart';
import '../widgets/fe_catalog_item_preview.dart';
import '../widgets/fe_effect_form_fields.dart';
import '../widgets/fe_filter_form_fields.dart';
import '../widgets/fe_form_preview_panel.dart';

void showEffectFormDialog(
  BuildContext context, {
  CameraEffectEntity? editing,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: EffectFormDialog(editing: editing),
    ),
  );
}

class EffectFormDialog extends StatefulWidget {
  const EffectFormDialog({super.key, this.editing});

  final CameraEffectEntity? editing;

  @override
  State<EffectFormDialog> createState() => _EffectFormDialogState();
}

class _EffectFormDialogState extends State<EffectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _assetCtrl;
  late final TextEditingController _labelKeyCtrl;
  late final TextEditingController _sortOrderCtrl;
  late String _selectedEffectType;
  late String _previewColorHex;
  late bool _requiresFaceDetection;
  late bool _isScreenEffect;
  late bool _isActive;

  bool get _isEditing => widget.editing != null;

  String get _previewLabel {
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
    _selectedEffectType =
        CameraEffectTypeApi.normalize(e?.effectType ?? CameraEffectTypeApi.faceAr);
    _emojiCtrl = TextEditingController(text: e?.emoji ?? '');
    _assetCtrl = TextEditingController(text: e?.assetUrl ?? '');
    _labelKeyCtrl = TextEditingController(text: e?.labelKey ?? '');
    _sortOrderCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _previewColorHex = e?.previewColorHex?.trim().isNotEmpty == true
        ? e!.previewColorHex!.trim().toUpperCase()
        : defaultPreviewColorHex(required: true);
    _requiresFaceDetection = e?.requiresFaceDetection ?? false;
    _isScreenEffect = e?.isScreenEffect ?? false;
    _isActive = e?.isActive ?? true;

    final flags = CameraEffectTypeApi.flagsForType(
      _selectedEffectType,
      requiresFaceDetection: _requiresFaceDetection,
    );
    _requiresFaceDetection = flags.requiresFaceDetection;
    _isScreenEffect = flags.isScreenEffect;

    for (final ctrl in [_slugCtrl, _labelKeyCtrl, _emojiCtrl, _assetCtrl]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _emojiCtrl.dispose();
    _assetCtrl.dispose();
    _labelKeyCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _onEffectTypeChanged(String value) {
    setState(() {
      _selectedEffectType = value;
      final flags = CameraEffectTypeApi.flagsForType(
        value,
        requiresFaceDetection: _requiresFaceDetection,
      );
      _requiresFaceDetection = flags.requiresFaceDetection;
      _isScreenEffect = flags.isScreenEffect;
    });
  }

  ({String effectType, bool requiresFaceDetection, bool isScreenEffect})
      _resolvedEffectPayload() {
    final effectType = CameraEffectTypeApi.normalize(_selectedEffectType);
    final flags = CameraEffectTypeApi.flagsForType(
      effectType,
      requiresFaceDetection: _requiresFaceDetection,
    );
    return (
      effectType: effectType,
      requiresFaceDetection: flags.requiresFaceDetection,
      isScreenEffect: flags.isScreenEffect,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_previewColorHex.trim().isEmpty) return;
    final bloc = context.read<FiltersEffectsBloc>();
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
    final payload = _resolvedEffectPayload();

    if (_isEditing) {
      bloc.add(
        UpdateCameraEffectEvent(
          widget.editing!.id,
          UpdateEffectRequest(
            slug: _slugCtrl.text.trim(),
            effectType: payload.effectType,
            emoji: _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim(),
            assetUrl: _assetCtrl.text.trim().isEmpty ? null : _assetCtrl.text.trim(),
            previewColorHex: _previewColorHex.trim(),
            labelKey: _labelKeyCtrl.text.trim(),
            requiresFaceDetection: payload.requiresFaceDetection,
            isScreenEffect: payload.isScreenEffect,
            sortOrder: sortOrder,
            isActive: _isActive,
          ),
        ),
      );
    } else {
      bloc.add(
        CreateCameraEffectEvent(
          CreateEffectRequest(
            slug: _slugCtrl.text.trim(),
            effectType: payload.effectType,
            emoji: _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim(),
            assetUrl: _assetCtrl.text.trim().isEmpty ? null : _assetCtrl.text.trim(),
            previewColorHex: _previewColorHex.trim(),
            labelKey: _labelKeyCtrl.text.trim(),
            requiresFaceDetection: payload.requiresFaceDetection,
            isScreenEffect: payload.isScreenEffect,
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

    return AlertDialog(
      title: Text(
        _isEditing
            ? l10n.tOr('feEditEffect', 'Edit effect')
            : l10n.tOr('feCreateEffect', 'Create effect'),
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
                              onSelected: (hex) {
                                if (hex != null) {
                                  setState(() => _previewColorHex = hex);
                                }
                              },
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
                            FeEffectTypeField(
                              value: _selectedEffectType,
                              onChanged: _onEffectTypeChanged,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _labelKeyCtrl,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.tOr('feFieldLabelKey', 'Label key'),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.tOr('feRequired', 'Required')
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emojiCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.tOr('feFieldEmoji', 'Emoji'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _assetCtrl,
                              decoration: InputDecoration(
                                labelText:
                                    l10n.tOr('feFieldAssetUrl', 'Asset URL'),
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
                              title: Text(
                                l10n.tOr('feFlagFaceDetection', 'Face detection'),
                              ),
                              value: _requiresFaceDetection,
                              onChanged: CameraEffectTypeApi.isScreenOverlay(
                                _selectedEffectType,
                              )
                                  ? null
                                  : (v) =>
                                      setState(() => _requiresFaceDetection = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsetsDirectional.zero,
                              title: Text(
                                l10n.tOr('feFlagScreenEffect', 'Screen effect'),
                              ),
                              value: _isScreenEffect,
                              onChanged: !CameraEffectTypeApi.isScreenOverlay(
                                _selectedEffectType,
                              )
                                  ? null
                                  : (v) => setState(() => _isScreenEffect = v),
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
                mode: FeCatalogPreviewMode.effect,
                label: _previewLabel,
                previewColorHex: _previewColorHex,
                emoji: _emojiCtrl.text.trim(),
                thumbnailUrl: _assetCtrl.text.trim(),
                effectType: CameraEffectTypeApi.normalize(_selectedEffectType),
                requiresFaceDetection: _requiresFaceDetection,
                isScreenEffect: _isScreenEffect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
