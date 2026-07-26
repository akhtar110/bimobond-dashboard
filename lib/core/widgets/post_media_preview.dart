import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/media_url_resolver.dart';
import 'post_video_controls_overlay.dart';

/// Reuses initialized controllers across carousel swipes for the same URL.
class PostVideoControllerCache {
  PostVideoControllerCache._();

  static final PostVideoControllerCache instance = PostVideoControllerCache._();

  final Map<String, _CachedVideoController> _cache = {};

  /// Playback groups so post video + attached sound pause/play together.
  final Map<String, Set<String>> _playbackGroups = {};

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

    // mixWithOthers lets muted post video keep playing while attached sound
    // uses a second controller for audio.
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
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

  String? urlFor(VideoPlayerController controller) {
    for (final entry in _cache.entries) {
      if (identical(entry.value.controller, controller)) return entry.key;
    }
    return null;
  }

  bool isInitialized(String url) => _cache[url]?.initialized ?? false;

  Future<void> waitForInitialize(String url) async {
    final entry = _cache[url];
    if (entry?.initializeFuture != null) {
      await entry!.initializeFuture;
    }
  }

  /// Links video + attached-sound URLs so play/pause stays in sync.
  void linkPlayback(String urlA, String urlB) {
    final a = urlA.trim();
    final b = urlB.trim();
    if (a.isEmpty || b.isEmpty || a == b) return;
    final group = <String>{
      ...(_playbackGroups[a] ?? {a}),
      ...(_playbackGroups[b] ?? {b}),
      a,
      b,
    };
    for (final url in group) {
      _playbackGroups[url] = group;
    }
  }

  void unlinkPlayback(String url) {
    final group = _playbackGroups[url];
    if (group == null) return;
    for (final member in group) {
      _playbackGroups.remove(member);
    }
  }

  void pauseGroup(String url) {
    for (final member in _playbackGroups[url] ?? {url}) {
      final controller = _cache[member]?.controller;
      if (controller != null && controller.value.isInitialized) {
        controller.pause();
      }
    }
  }

  void playGroup(String url) {
    for (final member in _playbackGroups[url] ?? {url}) {
      final controller = _cache[member]?.controller;
      if (controller != null && controller.value.isInitialized) {
        controller.play();
      }
    }
  }

  /// Returns `true` when the group is playing after the toggle.
  bool toggleGroup(String url) {
    final controller = _cache[url]?.controller;
    if (controller == null || !controller.value.isInitialized) {
      return false;
    }
    if (controller.value.isPlaying) {
      pauseGroup(url);
      return false;
    }
    playGroup(url);
    return true;
  }

  /// Play/pause using a controller instance (resolves its cached URL).
  bool toggleGroupForController(VideoPlayerController controller) {
    final url = urlFor(controller);
    if (url == null) {
      if (controller.value.isInitialized) {
        if (controller.value.isPlaying) {
          controller.pause();
          return false;
        }
        controller.play();
        return true;
      }
      return false;
    }
    return toggleGroup(url);
  }

  void pauseAll() {
    for (final entry in _cache.values) {
      final controller = entry.controller;
      if (controller.value.isInitialized) {
        controller.pause();
      }
    }
  }

  /// Re-starts muted video controllers after attached sound begins playing.
  /// Skips [exceptUrl] (the sound controller itself).
  void resumeMutedExcept(String exceptUrl) {
    for (final entry in _cache.entries) {
      if (entry.key == exceptUrl) continue;
      final controller = entry.value.controller;
      if (!controller.value.isInitialized) continue;
      if (controller.value.volume > 0) continue;
      if (controller.value.isPlaying) continue;
      controller.play();
    }
  }

