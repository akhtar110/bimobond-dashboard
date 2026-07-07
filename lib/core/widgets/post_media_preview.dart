import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'post_video_controls_overlay.dart';

/// Reuses initialized controllers across carousel swipes for the same URL.
class PostVideoControllerCache {
  PostVideoControllerCache._();

  static final PostVideoControllerCache instance = PostVideoControllerCache._();

  final Map<String, _CachedVideoController> _cache = {};

  VideoPlayerController obtain(String url, {bool looping = true}) {
    final existing = _cache[url];
    if (existing != null) {
      existing.refCount++;
      existing.looping = looping;
      if (existing.initialized) {
        existing.controller.setLooping(looping);
      }
      return existing.controller;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    final entry = _CachedVideoController(controller, looping: looping);
    _cache[url] = entry;
    entry.refCount = 1;
    entry.initializeFuture = controller.initialize().then((_) {
      entry.initialized = true;
      controller.setLooping(entry.looping);
    }).catchError((_) {
      entry.failed = true;
    });
    return controller;
  }

  VideoPlayerController? controllerFor(String url) => _cache[url]?.controller;

  bool isInitialized(String url) => _cache[url]?.initialized ?? false;

  Future<void> waitForInitialize(String url) async {
    final entry = _cache[url];
    if (entry?.initializeFuture != null) {
      await entry!.initializeFuture;
    }
  }

  void pauseAll() {
    for (final entry in _cache.values) {
      final controller = entry.controller;
      if (controller.value.isInitialized) {
        controller.pause();
      }
    }
  }

  void release(String url) {
    final entry = _cache[url];
    if (entry == null) return;
    entry.refCount--;
    if (entry.refCount <= 0) {
      entry.controller.dispose();
      _cache.remove(url);
    }
  }
}

class _CachedVideoController {
  _CachedVideoController(this.controller, {this.looping = true});

  final VideoPlayerController controller;
  bool looping;
  int refCount = 0;
  Future<void>? initializeFuture;
  bool initialized = false;
  bool failed = false;
}

class PostMediaPreview extends StatefulWidget {
  const PostMediaPreview({
    super.key,
    required this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.type = 'VIDEO',
    this.height = 360,
    this.autoplay = false,
    this.looping = true,
    this.fit = BoxFit.contain,
    this.showSeekBar = true,
    this.onAspectRatioDetermined,
  });

  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final String type;
  final double height;
  final bool autoplay;
  final bool looping;
  final BoxFit fit;
  final bool showSeekBar;
  final ValueChanged<double>? onAspectRatioDetermined;

  @override
  State<PostMediaPreview> createState() => _PostMediaPreviewState();
}

class _PostMediaPreviewState extends State<PostMediaPreview> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(PostMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl) {
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
    final imageUrl = widget.thumbnailUrl;
    final playUrl = widget.videoUrl?.isNotEmpty == true
        ? widget.videoUrl
        : (widget.hlsUrl?.isNotEmpty == true ? widget.hlsUrl : null);
    final isVideo =
        widget.type.toUpperCase() == 'VIDEO' && playUrl != null;

    if (imageUrl != null && imageUrl.isNotEmpty && !isVideo) {
      _resolvedImageUrl = imageUrl;
      final provider = CachedNetworkImageProvider(imageUrl);
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
  }

  @override
  Widget build(BuildContext context) {
    final playUrl = widget.videoUrl?.isNotEmpty == true
        ? widget.videoUrl
        : (widget.hlsUrl?.isNotEmpty == true ? widget.hlsUrl : null);
    final isVideo =
        widget.type.toUpperCase() == 'VIDEO' && playUrl != null;

    final media = isVideo
        ? PostVideoPreview(
            key: ValueKey(playUrl),
            videoUrl: playUrl,
            autoplay: widget.autoplay,
            looping: widget.looping,
            fit: widget.fit,
            showSeekBar: widget.showSeekBar,
            onAspectRatioDetermined: widget.onAspectRatioDetermined,
          )
        : (_resolvedImageUrl != null
            ? _CachedPostImage(
                imageUrl: _resolvedImageUrl!,
                fit: widget.fit,
                onAspectRatioDetermined: widget.onAspectRatioDetermined,
              )
            : const _MediaFallback());

    if (!widget.height.isFinite) {
      return SizedBox.expand(child: media);
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: media,
    );
  }
}

class PostAttachedSoundPreview extends StatefulWidget {
  const PostAttachedSoundPreview({
    super.key,
    required this.audioUrl,
    this.autoplay = true,
    this.looping = true,
    this.showSeekBar = true,
  });

  final String audioUrl;
  final bool autoplay;
  final bool looping;
  final bool showSeekBar;

