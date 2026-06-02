import 'package:flutter/material.dart';

import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_media_entity.dart';
import 'media_carousel_item.dart';

/// Swipeable admin preview for all items in [ManagedPostEntity.media].
class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.post,
    this.height = 320,
  });

  final ManagedPostEntity post;
  final double height;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<PostMediaEntity> get _media => widget.post.media;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(PostMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.media.length != widget.post.media.length) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _videoPosterUrl(int videoIndex) {
    for (var i = 0; i < videoIndex; i++) {
      final prior = _media[i];
      if (prior.mediaType.toUpperCase() == 'IMAGE' && prior.url.isNotEmpty) {
        return prior.url;
      }
    }
    return widget.post.displayThumbnailUrl ?? widget.post.thumbnailUrl;
  }

  void _openVideoPlayer(String videoUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final maxWidth = MediaQuery.sizeOf(ctx).width * 0.92;
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.75;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth.clamp(320, 960),
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PostMediaPreview(
                    thumbnailUrl: widget.post.displayThumbnailUrl,
                    videoUrl: videoUrl,
                    hlsUrl: widget.post.hlsUrl,
                    type: 'VIDEO',
                    height: (maxHeight - 56).clamp(200, 520),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_media.isEmpty) {
      return PostMediaPreview(
        thumbnailUrl: widget.post.displayThumbnailUrl,
        videoUrl: widget.post.videoUrl,
        hlsUrl: widget.post.hlsUrl,
        type: widget.post.type,
        height: widget.height,
      );
    }

    final showIndicators = _media.length > 1;
    final indicatorActive = theme.colorScheme.primary;
    final indicatorInactive = isDark
        ? Colors.grey.shade700
        : theme.colorScheme.outline.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _media.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = _media[index];
                final isVideo = item.mediaType.toUpperCase() == 'VIDEO';

                return MediaCarouselItem(
                  item: item,
                  height: widget.height,
                  videoPosterUrl: isVideo ? _videoPosterUrl(index) : null,
                  onVideoTap: isVideo
                      ? () => _openVideoPlayer(item.url)
                      : null,
                );
              },
            ),
          ),
          if (showIndicators) ...[
            const SizedBox(height: 10),
            _PageIndicators(
              count: _media.length,
              currentIndex: _currentIndex,
              activeColor: indicatorActive,
              inactiveColor: indicatorInactive,
              onDotTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    this.onDotTap,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final void Function(int index)? onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return GestureDetector(
          onTap: onDotTap != null ? () => onDotTap!(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: selected ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}
