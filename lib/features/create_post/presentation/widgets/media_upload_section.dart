import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../bloc/create_post_bloc.dart';
import '../utils/media_file_picker.dart';
import 'create_post_media_filter_sheet.dart';

/// Step 1: attach media locally; upload runs on publish/draft (or explicit [UploadMedia]).
class MediaUploadSection extends StatelessWidget {
  const MediaUploadSection({
    super.key,
    required this.form,
    required this.status,
    required this.isGeneratingThumbnail,
    required this.onFilesPicked,
    required this.onRemove,
    required this.onReorder,
  });

  final CreatePostEntity form;
  final CreatePostStatus status;
  final bool isGeneratingThumbnail;
  final void Function(List<LocalMediaFile> files) onFilesPicked;
  final void Function(String id) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  Future<void> _pickFiles(BuildContext context) async {
    final result = await pickMediaFiles();
    if (result.isEmpty) return;

    final picked = <LocalMediaFile>[];
    for (final file in result) {
      picked.add(
        LocalMediaFile(
          id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          name: file.name,
          bytes: file.bytes,
          mediaType: LocalMediaFile.inferMediaType(file.name),
        ),
      );
    }
    onFilesPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final files = form.localMedia;
    final allUploaded = form.allMediaUploaded && files.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickFiles(context),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(l10n.t('attachMedia')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.t('attachMediaHint'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
          ),
        ),
        if (isGeneratingThumbnail) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.tOr('generatingThumbnail', 'Generating thumbnail…'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
        if (status == CreatePostStatus.mediaUploaded || allUploaded) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                l10n.t('mediaUploadedReady'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.tr('attachedMediaCount', {'count': '${files.length}'}),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('dragToReorderHint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 10),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: onReorder,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final firstVideoId = form.hasVideoMedia
                  ? form.localMedia
                      .firstWhere((item) => item.mediaType == 'VIDEO')
                      .id
                  : null;
              return _MediaListTile(
                key: ValueKey(file.id),
                file: file,
                index: index,
                total: files.length,
                isDark: isDark,
                videoThumbnailBytes: file.id == firstVideoId
                    ? form.thumbnailBytes
                    : null,
                onRemove: () => onRemove(file.id),
                onEditFilter: () => showCreatePostMediaFilterSheet(
                  context: context,
                  file: file,
                ),
                onMoveUp: index > 0
                    ? () => onReorder(index, index - 1)
                    : null,
                onMoveDown: index < files.length - 1
                    ? () => onReorder(index, index + 1)
                    : null,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _MediaListTile extends StatelessWidget {
  const _MediaListTile({
    super.key,
    required this.file,
    required this.index,
    required this.total,
    required this.isDark,
    required this.onRemove,
    required this.onEditFilter,
    this.videoThumbnailBytes,
    this.onMoveUp,
    this.onMoveDown,
  });

  final LocalMediaFile file;
  final int index;
  final int total;
  final bool isDark;
  final Uint8List? videoThumbnailBytes;
  final VoidCallback onRemove;
  final VoidCallback onEditFilter;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final isImage = file.mediaType == 'IMAGE';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: isImage
                    ? buildFilteredImagePreview(
                        bytes: file.bytes,
                        filter: file.filter,
                        fit: BoxFit.cover,
                      )
                    : videoThumbnailBytes != null &&
                            videoThumbnailBytes!.isNotEmpty
                        ? Image.memory(
                            videoThumbnailBytes!,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        child: const Icon(Icons.videocam_rounded, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.mediaType +
                        (file.isUploaded ? ' · ✓' : '') +
                        (file.hasFilter ? ' · ✦' : ''),
                    style: TextStyle(
                      fontSize: 11,
                      color: file.isUploaded
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: context.l10n.t('createPostMediaFilterEdit'),
              onPressed: onEditFilter,
              visualDensity: VisualDensity.compact,
            ),
            if (onMoveUp != null)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                onPressed: onMoveUp,
                visualDensity: VisualDensity.compact,
              ),
            if (onMoveDown != null)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                onPressed: onMoveDown,
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
