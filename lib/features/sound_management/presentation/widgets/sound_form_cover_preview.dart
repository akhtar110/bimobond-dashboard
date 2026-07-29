import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Compact cover/image preview for the sound create/edit form.
class SoundFormCoverPreview extends StatelessWidget {
  const SoundFormCoverPreview({
    super.key,
    this.previewBytes,
    this.imageUrl,
    this.fileName,
    this.onClear,
    this.enabled = true,
  });

  final Uint8List? previewBytes;
  final String? imageUrl;
  final String? fileName;
  final VoidCallback? onClear;
  final bool enabled;

  bool get hasImage {
    if (previewBytes != null && previewBytes!.isNotEmpty) return true;
    final url = imageUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasImage) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 72,
            height: 72,
            color: scheme.surfaceContainerHighest,
            child: previewBytes != null
                ? Image.memory(
                    previewBytes!,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fileName != null)
                Text(
                  fileName!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (onClear != null)
                TextButton.icon(
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(l10n.tOr('remove', 'Remove')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
