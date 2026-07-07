import 'package:flutter/material.dart';
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
      _labelKeyCtrl = TextEditingController(text: editing.labelKey);
      _sortOrderCtrl = TextEditingController(text: '${editing.sortOrder}');
      _isActive = editing.isActive;
    } else if (editing is CameraEffectCategoryEntity) {
      _slugCtrl = TextEditingController(text: editing.slug);
      _labelKeyCtrl = TextEditingController(text: editing.labelKey);
      _sortOrderCtrl = TextEditingController(text: '${editing.sortOrder}');
      _isActive = editing.isActive;
    } else {
      _slugCtrl = TextEditingController();
      _labelKeyCtrl = TextEditingController();
      _sortOrderCtrl = TextEditingController(text: '0');
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
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

    if (_isEditing) {
      final request = UpdateCategoryRequest(
        slug: _slugCtrl.text.trim(),
        labelKey: _labelKeyCtrl.text.trim(),
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
        slug: _slugCtrl.text.trim(),
        labelKey: _labelKeyCtrl.text.trim(),
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
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldSlug', 'Slug'),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.tOr('feRequired', 'Required') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _labelKeyCtrl,
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldLabelKey', 'Label key'),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.tOr('feRequired', 'Required') : null,
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
