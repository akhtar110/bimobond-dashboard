import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_field.dart';
import 'create_post_category_selector.dart';
import 'create_post_field_listener.dart';

class PostDetailsSection extends StatefulWidget {
  const PostDetailsSection({
    super.key,
    required this.form,
    required this.onFieldUpdate,
  });

  final CreatePostEntity form;
  final CreatePostFieldUpdater onFieldUpdate;

  @override
  State<PostDetailsSection> createState() => _PostDetailsSectionState();
}

class _PostDetailsSectionState extends State<PostDetailsSection> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.form.description ?? '');
  }

  @override
  void didUpdateWidget(covariant PostDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.form.description != widget.form.description &&
        _descriptionController.text != (widget.form.description ?? '')) {
      _descriptionController.text = widget.form.description ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inferred = widget.form.inferredType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.t('description'),
            hintText: l10n.t('postDescriptionHint'),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (v) => widget.onFieldUpdate(
            CreatePostField.description,
            v.trim().isEmpty ? null : v,
          ),
        ),
        const SizedBox(height: 16),
        CreatePostCategorySelector(
          form: widget.form,
          onCategorySelected: (id, name) {
            // Update UUID first (also clears display name when id == null).
            widget.onFieldUpdate(CreatePostField.categoryId, id);
            // Then update the display name (no-op when id == null because
            // the previous call already cleared it via clearCategory).
            if (id != null) {
              widget.onFieldUpdate(CreatePostField.category, name);
            }
          },
        ),
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
