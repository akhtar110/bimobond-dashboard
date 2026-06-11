import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_message.dart';
import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/category_icon_picker.dart';
import '../widgets/category_icon.dart';
import '../widgets/category_tree_view.dart';

double _pageHorizontalPadding(double width) {
  if (width >= 1600) return 32;
  if (width >= 768) return 24;
  return 16;
}

// --- Page ---

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      // Only invoke listener when a NEW message actually arrives â€” i.e. the
      // message in the incoming state differs from the one in the previous state.
      // This prevents filter changes or rebuilds from re-showing stale snackbars.
      listenWhen: (previous, current) {
        if (current is! CategoriesLoaded) return false;
        final newMsg =
            current.successMessage ?? current.failureMessage;
        if (newMsg == null) return false;
        if (previous is! CategoriesLoaded) return true;
        final prevMsg = previous.successMessage ?? previous.failureMessage;
        return newMsg != prevMsg;
      },
      listener: (context, state) {
        if (state is! CategoriesLoaded) return;
        final scheme = Theme.of(context).colorScheme;
        final messenger = ScaffoldMessenger.of(context);
        if (state.successMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(localizeMessage(context, state.successMessage!)),
              backgroundColor: scheme.primary,
              behavior: SnackBarBehavior.floating,
            ));
        } else if (state.failureMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.failureMessage!),
              backgroundColor: scheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scheme = theme.colorScheme;

        return LayoutBuilder(
          builder: (context, constraints) {
            final hPad = _pageHorizontalPadding(constraints.maxWidth);
            final hasTree = state is CategoriesLoaded &&
                state.catalogCategories.isNotEmpty &&
                (state.displayRoots.isNotEmpty ||
                    state.searchQuery.trim().isNotEmpty ||
                    state.filter != CategoryFilter.all ||
                    state.typeFilter != CategoryTypeFilter.all);

            return ColoredBox(
              color: scheme.surfaceContainerLowest,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  hPad,
                  hasTree ? 16 : 20,
                  hPad,
                  hasTree ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PageHeader(isDark: isDark, state: state, compact: hasTree),
                    SizedBox(height: hasTree ? 12 : 16),
                    Expanded(
                      child: hasTree
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadow
                                          .withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildBody(context, state, isDark),
                              ),
                            )
                          : _buildBody(context, state, isDark),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoriesState state, bool isDark) {
    if (state is CategoriesLoading) return _LoadingView(isDark: isDark);
    if (state is CategoriesError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
      );
    }
    if (state is CategoriesLoaded) {
      final hasCatalog = state.catalogCategories.isNotEmpty;
      final noFiltersApplied = state.searchQuery.trim().isEmpty &&
          state.filter == CategoryFilter.all &&
          state.typeFilter == CategoryTypeFilter.all;

      if (!hasCatalog && noFiltersApplied) {
        return _EmptyView(isDark: isDark);
      }

      if (state.isFetching && state.filteredRoots.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      if (state.displayRoots.isEmpty) {
        return _FilteredEmptyState(
          filter: state.filter,
          typeFilter: state.typeFilter,
          isDark: isDark,
        );
      }

      return CategoryTreeView(
        state: state,
        onFormRequest: ({editing, parentForNew}) => _showCategoryForm(
          context,
          editing: editing,
          parentForNew: parentForNew,
        ),
        onDeleteRequest: (category) =>
            _confirmDeleteCategory(context, category),
      );
    }
    return const SizedBox.shrink();
  }
}

// â”€â”€â”€ Page header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isDark,
    required this.state,
    this.compact = false,
  });

  final bool isDark;
  final CategoriesState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loaded = state is CategoriesLoaded ? state as CategoriesLoaded : null;
    final total = loaded?.categories.length ?? 0;
    final rootCount = loaded?.roots.length ?? 0;
    final subCount = total - rootCount;
    final active = loaded?.categories.where((c) => c.isActive).length ?? 0;
    final scheme = theme.colorScheme;
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.onSurfaceVariant;
    final outlineBorder = scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('categoriesTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: titleColor,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('categoriesSubtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderBadge(
                      icon: Icons.layers_outlined,
                      label: '$rootCount root',
                      isDark: isDark,
                    ),
                    if (subCount > 0)
                      _HeaderBadge(
                        icon: Icons.account_tree_outlined,
                        label: '$subCount subcategories',
                        isDark: isDark,
                        accent: theme.colorScheme.secondary,
                      ),
                    _HeaderBadge(
                      icon: Icons.check_circle_outline_rounded,
                      label: '$active ${l10n.t('active').toLowerCase()}',
                      isDark: isDark,
                      accent: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              ],
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                isDark: isDark,
                icon: Icons.refresh_rounded,
                tooltip: l10n.t('refresh'),
                onTap: () =>
                    context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _showDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.t('newCategory')),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actions,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: titleBlock), actions],
          );
        }),
        SizedBox(height: compact ? 12 : 24),
        if (!compact) Divider(height: 1, thickness: 1, color: outlineBorder),
      ],
    );
  }

  void _showDialog(BuildContext context, {CategoryEntity? parent}) {
    _showCategoryForm(context, parentForNew: parent);
  }
}

void _showCategoryForm(
  BuildContext context, {
  CategoryEntity? editing,
  CategoryEntity? parentForNew,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<CategoriesBloc>(),
      child: _CategoryFormDialog(
        editing: editing,
        parentForNew: parentForNew,
      ),
    ),
  );
}

