import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/post_media_entity.dart';

/// Single slide in [PostMediaCarousel] — image preview or video poster + play affordance.
class MediaCarouselItem extends StatelessWidget {
  const MediaCarouselItem({
    super.key,
    required this.item,
    required this.height,
    this.videoPosterUrl,
    this.onVideoTap,
  });

  final PostMediaEntity item;
  final double height;
  final String? videoPosterUrl;
  final VoidCallback? onVideoTap;

  bool get _isVideo => item.mediaType.toUpperCase() == 'VIDEO';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isVideo) {
      return _VideoSlide(
        height: height,
        posterUrl: videoPosterUrl,
        isDark: isDark,
        onTap: onVideoTap,
      );
    }

    return _ImageSlide(
      height: height,
      imageUrl: item.url,
      isDark: isDark,
    );
  }
}

class _ImageSlide extends StatelessWidget {
  const _ImageSlide({
    required this.height,
    required this.imageUrl,
    required this.isDark,
  });

  final double height;
  final String imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => _MediaPlaceholder(isDark: isDark),
        errorWidget: (_, __, ___) => _MediaPlaceholder(isDark: isDark),
      ),
    );
  }
}

class _VideoSlide extends StatelessWidget {
  const _VideoSlide({
    required this.height,
    required this.posterUrl,
    required this.isDark,
    this.onTap,
  });

  final double height;
  final String? posterUrl;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterUrl != null && posterUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPoster)
              CachedNetworkImage(
                imageUrl: posterUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => _MediaPlaceholder(isDark: isDark),
                errorWidget: (_, __, ___) => _MediaPlaceholder(isDark: isDark),
              )
            else
              _MediaPlaceholder(isDark: isDark),
            ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? const Color(0xFF252B3B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.perm_media_outlined,
          size: 48,
          color: isDark ? Colors.grey.shade700 : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
