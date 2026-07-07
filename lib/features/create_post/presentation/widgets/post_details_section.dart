import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import 'create_post_category_selector.dart';
import 'create_post_description_field.dart';
import 'create_post_field_listener.dart';
import 'create_post_location_card.dart';
import 'create_post_sound_section.dart';

class PostDetailsSection extends StatelessWidget {
  const PostDetailsSection({
    super.key,
    required this.form,
    required this.onFieldUpdate,
  });

  final CreatePostEntity form;
  final CreatePostFieldUpdater onFieldUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inferred = form.inferredType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreatePostDescriptionField(
          value: form.description,
          onChanged: (v) => onFieldUpdate(CreatePostField.description, v),
        ),
        const SizedBox(height: 16),
        CreatePostCategorySelector(
          form: form,
          onCategorySelected: (id, name) {
            onFieldUpdate(CreatePostField.categoryId, id);
            if (id != null) {
              onFieldUpdate(CreatePostField.category, name);
            }
          },
        ),
        const SizedBox(height: 16),
        CreatePostLocationCard(form: form),
        const SizedBox(height: 16),
        CreatePostSoundSection(form: form),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.t('postType'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            '$inferred (${l10n.t('postTypeAutoHint')})',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
