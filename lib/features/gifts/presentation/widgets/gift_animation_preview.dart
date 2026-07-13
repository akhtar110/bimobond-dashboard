import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../create_post/presentation/utils/create_post_video_source.dart';
import '../../../../core/utils/media_url_resolver.dart';

bool giftAnimationLooksLikeVideo(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi');
}

bool giftAnimationLooksLikeImage(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.gif') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}

String? _displayFileName(String? fileName, String? networkUrl) {
  final raw = (fileName != null && fileName.isNotEmpty)
      ? fileName
      : networkUrl;
  if (raw == null || raw.isEmpty) return null;
  final withoutQuery = raw.split('?').first;
  final parts = withoutQuery.split(RegExp(r'[/\\]'));
  return parts.isNotEmpty ? parts.last : withoutQuery;
}

String _formatBadge(String? fileName, String? networkUrl) {
  final name = _displayFileName(fileName, networkUrl)?.toLowerCase() ?? '';
  if (name.endsWith('.mp4')) return 'MP4';
  if (name.endsWith('.webm')) return 'WEBM';
  if (name.endsWith('.mov')) return 'MOV';
  if (giftAnimationLooksLikeImage(name)) return 'IMAGE';
  if (giftAnimationLooksLikeVideo(name)) return 'VIDEO';
  return 'MP4';
}

/// Compact animation preview for gift create/edit dialogs (MP4 / image / placeholder).
class GiftAnimationPreview extends StatelessWidget {
  const GiftAnimationPreview({
    super.key,
    this.bytes,
    this.networkUrl,
    this.fileName,
    this.onClear,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final String? fileName;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = _displayFileName(fileName, networkUrl) ?? 'animation.mp4';
    final badge = _formatBadge(fileName, networkUrl);
    final isVideo = giftAnimationLooksLikeVideo(fileName) ||
        giftAnimationLooksLikeVideo(networkUrl) ||
        (bytes != null &&
            !giftAnimationLooksLikeImage(fileName) &&
            (fileName == null || fileName!.isEmpty));
    final isImage = giftAnimationLooksLikeImage(fileName) ||
        giftAnimationLooksLikeImage(networkUrl);

    Widget preview;
    if (bytes != null && isVideo) {
      preview = _LocalVideoPreview(
        bytes: bytes!,
        fileName: fileName?.isNotEmpty == true ? fileName! : 'animation.mp4',
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty && isVideo) {
      preview = _NetworkVideoPreview(url: networkUrl!);
    } else if (bytes != null && isImage) {
      preview = Image.memory(
        bytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(scheme),
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty && isImage) {
      preview = Image.network(
        resolveMediaUrl(networkUrl) ?? networkUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(scheme),
      );
    } else if (bytes != null) {
      preview = _LocalVideoPreview(
        bytes: bytes!,
        fileName: fileName?.isNotEmpty == true ? fileName! : 'animation.mp4',
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      preview = _NetworkVideoPreview(url: networkUrl!);
    } else {
      preview = _placeholder(scheme);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.animation_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Animation',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                if (onClear != null)
                  IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: scheme.error,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111318),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: preview,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.animation_rounded, size: 34, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            'Animation preview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalVideoPreview extends StatefulWidget {
  const _LocalVideoPreview({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  VideoPlayerController? _controller;
  String? _objectUrl;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _LocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes ||
        oldWidget.fileName != widget.fileName) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    final uri = createVideoPreviewUri(widget.bytes, widget.fileName);
    if (uri == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    _objectUrl = uri;
    final controller = VideoPlayerController.networkUrl(Uri.parse(uri));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    final uri = _objectUrl;
    if (uri != null) disposeVideoPreviewUri(uri);
    _objectUrl = null;
    _ready = false;
    _failed = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GiftVideoSurface(
      controller: _controller,
      ready: _ready,
      failed: _failed,
    );
  }
}

class _NetworkVideoPreview extends StatefulWidget {
  const _NetworkVideoPreview({required this.url});

  final String url;

  @override
  State<_NetworkVideoPreview> createState() => _NetworkVideoPreviewState();
}

class _NetworkVideoPreviewState extends State<_NetworkVideoPreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _NetworkVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _failed = false;
      _init();
    }
  }

  Future<void> _init() async {
    final resolved = resolveMediaUrl(widget.url) ?? widget.url;
    final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GiftVideoSurface(
      controller: _controller,
      ready: _ready,
      failed: _failed,
    );
  }
}

class _GiftVideoSurface extends StatelessWidget {
  const _GiftVideoSurface({
    required this.controller,
    required this.ready,
    required this.failed,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (failed || controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 34,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview unavailable',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    if (!ready || !controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Loading preview…',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller!,
      builder: (context, value, _) {
        final progress = value.duration.inMilliseconds == 0
            ? 0.0
            : (value.position.inMilliseconds / value.duration.inMilliseconds)
                .clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(controller!),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Material(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (value.isPlaying) {
                                  controller!.pause();
                                } else {
                                  controller!.play();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Muted · Loop',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
