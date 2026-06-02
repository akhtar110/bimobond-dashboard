import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../domain/entities/create_post_entity.dart';

class CreatePostCategorySelector extends StatelessWidget {
  const CreatePostCategorySelector({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final CreatePostEntity form;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is! CategoriesLoaded) {
          return const LinearProgressIndicator();
        }

        final items = state.categories;
        return DropdownButtonFormField<String?>(
          key: ValueKey(form.category),
          initialValue: form.category,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.t('postCategory'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.t('selectCategory')),
            ),
            for (final cat in items)
              DropdownMenuItem<String?>(
                // API expects a free-text category label in `POST /posts`.
                value: cat.name,
                child: Text(cat.name),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
