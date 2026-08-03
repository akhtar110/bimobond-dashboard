import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gift_type.dart';
import '../utils/gift_publisher_name.dart';
import '../utils/gift_schedule_label.dart';
import 'edit_gift_dialog.dart';
import 'gift_animation_preview.dart';
import 'gift_audio_preview.dart';
import 'gift_color_picker_field.dart';
import 'gift_thumbnail_image.dart';

/// Shows a responsive, high-end, professional preview dialog for a [GiftEntity].
/// Supports both image gifts (with optional PAG/Lottie/MP4 animation)
/// and audio gifts (with hero visualizer and playable audio controls).
void showGiftPreviewModal(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => GiftPreviewDialog(pageContext: pageContext, gift: gift),
  );
}

class GiftPreviewDialog extends StatefulWidget {
  const GiftPreviewDialog({
    super.key,
    required this.pageContext,
    required this.gift,
  });

  final BuildContext pageContext;
  final GiftEntity gift;

  @override
  State<GiftPreviewDialog> createState() => _GiftPreviewDialogState();
}

class _GiftPreviewDialogState extends State<GiftPreviewDialog> {
  int _selectedMediaTab = 0; // 0: Animation, 1: Thumbnail (when both exist)

  static const _thumbnailPreviewHeight = 240.0;
  static const _animationPreviewHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gift = widget.gift;
    final isAudio = gift.type == GiftType.audio;

    final hasAnimation =
        !isAudio &&
        gift.animationUrl != null &&
        gift.animationUrl!.trim().isNotEmpty;
    final hasAudio =
        isAudio && gift.audioUrl != null && gift.audioUrl!.trim().isNotEmpty;

    final schedule = giftScheduleLabelFor(l10n, gift);
    final customColor = parseGiftHex(gift.color);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final dialogWidth = isWide
              ? (constraints.maxWidth * 0.82).clamp(680.0, 840.0)
              : constraints.maxWidth * 0.96;

          return Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Bar ---
                  _buildHeader(context, gift, isAudio, schedule),

                  const Divider(height: 1, thickness: 1),

