import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'gift_animation_preview.dart';
import 'gift_dialog_layout.dart';

/// A modern, responsive, and visually stunning animation asset section
/// used in create and edit gift popups.
class GiftAnimationUploadSection extends StatelessWidget {
  const GiftAnimationUploadSection({
    super.key,
    required this.layout,
    required this.hasAnimation,
    required this.uploading,
    this.animationBytes,
    this.animationUrl,
    this.animationName,
    this.animationError,
    this.isActioning = false,
    this.onPickAnimation,
    this.onClearAnimation,
  });

  final GiftDialogLayout layout;
  final bool hasAnimation;
  final bool uploading;
  final Uint8List? animationBytes;
  final String? animationUrl;
  final String? animationName;
  final String? animationError;
  final bool isActioning;
  final VoidCallback? onPickAnimation;
  final VoidCallback? onClearAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAnimation
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          if (hasAnimation)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.tOr('giftAnimationHeader', 'Animation Asset'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      l10n.tOr(
                        'giftAnimationSubtitle',
                        'PAG, Lottie, MP4, WebM, GIF, SWF',
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAnimation && onClearAnimation != null)
                IconButton(
                  tooltip: 'Remove animation',
                  onPressed: isActioning || uploading ? null : onClearAnimation,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          // Error alert banner if upload failed
          if (animationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      animationError!,
                      style: TextStyle(color: scheme.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Body Content Area (Empty Dropzone vs Uploading Loader vs Live Preview Stage)
          if (uploading)
            _buildUploadingStage(context, scheme)
          else if (hasAnimation)
            _buildPreviewStage(context, scheme, l10n)
          else
            _buildEmptyDropzone(context, scheme, l10n),
        ],
      ),
    );
  }

  // Stage 1: Empty Dropzone Card
  Widget _buildEmptyDropzone(
    BuildContext context,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    return InkWell(
      onTap: isActioning || uploading ? null : onPickAnimation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 28,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tOr('uploadAnimationOptional', 'Upload Animation File'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tOr('animationFormatsHint', 'Supports .pag, .json, .lottie, .mp4, .gif'),
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: const [
                _FormatPill(label: 'PAG'),
                _FormatPill(label: 'LOTTIE'),
                _FormatPill(label: 'MP4'),
                _FormatPill(label: 'GIF'),
                _FormatPill(label: 'SWF'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Stage 2: Uploading Progress Ring Stage
  Widget _buildUploadingStage(BuildContext context, ColorScheme scheme) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Uploading animation asset…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            if (animationName != null) ...[
              const SizedBox(height: 2),
              Text(
                animationName!,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Stage 3: Live Preview Stage with Controls Bar
  Widget _buildPreviewStage(
    BuildContext context,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Preview Frame
        SizedBox(
          height: 150,
          child: GiftAnimationPreview(
            key: ValueKey('animation-upload-preview-${animationUrl ?? animationName}'),
            compact: true,
            expandToFill: true,
            bytes: animationBytes,
            networkUrl: animationUrl,
            fileName: animationName ?? animationUrl,
          ),
        ),
        const SizedBox(height: 10),

        // Action Toolbar below preview
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isActioning || uploading ? null : onPickAnimation,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text(
                  l10n.tOr('changeAnimation', 'Change Animation'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: layout.denseOutlinedButtonStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatPill extends StatelessWidget {
  const _FormatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