  void release(String url) {
    final entry = _cache[url];
    if (entry == null) return;
    entry.refCount--;
    if (entry.refCount <= 0) {
      entry.controller.dispose();
      _cache.remove(url);
      // Playback groups are owned by the media carousel, not ref-counts.
      _playbackGroups.remove(url);
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
    this.muted = false,
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
  /// When true, video plays silently (e.g. attached post sound is used instead).
  final bool muted;
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
            muted: widget.muted,
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

/// Compact always-visible sound player (play/pause + progress) for attached
/// post sounds over image / video / carousel previews.
///
/// Uses [VideoPlayerController] (same path as sound management previews) so
/// CDN audio loads reliably. Post video stays muted when this is active.
class PostAttachedSoundPreview extends StatefulWidget {
  const PostAttachedSoundPreview({
    super.key,
    required this.audioUrl,
    this.title,
    this.autoplay = true,
    this.looping = true,
    this.showSeekBar = true,
  });

  final String audioUrl;
  final String? title;
  final bool autoplay;
  final bool looping;
  final bool showSeekBar;

  @override
  State<PostAttachedSoundPreview> createState() =>
      _PostAttachedSoundPreviewState();
}

class _PostAttachedSoundPreviewState extends State<PostAttachedSoundPreview> {
  VideoPlayerController? _controller;
  String? _resolvedUrl;
  bool _initialized = false;
  bool _failed = false;
  double? _dragPositionMs;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  String? _resolvePlayUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return resolveMediaUrl(trimmed) ?? trimmed;
  }

  Future<void> _bootstrap() async {
    final generation = ++_loadGeneration;
    final playUrl = _resolvePlayUrl(widget.audioUrl);
    if (kDebugMode) {
      debugPrint(
        '[PostAttachedSoundPreview] Initializing audioUrl: ${widget.audioUrl} → $playUrl',
      );
    }
    if (playUrl == null || playUrl.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    // Release previous controller if URL changed mid-flight.
    final previousUrl = _resolvedUrl;
    if (previousUrl != null && previousUrl != playUrl) {
      PostVideoControllerCache.instance.release(previousUrl);
      _controller = null;
    }

    _resolvedUrl = playUrl;
    final controller = PostVideoControllerCache.instance.obtain(
      playUrl,
      looping: widget.looping,
    );
    _controller = controller;

    await PostVideoControllerCache.instance.waitForInitialize(playUrl);
    if (!mounted || generation != _loadGeneration) return;

    final value = controller.value;
    if (value.hasError || !value.isInitialized) {
      if (kDebugMode) {
        debugPrint(
          '[PostAttachedSoundPreview] Init failed: ${value.errorDescription}',
        );
      }
      setState(() => _failed = true);
      return;
    }

    try {
      await controller.setVolume(1);
      if (widget.autoplay) {
        await controller.play();
        // Sound and muted post video can coexist; restore video if the
        // platform paused it when the sound controller started.
        PostVideoControllerCache.instance.resumeMutedExcept(playUrl);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PostAttachedSoundPreview] Play failed: $e');
      }
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
      return;
    }

    if (mounted && generation == _loadGeneration) {
      setState(() {
        _initialized = true;
        _failed = false;
      });
    }
  }

  @override
  void didUpdateWidget(PostAttachedSoundPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      setState(() {
        _initialized = false;
        _failed = false;
        _dragPositionMs = null;
      });
      _bootstrap();
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (oldWidget.autoplay != widget.autoplay) {
      if (widget.autoplay) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    final url = _resolvedUrl;
    if (url != null) {
      PostVideoControllerCache.instance.release(url);
    }
    super.dispose();
  }

  String _format(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final url = _resolvedUrl;
    if (url != null) {
      PostVideoControllerCache.instance.toggleGroup(url);
    } else if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;

    if (_failed) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.errorContainer.withValues(alpha: 0.92),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.music_off_rounded,
                    size: 18, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sound failed to load',
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading sound…',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final value = controller.value;
          final durationMs = value.duration.inMilliseconds;
          final positionMs =
              _dragPositionMs ?? value.position.inMilliseconds.toDouble();
          final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
          final title = widget.title?.trim();

          return Material(
            color: Colors.black.withValues(alpha: 0.72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        tooltip: value.isPlaying ? 'Pause sound' : 'Play sound',
                      ),
                      Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (title != null && title.isNotEmpty)
                              ? title
                              : 'Original sound',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_format(Duration(milliseconds: positionMs.round()))}'
                        ' / ${_format(value.duration)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (widget.showSeekBar)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: scheme.primary,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.28),
                        thumbColor: scheme.primary,
                        overlayColor: scheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: positionMs.clamp(0, maxMs),
                        max: maxMs,
                        onChanged: (v) => setState(() => _dragPositionMs = v),
                        onChangeEnd: (v) async {
                          await controller.seekTo(
                            Duration(milliseconds: v.round()),
                          );
                          if (mounted) {
                            setState(() => _dragPositionMs = null);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
    this.muted = false,
    this.onAspectRatioDetermined,
  });

  final String videoUrl;
  final bool autoplay;
  final bool looping;
  final BoxFit fit;
  final bool showSeekBar;
  final bool muted;
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
    await _applyMute();
    if (widget.autoplay) {
      await _controller.play();
    }
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _applyMute() async {
    if (!_controller.value.isInitialized) return;
    await _controller.setVolume(widget.muted ? 0 : 1);
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
    await _applyMute();
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

    if (oldWidget.muted != widget.muted) {
      _applyMute();
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
                onTogglePlayPause: () => PostVideoControllerCache.instance
                    .toggleGroupForController(_controller),
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
