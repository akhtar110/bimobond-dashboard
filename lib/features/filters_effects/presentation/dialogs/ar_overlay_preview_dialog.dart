import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/ar_overlay_entities.dart';

/// Popup preview for an AR overlay Lottie animation (`lottieUrl`).
Future<void> openArOverlayPreviewDialog(
  BuildContext context, {
  required ArOverlayEntity overlay,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => ArOverlayPreviewDialog(overlay: overlay),
  );
}

class ArOverlayPreviewDialog extends StatelessWidget {
  const ArOverlayPreviewDialog({
    super.key,
    required this.overlay,
  });

  final ArOverlayEntity overlay;

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
    final size = MediaQuery.sizeOf(context);
    final maxWidth = (size.width * 0.92).clamp(280.0, 520.0);
    final maxHeight = (size.height * 0.86).clamp(360.0, 720.0);
    final previewColor = _parseColorHex(overlay.previewColorHex);
    final lottieUrl =
        resolveMediaUrl(overlay.lottieUrl) ?? overlay.lottieUrl.trim();
    final thumbUrl = overlay.thumbnailUrl == null
        ? null
        : (resolveMediaUrl(overlay.thumbnailUrl) ?? overlay.thumbnailUrl!.trim());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width < 480 ? 12 : 24,
        vertical: size.height < 700 ? 16 : 28,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: scheme.shadow.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    if (overlay.emoji != null && overlay.emoji!.isNotEmpty) ...[
                      Text(overlay.emoji!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overlay.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tOr('arOverlayPreviewSubtitle', 'Overlay preview'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.t('close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: previewColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.8),
                        ),
                        image: thumbUrl != null && thumbUrl.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(thumbUrl),
                                fit: BoxFit.cover,
                                opacity: 0.18,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: lottieUrl.isEmpty
                            ? _PreviewFallback(
                                emoji: overlay.emoji,
                                message: l10n.tOr(
                                  'arOverlayPreviewMissingLottie',
                                  'No Lottie URL on this overlay',
                                ),
                              )
                            : Lottie.network(
                                lottieUrl,
                                fit: BoxFit.contain,
                                repeat: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return _PreviewFallback(
                                    emoji: overlay.emoji,
                                    message: l10n.tOr(
                                      'arOverlayPreviewFailed',
                                      'Could not load Lottie preview',
                                    ),
                                    detail: overlay.lottieUrl,
                                  );
                                },
                                frameBuilder: (context, child, composition) {
                                  if (composition == null) {
                                    return Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    );
                                  }
                                  return child;
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${overlay.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.t('close')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({
    this.emoji,
    required this.message,
    this.detail,
  });

  final String? emoji;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null && emoji!.isNotEmpty)
              Text(emoji!, style: const TextStyle(fontSize: 42))
            else
              Icon(
                Icons.layers_outlined,
                size: 40,
                color: scheme.onSurfaceVariant,
              ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (detail != null && detail!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
