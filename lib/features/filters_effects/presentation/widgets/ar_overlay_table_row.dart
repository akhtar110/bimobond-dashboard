import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/ar_overlay_entities.dart';

class ArOverlayTableRow extends StatelessWidget {
  const ArOverlayTableRow({
    super.key,
    required this.overlay,
    this.onPreview,
    this.onEdit,
    this.onDelete,
  });

  final ArOverlayEntity overlay;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _parseColorHex(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const Color(0xFF1E88E5);
    }
    var clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(val) : const Color(0xFF1E88E5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = _parseColorHex(overlay.previewColorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Avatar / Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: overlay.thumbnailUrl != null && overlay.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: overlay.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _fallbackAvatar(overlay, color),
                  )
                : _fallbackAvatar(overlay, color),
          ),
          const SizedBox(width: 14),

          // Title & ID
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (overlay.emoji != null && overlay.emoji!.isNotEmpty) ...[
                      Text(overlay.emoji!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        overlay.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${overlay.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),

          // Sort Order Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Sort: #${overlay.sortOrder}',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Lottie Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.animation_rounded, size: 13, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  'Lottie',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Action Buttons
          if (onPreview != null)
            IconButton(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: l10n.tOr('previewOverlay', 'Preview overlay'),
            ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              tooltip: l10n.t('edit'),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: scheme.error,
              ),
              tooltip: l10n.t('delete'),
            ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(ArOverlayEntity overlay, Color color) {
    if (overlay.emoji != null && overlay.emoji!.isNotEmpty) {
      return Center(
        child: Text(overlay.emoji!, style: const TextStyle(fontSize: 20)),
      );
    }
    return Center(
      child: Icon(Icons.layers_outlined, size: 20, color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}
