import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';

class PostPreviewSection extends StatelessWidget {
  const PostPreviewSection({super.key, required this.form});

  final CreatePostEntity form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (form.localMedia.isEmpty) {
      return Center(
        child: Text(
          l10n.t('previewEmpty'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    final first = form.localMedia.first;
    final isImage = first.mediaType == 'IMAGE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B28) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3344) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: isImage
                  ? Image.memory(first.bytes, fit: BoxFit.cover)
                  : ColoredBox(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 56),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            form.description?.isNotEmpty == true
                ? form.description!
                : '—',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Chip(label: form.type),
              _Chip(label: form.status),
              _Chip(label: form.privacyStatus),
              if (form.category != null) _Chip(label: form.category!),
              if (form.isAuctionable) _Chip(label: 'Auction'),
              if (form.isStory) _Chip(label: 'Story'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
