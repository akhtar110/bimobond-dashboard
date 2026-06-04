import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../utils/post_detail_labels.dart';
import '../post_media_carousel.dart';
import 'post_surface_card.dart';

class PostContentSection extends StatelessWidget {
  const PostContentSection({
    super.key,
    required this.draft,
    required this.isBusy,
    required this.captionController,
    required this.categoryController,
    required this.onCaptionChanged,
    required this.onCategoryChanged,
    required this.onPrivacyChanged,
  });

  final ManagedPostEntity draft;
  final bool isBusy;
  final TextEditingController captionController;
  final TextEditingController categoryController;
  final VoidCallback onCaptionChanged;
  final VoidCallback onCategoryChanged;
  final ValueChanged<String> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostSurfaceCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PostMediaCarousel(post: draft, height: 400),
          ),
        ),
        const SizedBox(height: 16),
        PostSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('postInformation'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                maxLines: 4,
                enabled: !isBusy,
                onChanged: (_) => onCaptionChanged(),
                decoration: InputDecoration(
                  labelText: l10n.t('caption'),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                enabled: !isBusy,
                onChanged: (_) => onCategoryChanged(),
                decoration: InputDecoration(
                  labelText: l10n.t('categoryName'),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: const ['PUBLIC', 'PRIVATE', 'FRIENDS']
                        .contains(draft.privacyStatus)
                    ? draft.privacyStatus
                    : 'PUBLIC',
                decoration: InputDecoration(
                  labelText: l10n.t('privacy'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const ['PUBLIC', 'PRIVATE', 'FRIENDS']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(privacyLabel(l10n, v)),
                      ),
                    )
                    .toList(),
                onChanged: isBusy ? null : (v) => v != null ? onPrivacyChanged(v) : null,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('postTimestamps', {
                  'created': DateFormat('MMM dd, yyyy · HH:mm')
                      .format(draft.createdAt),
                  'updated': DateFormat('MMM dd, yyyy · HH:mm')
                      .format(draft.updatedAt),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.t('status')}: ${postStatusLabel(l10n, draft.status)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
