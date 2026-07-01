import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/post_media_entity.dart';

/// Single slide in [PostMediaCarousel] — image preview or inline video.
class MediaCarouselItem extends StatefulWidget {
  const MediaCarouselItem({
    super.key,
    required this.item,
    required this.height,
    this.hlsUrl,
    this.fit = BoxFit.contain,
    this.isActive = false,
    this.onAspectRatioDetermined,
  });

  final PostMediaEntity item;
  final double height;
  final String? hlsUrl;
  final BoxFit fit;
  final bool isActive;
  final ValueChanged<double>? onAspectRatioDetermined;

  @override
  State<MediaCarouselItem> createState() => _MediaCarouselItemState();
}

class _MediaCarouselItemState extends State<MediaCarouselItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.item.isVideo) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: PostMediaPreview(
          thumbnailUrl: null,
          videoUrl: widget.item.url,
          hlsUrl: widget.hlsUrl,
          type: 'VIDEO',
          height: widget.height,
          autoplay: widget.isActive,
          fit: widget.fit,
          onAspectRatioDetermined: widget.onAspectRatioDetermined,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return _ImageSlide(
      height: widget.height,
      imageUrl: widget.item.url,
      fit: widget.fit,
      backgroundColor: scheme.surfaceContainerHighest,
      onAspectRatioDetermined: widget.onAspectRatioDetermined,
    );
  }
}

class _ImageSlide extends StatefulWidget {
  const _ImageSlide({
    required this.height,
    required this.imageUrl,
    required this.fit,
    required this.backgroundColor,
    this.onAspectRatioDetermined,
  });

  final double height;
  final String imageUrl;
  final BoxFit fit;
  final Color backgroundColor;
  final ValueChanged<double>? onAspectRatioDetermined;

  @override
  State<_ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<_ImageSlide>
    with AutomaticKeepAliveClientMixin {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  int _retryGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(_ImageSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _cleanupStream();
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _cleanupStream();
    super.dispose();
  }

  void _cleanupStream() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
  }

  void _resolveImage() {
    if (widget.imageUrl.isEmpty) return;
    final provider = CachedNetworkImageProvider(widget.imageUrl);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageListener = ImageStreamListener((ImageInfo info, bool _) {
      if (!mounted) return;
      final width = info.image.width;
      final height = info.image.height;
      if (width > 0 && height > 0) {
        widget.onAspectRatioDetermined?.call(width / height);
      }
    });
    _imageStream!.addListener(_imageListener!);
  }

  void _retry() {
    setState(() => _retryGeneration++);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: CachedNetworkImage(
          key: ValueKey('${widget.imageUrl}_$_retryGeneration'),
          imageUrl: widget.imageUrl,
          fit: widget.fit,
          width: double.infinity,
          height: widget.height,
          memCacheHeight: (widget.height * 2).round(),
          placeholder: (_, __) => ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 40, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