                  // --- Body Content ---
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Showcase Column
                                Expanded(
                                  flex: isAudio ? 5 : 5,
                                  child: _buildMediaColumn(
                                    context,
                                    gift,
                                    isAudio,
                                    hasAnimation,
                                    hasAudio,
                                    customColor,
                                    isWide,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Right Details Column
                                Expanded(
                                  flex: isAudio ? 6 : 6,
                                  child: _buildDetailsColumn(
                                    context,
                                    gift,
                                    schedule,
                                    customColor,
                                    isAudio,
                                    hasAnimation,
                                    hasAudio,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMediaColumn(
                                  context,
                                  gift,
                                  isAudio,
                                  hasAnimation,
                                  hasAudio,
                                  customColor,
                                  isWide,
                                ),
                                const SizedBox(height: 20),
                                _buildDetailsColumn(
                                  context,
                                  gift,
                                  schedule,
                                  customColor,
                                  isAudio,
                                  hasAnimation,
                                  hasAudio,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const Divider(height: 1, thickness: 1),

                  // --- Footer Actions ---
                  _buildFooter(context, gift, l10n),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Header Bar with Title, Badges and Close Button
  Widget _buildHeader(
    BuildContext context,
    GiftEntity gift,
    bool isAudio,
    GiftScheduleLabel schedule,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final typeGradient = isAudio
        ? const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF00BCD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest),
      child: Row(
        children: [
          // Icon Avatar Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: typeGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isAudio ? Colors.pink : Colors.indigo).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isAudio ? Icons.graphic_eq_rounded : Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Active / Inactive Status Badge
                    _StatusBadge(
                      label: gift.isActive ? 'Active' : 'Inactive',
                      color: gift.isActive
                          ? const Color(0xFF10B981)
                          : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      icon: gift.isActive
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_outline_rounded,
                    ),
                    // Type Badge
                    _StatusBadge(
                      label: isAudio ? 'Audio Gift' : 'Image Gift',
                      color: isAudio ? scheme.secondary : scheme.primary,
                      icon: isAudio
                          ? Icons.audiotrack_rounded
                          : Icons.image_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Close Icon Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Left Column: Responsive Media Showcase (Audio Visualizer or Image/Animation)
  Widget _buildMediaColumn(
    BuildContext context,
    GiftEntity gift,
    bool isAudio,
    bool hasAnimation,
    bool hasAudio,
    Color? customColor,
    bool isWide,
  ) {
    if (isAudio) {
      return _buildAudioHeroShowcase(context, gift, hasAudio, customColor);
    } else {
      return _buildImageHeroShowcase(context, gift, hasAnimation, customColor);
    }
  }

  // Hero Showcase for Audio Gifts
  Widget _buildAudioHeroShowcase(
    BuildContext context,
    GiftEntity gift,
    bool hasAudio,
    Color? customColor,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heroBgColor = customColor ?? scheme.secondaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visualizer / Album Art Hero Card
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                heroBgColor,
                heroBgColor.withValues(alpha: 0.7),
                scheme.surfaceContainerHigh,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: heroBgColor.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            children: [
              // Subtle background music wave pattern
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.12,
                    child: Icon(
                      Icons.equalizer_rounded,
                      size: 140,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Center Album Art or Vinyl Disk Icon
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gift.thumbnailUrl.isNotEmpty) ...[
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: ClipOval(
                          child: GiftThumbnailImage(
                            networkUrl: gift.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: _audioPlaceholder(scheme),
                            errorWidget: _audioPlaceholder(scheme),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'PLAYABLE AUDIO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Audio Player Controls
        GiftAudioPreview(
          key: const ValueKey('gift-audio-preview-hero'),
          networkUrl: gift.audioUrl,
          fileName: gift.audioUrl,
          compact: false,
          autoPlay: hasAudio,
        ),
      ],
    );
  }

  // Placeholder for audio image
  Widget _audioPlaceholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.audiotrack_rounded, size: 36, color: Colors.white70),
      ),
    );
  }

  // Hero Showcase for Image Gifts (Thumbnail & Animation)
  Widget _buildImageHeroShowcase(
    BuildContext context,
    GiftEntity gift,
    bool hasAnimation,
    Color? customColor,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab selector if both image and animation exist
        if (hasAnimation) ...[
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMediaTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedMediaTab == 0
                            ? scheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedMediaTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.animation_rounded,
                            size: 16,
                            color: _selectedMediaTab == 0
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live Animation',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: _selectedMediaTab == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedMediaTab == 0
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMediaTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedMediaTab == 1
                            ? scheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedMediaTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_rounded,
                            size: 16,
                            color: _selectedMediaTab == 1
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Thumbnail',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: _selectedMediaTab == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedMediaTab == 1
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Media Frame Display
        if (!hasAnimation || _selectedMediaTab == 1) ...[
          // Static Image Preview Frame
          Container(
            height: _thumbnailPreviewHeight,
            decoration: _imagePreviewFrameDecoration(scheme, customColor),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              clipBehavior: kIsWeb ? Clip.none : Clip.antiAlias,
              child: gift.thumbnailUrl.isNotEmpty
                  ? GiftThumbnailImage(
                      key: ValueKey('preview-gift-img-${gift.thumbnailUrl}'),
                      networkUrl: gift.thumbnailUrl,
                      fit: BoxFit.contain,
                      placeholder: _imagePlaceholder(scheme),
                      errorWidget: _imagePlaceholder(scheme),
                    )
                  : _imagePlaceholder(scheme),
            ),
          ),
        ] else ...[
          // Animation — border hugs full-bleed media (no inner padding / letterbox gap)
          Container(
            height: _animationPreviewHeight,
            clipBehavior: Clip.antiAlias,
            decoration: _animationPreviewFrameDecoration(scheme, customColor),
            child: GiftAnimationPreview(
              key: const ValueKey('preview-gift-animation-tab'),
              showChrome: false,
              expandToFill: true,
              clipBorderRadius: 16,
              networkUrl: gift.animationUrl,
              fileName: gift.animationUrl,
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _imagePreviewFrameDecoration(
    ColorScheme scheme,
    Color? customColor,
  ) {
    return BoxDecoration(
      color:
          customColor?.withValues(alpha: 0.15) ??
          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color:
            customColor?.withValues(alpha: 0.4) ??
            scheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }

  BoxDecoration _animationPreviewFrameDecoration(
    ColorScheme scheme,
    Color? customColor,
  ) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color:
            customColor?.withValues(alpha: 0.55) ??
            scheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Right Column: Details, Metadata & Resources
  Widget _buildDetailsColumn(
    BuildContext context,
    GiftEntity gift,
    GiftScheduleLabel schedule,
    Color? customColor,
    bool isAudio,
    bool hasAnimation,
    bool hasAudio,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Price Hero Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COIN PRICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB78103),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gift.priceCoins.toStringAsFixed(gift.priceCoins.truncateToDouble() == gift.priceCoins ? 0 : 2)} Coins',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Metadata Chip Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetaChip(
              icon: Icons.aspect_ratio_rounded,
              label: l10n.tOr('giftSizeLabel', 'Size'),
              value: gift.size.apiValue,
            ),
            _MetaChip(
              icon: Icons.local_offer_rounded,
              label: l10n.tOr('giftTag', 'Tag'),
              value: gift.tag ?? l10n.tOr('giftNoTag', 'None'),
              highlight: gift.tag != null,
            ),
            if (gift.color != null && gift.color!.trim().isNotEmpty)
              _MetaChip(
                icon: Icons.palette_rounded,
                label: l10n.tOr('giftColor', 'Color'),
                value: gift.color!,
                swatchColor: customColor,
                onTapCopy: () =>
                    _copyToClipboard(context, gift.color!, 'Color code'),
              ),
            _MetaChip(
              icon: Icons.format_list_numbered_rounded,
              label: l10n.tOr('giftSortOrder', 'Sort Order'),
              value: '#${gift.sortOrder}',
            ),
            _MetaChip(
              icon: Icons.event_rounded,
              label: l10n.tOr('giftFilterPublished', 'Published'),
              value: () {
                final publisher = resolveGiftPublisherName(context, gift);
                if (publisher == null || publisher.isEmpty) {
                  return schedule.text;
                }
                final by = l10n.tOr('by', 'by');
                return '${schedule.text} $by $publisher';
              }(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Resource Links Section (Copyable URLs)
        if (gift.thumbnailUrl.isNotEmpty || hasAnimation || hasAudio) ...[
          Text(
            'RESOURCE URLS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          if (gift.thumbnailUrl.isNotEmpty)
            _UrlCopyTile(
              label: 'Thumbnail URL',
              url: gift.thumbnailUrl,
              icon: Icons.image_outlined,
            ),
          if (hasAnimation)
            _UrlCopyTile(
              label: 'Animation URL',
              url: gift.animationUrl!,
              icon: Icons.animation_outlined,
            ),
          if (hasAudio)
            _UrlCopyTile(
              label: 'Audio URL',
              url: gift.audioUrl!,
              icon: Icons.audiotrack_outlined,
            ),
        ],
      ],
    );
  }

  // Footer Actions (Close & Edit Gift)
  Widget _buildFooter(
    BuildContext context,
    GiftEntity gift,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(l10n.t('close')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showEditGiftDialog(widget.pageContext, gift);
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(l10n.tOr('editGift', 'Edit Gift')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Status pill badge helper
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Meta chip helper for metadata values
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.swatchColor,
    this.onTapCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Color? swatchColor;
  final VoidCallback? onTapCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (swatchColor != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: swatchColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: highlight ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (onTapCopy != null) {
      return InkWell(
        onTap: onTapCopy,
        borderRadius: BorderRadius.circular(10),
        child: child,
      );
    }
    return child;
  }
}

// URL Copy Tile Widget
class _UrlCopyTile extends StatelessWidget {
  const _UrlCopyTile({
    required this.label,
    required this.url,
    required this.icon,
  });

  final String label;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'Copy $label',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