void _confirmDeleteCategory(BuildContext context, CategoryEntity category) {
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

// â”€â”€â”€ Filtered empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.filter,
    required this.typeFilter,
    required this.isDark,
  });

  final CategoryFilter filter;
  final CategoryTypeFilter typeFilter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final primary = scheme.primary;

    final (icon, message) = switch (typeFilter) {
      CategoryTypeFilter.subOnly => (
          Icons.account_tree_outlined,
          l10n.tOr('noSubcategoriesFound', 'No subcategories match your filters'),
        ),
      CategoryTypeFilter.rootOnly => (
          Icons.layers_outlined,
          l10n.tOr('noRootCategoriesFound', 'No root categories match your filters'),
        ),
      CategoryTypeFilter.all => switch (filter) {
          CategoryFilter.active => (
              Icons.visibility_outlined,
              l10n.t('noActiveCategories'),
            ),
          CategoryFilter.inactive => (
              Icons.visibility_off_outlined,
              l10n.t('noInactiveCategories'),
            ),
          CategoryFilter.all => (
              Icons.category_outlined,
              l10n.t('noCategoriesYet'),
            ),
        },
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: primary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              final bloc = context.read<CategoriesBloc>();
              bloc.add(ChangeCategoryFilterEvent(CategoryFilter.all));
              bloc.add(UpdateCategoryTypeFilterEvent(CategoryTypeFilter.all));
              bloc.add(UpdateCategorySearchEvent(''));
            },
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: Text(l10n.t('showAllCategories')),
          ),
        ],
      ),
    );
  }
}


// â”€â”€â”€ Create / Edit dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.editing, this.parentForNew});

  /// Non-null when editing an existing category.
  final CategoryEntity? editing;

  /// Pre-select this root category as parent when creating a new subcategory.
  final CategoryEntity? parentForNew;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
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

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // â”€â”€ Dialog header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      const SizedBox(height: 24),
                      Divider(height: 1, color: outlineBorder),
                      const SizedBox(height: 20),

                      // â”€â”€ Name field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _FormField(
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

                      // â”€â”€ Description field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _FormField(
                        controller: _descCtrl,
                        label: l10n.t('categoryDescription'),
                        hint: l10n.t('categoryDescriptionHint'),
                        maxLines: 3,
                        enabled: !isSubmitting,
                      ),
                      const SizedBox(height: 18),

                      // â”€â”€ Display order â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _FormField(
                        controller: _orderCtrl,
                        label: l10n.t('categoryDisplayOrder'),
                        hint: l10n.t('categoryDisplayOrderHint'),
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => _validateOrder(v, l10n.t('categoryOrderInvalid')),
                      ),
                      const SizedBox(height: 18),

                      // â”€â”€ Category icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _CategoryIconField(
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
                          createdAt:
                              widget.editing?.createdAt ?? DateTime.now(),
                          updatedAt:
                              widget.editing?.updatedAt ?? DateTime.now(),
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
                        onUrlChanged: () => setState(() => _clearIcon = false),
                      ),
                      const SizedBox(height: 18),

                      // â”€â”€ Parent category dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (!editedHasChildren) ...[
                        _ParentDropdown(
                          roots: roots,
                          selected: _selectedParentId,
                          isDark: isDark,
                          enabled: !isSubmitting,
                          onChanged: (v) =>
                              setState(() => _selectedParentId = v),
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        // Show info that parent cannot be changed while it has children
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
                                  l10n.t('cannotChangeParentWithChildren'),
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

                      // â”€â”€ Active toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      const SizedBox(height: 24),

                      // â”€â”€ Dialog actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                            onPressed: isSubmitting ? null : () => _submit(roots),
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

class _CategoryIconField extends StatelessWidget {
  const _CategoryIconField({
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

class _ParentDropdown extends StatelessWidget {
  const _ParentDropdown({
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


class _ActionToolButton extends StatefulWidget {
  const _ActionToolButton({
    required this.tooltip,
    required this.onTap,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  @override
  State<_ActionToolButton> createState() => _ActionToolButtonState();
}

class _ActionToolButtonState extends State<_ActionToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final outlineBorder =
        Theme.of(context).colorScheme.outlineVariant;
    final disabled = widget.onTap == null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disabled
                  ? widget.backgroundColor.withValues(alpha: 0.5)
                  : (_hovered
                      ? widget.backgroundColor.withValues(alpha: 0.92)
                      : widget.backgroundColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_hovered && !disabled)
                    ? widget.iconColor.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
              boxShadow: (_hovered && !disabled)
                  ? [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: disabled
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ]),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.isDark,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outlineBorder = scheme.outlineVariant;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hovered
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? scheme.primary.withValues(alpha: 0.35)
                    : outlineBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Form field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FormField extends StatelessWidget {
  const _FormField({
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

// â”€â”€â”€ Empty / Error / Loading states â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: scheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.t('loading'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final outlineBorder = scheme.outlineVariant;
    final bloc = context.read<CategoriesBloc>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: outlineBorder),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.15),
                    primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child:
                  Icon(Icons.category_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('noCategoriesYet'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.t('createFirstCategoryHint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => BlocProvider.value(
                  value: bloc,
                  child: const _CategoryFormDialog(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.t('createFirstCategory')),
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = scheme.error;
    final outlineBorder = scheme.outlineVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: danger.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 36, color: danger),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.t('couldNotLoadCategories'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.t('tryAgain')),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: outlineBorder),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
