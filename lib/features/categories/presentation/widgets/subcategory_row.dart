import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';

class SubcategoryRow extends StatelessWidget {
  const SubcategoryRow({
    super.key,
    required this.subcategory,
    required this.parentName,
    required this.childrenCount,
    required this.highlighted,
    required this.selected,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity subcategory;
  final String parentName;
  final int childrenCount;
  final bool highlighted;
  final bool selected;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent =
        categoryAccentColor(subcategory.slug, subcategory.name);

    return Material(
      color: highlighted
          ? accent.withValues(alpha: 0.1)
          : selected
              ? scheme.primaryContainer.withValues(alpha: 0.2)
              : Colors.transparent,
      child: InkWell(
        onTap: () => bloc.add(
          ToggleCategorySelectionEvent(subcategory.id),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => bloc.add(
                  ToggleCategorySelectionEvent(subcategory.id),
                ),
              ),
              CategoryIcon(
                category: subcategory,
                size: 24,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: accent.withValues(alpha: 0.12),
                iconColor: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _HighlightText(
                  text: subcategory.name,
                  highlighted: highlighted,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: CategoryStatusBadge(isActive: subcategory.isActive),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$childrenCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  formatCategoryDate(subcategory.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: l10n.t('edit'),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    onFormRequest(editing: subcategory),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: scheme.error),
                tooltip: l10n.t('delete'),
                visualDensity: VisualDensity.compact,
                onPressed: () => onDeleteRequest(subcategory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubcategoryTableHeader extends StatelessWidget {
  const SubcategoryTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    TextStyle headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const SizedBox(width: 34),
          Expanded(flex: 3, child: Text(l10n.t('categoryName'), style: headerStyle)),
          Expanded(flex: 2, child: Text(l10n.tOr('parent', 'Parent'), style: headerStyle)),
          SizedBox(width: 72, child: Text(l10n.t('categoryFilterStatus'), style: headerStyle)),
          SizedBox(width: 48, child: Text(l10n.tOr('children', 'Children'), style: headerStyle)),
          SizedBox(width: 88, child: Text(l10n.tOr('updated', 'Updated'), style: headerStyle)),
          const SizedBox(width: 88),
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.highlighted,
    required this.style,
  });

  final String text;
  final bool highlighted;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!highlighted) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
