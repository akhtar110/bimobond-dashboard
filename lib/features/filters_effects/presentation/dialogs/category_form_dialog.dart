import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';

void showCategoryFormDialog(
  BuildContext context, {
  required bool isEffectCategory,
  Object? editing,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: CategoryFormDialog(
        isEffectCategory: isEffectCategory,
        editing: editing,
      ),
    ),
  );
}

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    required this.isEffectCategory,
    this.editing,
  });

  final bool isEffectCategory;
  final Object? editing;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _labelKeyCtrl;
  late final TextEditingController _sortOrderCtrl;
  late bool _isActive;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing is CameraFilterCategoryEntity) {
      _slugCtrl = TextEditingController(text: editing.slug);
      _labelCtrl = TextEditingController(text: editing.label);
      _labelKeyCtrl = TextEditingController(text: editing.labelKey ?? '');
      _sortOrderCtrl = TextEditingController(text: '${editing.sortOrder}');
      _isActive = editing.isActive;
    } else if (editing is CameraEffectCategoryEntity) {
      _slugCtrl = TextEditingController(text: editing.slug);
      _labelCtrl = TextEditingController(text: editing.label);
      _labelKeyCtrl = TextEditingController(text: editing.labelKey ?? '');
      _sortOrderCtrl = TextEditingController(text: '${editing.sortOrder}');
      _isActive = editing.isActive;
    } else {
      _slugCtrl = TextEditingController();
      _labelCtrl = TextEditingController();
      _labelKeyCtrl = TextEditingController();
      _sortOrderCtrl = TextEditingController(text: '0');
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _labelCtrl.dispose();
    _labelKeyCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  String? _categoryId() {
    final editing = widget.editing;
    if (editing is CameraFilterCategoryEntity) return editing.id;
    if (editing is CameraEffectCategoryEntity) return editing.id;
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<FiltersEffectsBloc>();
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
    final label = _labelCtrl.text.trim();
    final labelKey = _labelKeyCtrl.text.trim();
    final slug = _slugCtrl.text.trim();

    if (_isEditing) {
      final request = UpdateCategoryRequest(
        slug: slug,
        label: label,
        labelKey: labelKey.isEmpty ? null : labelKey,
        clearLabelKey: labelKey.isEmpty,
        sortOrder: sortOrder,
        isActive: _isActive,
      );
      final id = _categoryId()!;
      if (widget.isEffectCategory) {
        bloc.add(UpdateCameraEffectCategoryEvent(id, request));
      } else {
        bloc.add(UpdateCameraFilterCategoryEvent(id, request));
      }
    } else {
      final request = CreateCategoryRequest(
        slug: slug,
        label: label,
        labelKey: labelKey.isEmpty ? null : labelKey,
        sortOrder: sortOrder,
        isActive: _isActive,
      );
      if (widget.isEffectCategory) {
        bloc.add(CreateCameraEffectCategoryEvent(request));
      } else {
        bloc.add(CreateCameraFilterCategoryEvent(request));
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isEffectCategory
        ? (_isEditing
              ? l10n.tOr('feEditEffectCategory', 'Edit effect category')
              : l10n.tOr('feCreateEffectCategory', 'Create effect category'))
        : (_isEditing
              ? l10n.tOr('feEditFilterCategory', 'Edit filter category')
              : l10n.tOr('feCreateFilterCategory', 'Create filter category'));

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _slugCtrl,
                maxLength: 50,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldSlug', 'Slug'),
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return l10n.tOr('feRequired', 'Required');
                  }
                  if (value.length > 50) {
                    return l10n.tOr('feSlugTooLong', 'Slug is too long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _labelCtrl,
                maxLength: 80,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldLabel', 'Label'),
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return l10n.tOr('feRequired', 'Required');
                  }
                  if (value.length > 80) {
                    return l10n.tOr('feLabelTooLong', 'Label is too long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _labelKeyCtrl,
                maxLength: 100,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldLabelKey', 'Label key'),
                  hintText: l10n.tOr('feFieldLabelKeyOptional', 'Optional'),
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.length > 100) {
                    return l10n.tOr(
                      'feLabelKeyTooLong',
                      'Label key is too long',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sortOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldSortOrder', 'Sort order'),
                ),
              ),
              const SizedBox(height: 10),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.tOr('feSave', 'Save')),
        ),
      ],
    );
  }
}