  @override
  State<PostAttachedSoundPreview> createState() =>
      _PostAttachedSoundPreviewState();
}

class _PostAttachedSoundPreviewState extends State<PostAttachedSoundPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = PostVideoControllerCache.instance.obtain(
      widget.audioUrl,
      looping: widget.looping,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await PostVideoControllerCache.instance.waitForInitialize(widget.audioUrl);
    if (!mounted) return;
    final value = _controller.value;
    if (value.hasError || !value.isInitialized) {
      setState(() => _failed = true);
      return;
    }
    if (widget.autoplay) {
      await _controller.play();
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void didUpdateWidget(PostAttachedSoundPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      PostVideoControllerCache.instance.release(oldWidget.audioUrl);
      _controller = PostVideoControllerCache.instance.obtain(
        widget.audioUrl,
        looping: widget.looping,
      );
      _initialized = false;
      _failed = false;
      _bootstrap();
      return;
    }

    if (oldWidget.autoplay != widget.autoplay &&
        _controller.value.isInitialized) {
      if (widget.autoplay) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    PostVideoControllerCache.instance.release(widget.audioUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed ||
        !_initialized ||
        !_controller.value.isInitialized ||
        _controller.value.hasError) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PostVideoControlsOverlay(
          controller: _controller,
          enableFullscreen: false,
          showSeekBar: widget.showSeekBar,
        );
      },
    );
  }
}

class PostVideoPreview extends StatefulWidget {
  const PostVideoPreview({
    super.key,
    required this.videoUrl,
    this.autoplay = false,
    this.looping = true,
    this.fit = BoxFit.contain,
    this.showSeekBar = true,
    this.onAspectRatioDetermined,
  });

  final String videoUrl;
  final bool autoplay;
  final bool looping;
  final BoxFit fit;
  final bool showSeekBar;
  final ValueChanged<double>? onAspectRatioDetermined;

  @override
  State<PostVideoPreview> createState() => _PostVideoPreviewState();
}

class _PostVideoPreviewState extends State<PostVideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _aspectRatioReported = false;
  bool _detachedForFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = PostVideoControllerCache.instance.obtain(
      widget.videoUrl,
      looping: widget.looping,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await PostVideoControllerCache.instance.waitForInitialize(widget.videoUrl);
    if (!mounted) return;
    final value = _controller.value;
    if (value.hasError) {
      setState(() => _failed = true);
      return;
    }
    if (!value.isInitialized) {
      setState(() => _failed = true);
      return;
    }
    _reportAspectRatio();
    if (widget.autoplay) {
      await _controller.play();
    }
    if (mounted) setState(() => _initialized = true);
  }

  void _onFullscreenWillOpen() {
    if (!mounted) return;
    setState(() => _detachedForFullscreen = true);
  }

  void _onFullscreenDidClose() {
    if (!mounted) return;
    setState(() => _detachedForFullscreen = false);
    _reattachInlinePlayer();
  }

  Future<void> _reattachInlinePlayer() async {
    if (!_controller.value.isInitialized) return;
    final wasPlaying = _controller.value.isPlaying;
    final position = _controller.value.position;
    await _controller.seekTo(position);
    if (!mounted) return;
    if (wasPlaying) {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  void _reportAspectRatio() {
    if (_aspectRatioReported) return;
    final ratio = _controller.value.aspectRatio;
    if (ratio > 0) {
      _aspectRatioReported = true;
      widget.onAspectRatioDetermined?.call(ratio);
    }
  }

  @override
  void didUpdateWidget(PostVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      PostVideoControllerCache.instance.release(oldWidget.videoUrl);
      _controller = PostVideoControllerCache.instance.obtain(
        widget.videoUrl,
        looping: widget.looping,
      );
      _initialized = false;
      _failed = false;
      _aspectRatioReported = false;
      _bootstrap();
      return;
    }

    if (oldWidget.autoplay != widget.autoplay &&
        _controller.value.isInitialized) {
      if (widget.autoplay) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    PostVideoControllerCache.instance.release(widget.videoUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_failed ||
        !_initialized ||
        !_controller.value.isInitialized ||
        _controller.value.hasError) {
      return const _MediaShimmer();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;

        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: _detachedForFullscreen
                        ? const SizedBox.shrink()
                        : VideoPlayer(
                            _controller,
                            key: ValueKey('inline_${widget.videoUrl}'),
                          ),
                  ),
                ),
              ),
              PostVideoControlsOverlay(
                controller: _controller,
                showSeekBar: widget.showSeekBar,
                onFullscreenWillOpen: _onFullscreenWillOpen,
                onFullscreenDidClose: _onFullscreenDidClose,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CachedPostImage extends StatefulWidget {
  const _CachedPostImage({
    required this.imageUrl,
    required this.fit,
    this.onAspectRatioDetermined,
  });

  final String imageUrl;
  final BoxFit fit;
  final ValueChanged<double>? onAspectRatioDetermined;

  @override
  State<_CachedPostImage> createState() => _CachedPostImageState();
}

class _CachedPostImageState extends State<_CachedPostImage> {
  int _retryGeneration = 0;

  void _retry() {
    setState(() => _retryGeneration++);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: CachedNetworkImage(
        key: ValueKey('${widget.imageUrl}_$_retryGeneration'),
        imageUrl: widget.imageUrl,
        fit: widget.fit,
        width: double.infinity,
        placeholder: (_, __) => const _MediaShimmer(),
        errorWidget: (_, __, ___) => _MediaError(onRetry: _retry),
      ),
    );
  }
}

class _MediaShimmer extends StatefulWidget {
  const _MediaShimmer();

  @override
  State<_MediaShimmer> createState() => _MediaShimmerState();
}

class _MediaShimmerState extends State<_MediaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.lerp(base, highlight, _controller.value)!,
                Color.lerp(highlight, base, _controller.value)!,
              ],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.videocam_off_outlined,
            size: 48, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
