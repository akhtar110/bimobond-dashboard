import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';

class CategoryBulkActionsBar extends StatelessWidget {
  const CategoryBulkActionsBar({super.key, required this.roots});

  final List<CategoryEntity> roots;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoriesBloc, CategoriesState, _BulkBarData>(
      selector: (state) {
        if (state is! CategoriesLoaded || !state.isSelectionMode) {
          return const _BulkBarData.hidden();
        }
        return _BulkBarData(
          selectedIds: state.selectedCategoryIds.toList(),
          isSubmitting: state.isSubmitting,
          visible: true,
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        final l10n = context.l10n;
        final scheme = Theme.of(context).colorScheme;
        final bloc = context.read<CategoriesBloc>();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            border: Border(
              top: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
              if (data.isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _BulkBtn(
                label: l10n.t('active'),
                enabled: !data.isSubmitting,
                onTap: () => bloc.add(
                  BulkActivateCategoriesEvent(data.selectedIds),
                ),
              ),
              _BulkBtn(
                label: l10n.t('inactive'),
                enabled: !data.isSubmitting,
                onTap: () => bloc.add(
                  BulkDeactivateCategoriesEvent(data.selectedIds),
                ),
              ),
              _BulkBtn(
                label: l10n.tOr('hide', 'Hide'),
                enabled: !data.isSubmitting,
                onTap: () => bloc.add(
                  BulkDeactivateCategoriesEvent(data.selectedIds),
                ),
              ),
              _BulkBtn(
                label: l10n.t('delete'),
                enabled: !data.isSubmitting,
                destructive: true,
                onTap: () => _confirmBulkDelete(context, data.selectedIds),
              ),
              _BulkBtn(
                label: l10n.tOr('move', 'Move'),
                enabled: !data.isSubmitting,
                onTap: () => _showMoveDialog(context, data.selectedIds, roots),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmBulkDelete(BuildContext context, List<String> ids) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deleteCategoryTitle')),
        content: Text(
          l10n.tOr(
            'deleteCategoriesConfirm',
            'Delete ${ids.length} selected categories?',
          ),
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
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CategoriesBloc>().add(
                    BulkDeleteCategoriesEvent(ids),
                  );
            },
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    List<String> ids,
    List<CategoryEntity> roots,
  ) {
    final l10n = context.l10n;
    String? parentId;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.tOr('moveCategories', 'Move categories')),
          content: DropdownButtonFormField<String?>(
            value: parentId,
            decoration: InputDecoration(
              labelText: l10n.tOr('newParent', 'New parent'),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.t('noParentCategory')),
              ),
              for (final root in roots)
                if (!ids.contains(root.id))
                  DropdownMenuItem(
                    value: root.id,
                    child: Text(root.name),
                  ),
            ],
            onChanged: (v) => setState(() => parentId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<CategoriesBloc>().add(
                      BulkMoveCategoriesEvent(ids: ids, parentId: parentId),
                    );
              },
              child: Text(l10n.tOr('move', 'Move')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkBarData {
  const _BulkBarData({
    required this.selectedIds,
    required this.isSubmitting,
    required this.visible,
  });

  const _BulkBarData.hidden()
      : selectedIds = const [],
        isSubmitting = false,
        visible = false;

  final List<String> selectedIds;
  final bool isSubmitting;
  final bool visible;
}

class _BulkBtn extends StatelessWidget {
  const _BulkBtn({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: destructive ? scheme.error : scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
