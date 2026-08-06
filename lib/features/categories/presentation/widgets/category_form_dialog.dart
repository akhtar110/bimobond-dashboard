import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/category_icon_picker.dart';
import 'category_icon.dart';

void showCategoryForm(
  BuildContext context, {
  CategoryEntity? editing,
  CategoryEntity? parentForNew,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<CategoriesBloc>(),
      child: CategoryFormDialog(
        editing: editing,
        parentForNew: parentForNew,
      ),
    ),
  );
}

void confirmDeleteCategory(BuildContext context, CategoryEntity category) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final bloc = context.read<CategoriesBloc>();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: scheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(l10n.t('deleteCategoryTitle'))),
      ]),
      content: Text(
        context.tr('deleteCategoryMessage', {'name': category.name}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            bloc.add(DeleteCategoryEvent(category.id));
          },
          child: Text(l10n.t('delete')),
        ),
      ],
    ),
  );
}

void confirmToggleCategoryStatus(BuildContext context, CategoryEntity category) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final bloc = context.read<CategoriesBloc>();
  final willActivate = !category.isActive;
  final titleText = willActivate
      ? l10n.tOr('activateCategoryTitle', 'Activate Category')
      : l10n.tOr('deactivateCategoryTitle', 'Deactivate Category');
  final actionText = willActivate
      ? l10n.tOr('active', 'Active')
      : l10n.tOr('inActive', 'Inactive');
  final messageText = willActivate
      ? l10n.tOr(
          'activateCategoryMessage',
          'Are you sure you want to activate category "${category.name}"?',
        )
      : l10n.tOr(
          'deactivateCategoryMessage',
          'Are you sure you want to deactivate category "${category.name}"?',
        );

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            willActivate
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            color: willActivate ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(titleText)),
        ],
      ),
      content: Text(messageText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: willActivate ? scheme.primary : scheme.error,
            foregroundColor: willActivate ? scheme.onPrimary : scheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            bloc.add(
              UpdateCategoryEvent(
                id: category.id,
                data: UpdateCategoryData(isActive: willActivate),
              ),
            );
          },
          child: Text(actionText),
        ),
      ],
    ),
  );
}



// â”€â”€â”€ Create / Edit dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({this.editing, this.parentForNew});

  /// Non-null when editing an existing category.
  final CategoryEntity? editing;

  /// Pre-select this root category as parent when creating a new subcategory.
  final CategoryEntity? parentForNew;

  @override
  State<CategoryFormDialog> createState() => CategoryFormDialogState();
}

class CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _iconUrlCtrl;
  late final TextEditingController _orderCtrl;
  late bool _isActive;
  String? _selectedParentId; // null = root category
  Uint8List? _pendingIconBytes;
  String? _pendingIconFilename;
  bool _clearIcon = false;

  bool get _isEditing => widget.editing != null;

  String? get _displayIconUrl {
    if (_clearIcon) return null;
    if (_pendingIconBytes != null) return null;
    final typed = _iconUrlCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return widget.editing?.iconUrl;
  }

  @override
  void initState() {
    super.initState();
    final cat = widget.editing;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _descCtrl = TextEditingController(text: cat?.description ?? '');
    _iconUrlCtrl = TextEditingController(text: cat?.iconUrl ?? '');
    _orderCtrl = TextEditingController(text: '${cat?.order ?? 0}');
    _isActive = cat?.isActive ?? true;

    if (_isEditing) {
      _selectedParentId = cat!.parentId;
    } else if (widget.parentForNew != null) {
      _selectedParentId = widget.parentForNew!.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _iconUrlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  int? _parseOrder(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return int.tryParse(trimmed);
  }

  String? _validateOrder(String? value, String invalidMessage) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return invalidMessage;
    return null;
  }

  Future<void> _pickIconFile() async {
    final picked = await pickCategoryIcon();
    if (!mounted || picked == null) return;
    setState(() {
      _pendingIconBytes = picked.bytes;
      _pendingIconFilename = picked.name;
      _clearIcon = false;
    });
  }

  void _submit(List<CategoryEntity> roots) {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<CategoriesBloc>();
    final iconUrlText = _iconUrlCtrl.text.trim();
    final hasUrl = iconUrlText.isNotEmpty;
    final hasFile = _pendingIconBytes != null;
    final order = _parseOrder(_orderCtrl.text) ?? 0;

    if (_isEditing) {
      final cat = widget.editing!;
      final parentChanged = _selectedParentId != cat.parentId;
      final iconChanged = hasFile ||
          _clearIcon ||
          (hasUrl && iconUrlText != (cat.iconUrl ?? '')) ||
          (!hasUrl && !_clearIcon && cat.iconUrl != null && !hasFile);

      bloc.add(UpdateCategoryEvent(
        id: cat.id,
        data: UpdateCategoryData(
          name: _nameCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          order: order,
          parentId: _selectedParentId,
          setParentId: parentChanged,
          iconBytes: _pendingIconBytes,
          iconFilename: _pendingIconFilename,
          iconUrl: _clearIcon
              ? null
              : (hasUrl ? iconUrlText : null),
          setIconUrl: _clearIcon || (iconChanged && !hasFile),
        ),
      ));
    } else {
      bloc.add(CreateCategoryEvent(
        CreateCategoryData(
          name: _nameCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          order: order,
          parentId: _selectedParentId,
          iconBytes: _pendingIconBytes,
          iconFilename: _pendingIconFilename,
          iconUrl: hasFile ? null : (hasUrl ? iconUrlText : null),
        ),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final outlineBorder = scheme.outlineVariant;

    return BlocListener<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesLoaded && state.successMessage != null) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          final isSubmitting =
              state is CategoriesLoaded && state.isSubmitting;
          final roots = state is CategoriesLoaded
              ? state.roots
                  // Exclude self when editing (cannot be parent of itself)
                  .where((r) => r.id != widget.editing?.id)
                  .toList()
              : <CategoryEntity>[];

          // Cannot set parent if the edited category already has children
          final editedHasChildren = _isEditing &&
              state is CategoriesLoaded &&
              state.childrenOf(widget.editing!.id).isNotEmpty;

          final viewSize = MediaQuery.sizeOf(context);
          final viewPadding = MediaQuery.paddingOf(context);
          final isCompact = viewSize.height < 720 || viewSize.width < 520;
          final dialogMaxWidth =
              viewSize.width > 524 ? 500.0 : viewSize.width - 24;
          final dialogMaxHeight =
              viewSize.height - viewPadding.vertical - (isCompact ? 16 : 32);
          final edgePadding = EdgeInsets.fromLTRB(
            isCompact ? 16 : 28,
            isCompact ? 16 : 24,
            isCompact ? 16 : 28,
            isCompact ? 16 : 20,
          );

          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 24,
              vertical: isCompact ? 12 : 24,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: dialogMaxHeight,
              ),
              child: Padding(
                padding: edgePadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const actionsBlockHeight = 62.0;
                    const headerBlockHeight = 108.0;
                    final scrollMaxHeight = (constraints.maxHeight -
                            headerBlockHeight -
                            actionsBlockHeight)
                        .clamp(120.0, constraints.maxHeight);

                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // ── Dialog header ─────────────────────────────────────
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isEditing
                                ? Icons.edit_outlined
                                : Icons.add_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing
                                    ? l10n.t('editCategory')
                                    : l10n.t('newCategory'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.t('categoriesSubtitle'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: outlineBorder),
                      const SizedBox(height: 16),

                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: scrollMaxHeight),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Name field ──────────────────────────────────
                              CategoryFormField(
                                controller: _nameCtrl,
                                label: l10n.t('categoryName'),
                                hint: l10n.t('categoryNameHint'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? l10n.t('nameRequired')
                                        : null,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 18),

                              // ── Description field ───────────────────────────
                              CategoryFormField(
                                controller: _descCtrl,
                                label: l10n.t('categoryDescription'),
                                hint: l10n.t('categoryDescriptionHint'),
                                maxLines: 3,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 18),

                              // ── Display order ───────────────────────────────
                              CategoryFormField(
                                controller: _orderCtrl,
                                label: l10n.t('categoryDisplayOrder'),
                                hint: l10n.t('categoryDisplayOrderHint'),
                                keyboardType: TextInputType.number,
                                enabled: !isSubmitting,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) => _validateOrder(
                                  v,
                                  l10n.t('categoryOrderInvalid'),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Category icon ───────────────────────────────
                              CategoryFormIconField(
                                isDark: isDark,
                                enabled: !isSubmitting,
                                previewCategory: CategoryEntity(
                                  id: widget.editing?.id ?? '',
                                  name: _nameCtrl.text.trim().isEmpty
                                      ? (widget.editing?.name ?? '')
                                      : _nameCtrl.text.trim(),
                                  slug: widget.editing?.slug ?? '',
                                  iconUrl: _displayIconUrl,
                                  isActive: _isActive,
                                  createdAt: widget.editing?.createdAt ??
                                      DateTime.now(),
                                  updatedAt: widget.editing?.updatedAt ??
                                      DateTime.now(),
                                ),
                                pendingBytes: _pendingIconBytes,
                                iconUrlController: _iconUrlCtrl,
                                onPickFile: _pickIconFile,
                                onClear: () => setState(() {
                                  _pendingIconBytes = null;
                                  _pendingIconFilename = null;
                                  _iconUrlCtrl.clear();
                                  _clearIcon = true;
                                }),
                                onUrlChanged: () =>
                                    setState(() => _clearIcon = false),
                              ),
                              const SizedBox(height: 18),

                              // ── Parent category dropdown ────────────────────
                              if (!editedHasChildren) ...[
                                CategoryParentDropdown(
                                  roots: roots,
                                  selected: _selectedParentId,
                                  isDark: isDark,
                                  enabled: !isSubmitting,
                                  onChanged: (v) =>
                                      setState(() => _selectedParentId = v),
                                ),
                                const SizedBox(height: 18),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: scheme.onTertiaryContainer
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 16,
                                          color: scheme.onTertiaryContainer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.t(
                                              'cannotChangeParentWithChildren'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // ── Active toggle ───────────────────────────────
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: outlineBorder),
                                ),
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    l10n.t('activeLabel'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    l10n.t('visibleToPublic'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  value: _isActive,
                                  onChanged: isSubmitting
                                      ? null
                                      : (v) => setState(() => _isActive = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Dialog actions ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.t('cancel')),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed:
                                isSubmitting ? null : () => _submit(roots),
                            style: FilledButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.onPrimary),
                                  )
                                : Text(
                                    _isEditing
                                        ? l10n.t('saveChanges')
                                        : l10n.t('create'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€ Parent category dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CategoryFormIconField extends StatelessWidget {
  const CategoryFormIconField({
    required this.isDark,
    required this.enabled,
    required this.previewCategory,
    required this.pendingBytes,
    required this.iconUrlController,
    required this.onPickFile,
    required this.onClear,
    required this.onUrlChanged,
  });

  final bool isDark;
  final bool enabled;
  final CategoryEntity previewCategory;
  final Uint8List? pendingBytes;
  final TextEditingController iconUrlController;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final VoidCallback onUrlChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('categoryIcon'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  pendingBytes!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CategoryIcon(
                    category: previewCategory,
                    size: 56,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              CategoryIcon(
                category: previewCategory,
                size: 56,
                borderRadius: BorderRadius.circular(12),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onPickFile : null,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: Text(l10n.t('uploadCategoryIcon')),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: iconUrlController,
                    enabled: enabled,
                    onChanged: (_) => onUrlChanged(),
                    decoration: InputDecoration(
                      labelText: l10n.t('categoryIconUrl'),
                      hintText: l10n.t('categoryIconUrlHint'),
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (previewCategory.iconUrl != null ||
                      pendingBytes != null ||
                      iconUrlController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: enabled ? onClear : null,
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: Text(l10n.t('removeCategoryIcon')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CategoryParentDropdown extends StatelessWidget {
  const CategoryParentDropdown({
    required this.roots,
    required this.selected,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  final List<CategoryEntity> roots;
  final String? selected;
  final bool isDark;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final outlineBorder = scheme.outlineVariant;
    final fillColor = scheme.surfaceContainerLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('parentCategory'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: selected,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: Text(
            l10n.t('noParentCategory'),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(children: [
                Icon(Icons.layers_outlined,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(l10n.t('noParentCategory')),
              ]),
            ),
            ...roots.map(
              (r) => DropdownMenuItem<String?>(
                value: r.id,
                child: CategoryIconLabel(category: r),
              ),
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class CategoryFormField extends StatelessWidget {
  const CategoryFormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fillColor = scheme.surfaceContainerLow;
    final outlineBorder = scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: enabled,
          validator: validator,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.error, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
