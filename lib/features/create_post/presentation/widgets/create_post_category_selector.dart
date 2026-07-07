import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../domain/entities/create_post_entity.dart';

class CreatePostCategorySelector extends StatelessWidget {
  const CreatePostCategorySelector({
    super.key,
    required this.form,
    /// Called whenever the user picks a category (or "All").
    /// [categoryId] is the UUID (null = All / no category).
    /// [categoryName] is the human-readable label (null when All is chosen).
    required this.onCategorySelected,
  });

  final CreatePostEntity form;
  final void Function(String? categoryId, String? categoryName)
      onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is! CategoriesLoaded) {
          return const LinearProgressIndicator();
        }

        final items = state.catalogCategories;

        return DropdownButtonFormField<String?>(
          // Key off categoryId so the dropdown resets when the form resets.
          key: ValueKey(form.categoryId),
          // Use the UUID as the selected value — this is the single source of
          // truth that is later sent to the backend as `categoryId`.
          value: form.categoryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.t('postCategory'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: [
            // "All / General feed" — clears the category filter.
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.t('categoryAllFeed')),
                ],
              ),
            ),
            for (final cat in items)
              DropdownMenuItem<String?>(
                // value = UUID (categoryId) — the real foreign key.
                value: cat.id.isNotEmpty ? cat.id : null,
                child: CategoryIconLabel(category: cat),
              ),
          ],
          onChanged: (selectedId) {
            if (selectedId == null) {
              // "All" selected — clear category.
              onCategorySelected(null, null);
              return;
            }
            // Look up the full entity to also provide the display name.
            final cat = items.cast<CategoryEntity?>().firstWhere(
                  (c) => c?.id == selectedId,
                  orElse: () => null,
                );
            onCategorySelected(cat?.id, cat?.name);
          },
        );
      },
    );
  }
}
