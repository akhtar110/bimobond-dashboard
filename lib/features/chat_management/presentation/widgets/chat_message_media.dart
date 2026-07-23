import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/localization.dart';

String formatMediaDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

/// Shows the full image without cropping (WhatsApp-style contain fit).
class ChatImageMessage extends StatelessWidget {
  const ChatImageMessage({
    super.key,
    required this.imageUrl,
    this.embedded = false,
    this.bubbleStyle = false,
  });

  final String imageUrl;
  final bool embedded;
  final bool bubbleStyle;

  static const _maxWidth = 320.0;
  static const _maxHeight = 280.0;

  void _openLightbox(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenW = MediaQuery.sizeOf(context).width;
    final maxW = bubbleStyle
        ? math.min(_maxWidth, screenW * 0.72)
        : _maxWidth;
    final maxH = bubbleStyle ? 240.0 : _maxHeight;

    final image = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxW,
        maxHeight: maxH,
        minWidth: bubbleStyle ? math.min(180, maxW) : 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(bubbleStyle ? 14 : 0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: bubbleStyle ? BoxFit.cover : BoxFit.contain,
          width: bubbleStyle ? maxW : null,
          height: bubbleStyle ? null : null,
          placeholder: (_, __) => SizedBox(
            width: embedded ? math.min(200, maxW) : maxW,
            height: embedded ? 140 : 160,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _MediaError(
            icon: Icons.broken_image_outlined,
            label: context.l10n.t('chatMediaLoadFailed'),
          ),
        ),
      ),
    );

    if (embedded || bubbleStyle) {
      return InkWell(onTap: () => _openLightbox(context), child: image);
    }

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLightbox(context),
        child: image,
      ),
    );
  }
}

/// Inline playable video bubble with play/pause and progress (WhatsApp-style).
class ChatVideoMessage extends StatefulWidget {
  const ChatVideoMessage({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<ChatVideoMessage> createState() => _ChatVideoMessageState();
}

class _ChatVideoMessageState extends State<ChatVideoMessage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  static const _maxWidth = 320.0;
  static const _maxHeight = 280.0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(ChatVideoMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initController();
    }
  }

  void _initController() {
    _initialized = false;
    _hasError = false;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted || _controller != controller) return;
      controller.setLooping(false);
      controller.addListener(_onTick);
      setState(() => _initialized = true);
    }).catchError((_) {
      if (!mounted || _controller != controller) return;
      setState(() => _hasError = true);
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _disposeController() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    _initialized = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void _seek(double value) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    controller.seekTo(Duration(milliseconds: (value * duration.inMilliseconds).round()));
  }

  Size _videoSize(double aspectRatio) {
    var width = _maxWidth;
    var height = width / aspectRatio;
    if (height > _maxHeight) {
      height = _maxHeight;
      width = height * aspectRatio;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;

    if (_hasError || controller == null) {
      return _MediaError(
        icon: Icons.videocam_off_outlined,
        label: l10n.t('chatMediaLoadFailed'),
      );
    }

    if (!_initialized || !controller.value.isInitialized) {
      return SizedBox(
        width: _maxWidth,
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    final value = controller.value;
    final size = _videoSize(value.aspectRatio);
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return SizedBox(
      width: size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _togglePlayback,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: value.size.width,
                          height: value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    ),
                    if (!value.isPlaying)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.scrim.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          Text(
                            formatMediaDuration(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatMediaDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seek,
              activeColor: scheme.primary,
              inactiveColor: scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ensures only one chat audio bubble plays at a time (WhatsApp-style).
class _ChatAudioPlaybackHub {
  _ChatAudioPlaybackHub._();

  static VideoPlayerController? _active;

  static Future<void> play(VideoPlayerController controller) async {
    final previous = _active;
    if (previous != null &&
        !identical(previous, controller) &&
        previous.value.isInitialized) {
      try {
        await previous.pause();
      } on Object {
        // Previous controller may already be disposed.
      }
    }
    _active = controller;
    await controller.play();
  }

  static Future<void> pause(VideoPlayerController controller) async {
    if (controller.value.isInitialized) {
      await controller.pause();
    }
    if (identical(_active, controller)) {
      _active = null;
    }
  }

  static void detach(VideoPlayerController controller) {
    if (identical(_active, controller)) {
      _active = null;
    }
  }
}

/// Inline playable audio bubble with play/pause and scrubber (WhatsApp-style).
class ChatAudioMessage extends StatefulWidget {
  const ChatAudioMessage({
    super.key,
    required this.audioUrl,
    this.embedded = false,
  });

  final String audioUrl;
  final bool embedded;

  @override
  State<ChatAudioMessage> createState() => _ChatAudioMessageState();
}

class _ChatAudioMessageState extends State<ChatAudioMessage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(ChatAudioMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _disposeController();
      _initController();
    }
  }

  void _initController() {
    _initialized = false;
    _hasError = false;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.audioUrl),
    );
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted || _controller != controller) return;
      controller.setLooping(false);
      controller.addListener(_onTick);
      setState(() => _initialized = true);
    }).catchError((_) {
      if (!mounted || _controller != controller) return;
      setState(() => _hasError = true);
    });
  }

  void _onTick() {
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying &&
        identical(_ChatAudioPlaybackHub._active, controller) &&
        controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      _ChatAudioPlaybackHub.detach(controller);
    }
    if (mounted) setState(() {});
  }

  void _disposeController() {
    final controller = _controller;
    if (controller != null) {
      _ChatAudioPlaybackHub.detach(controller);
      controller.removeListener(_onTick);
      controller.dispose();
    }
    _controller = null;
    _initialized = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await _ChatAudioPlaybackHub.pause(controller);
    } else {
      await _ChatAudioPlaybackHub.play(controller);
    }
    if (mounted) setState(() {});
  }

  void _seek(double value) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    controller.seekTo(Duration(milliseconds: (value * duration.inMilliseconds).round()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;

    if (_hasError || controller == null) {
      return _MediaError(
        icon: Icons.mic_off_outlined,
        label: l10n.t('chatMediaLoadFailed'),
      );
    }

    if (!_initialized || !controller.value.isInitialized) {
      return SizedBox(
        width: math.min(MediaQuery.sizeOf(context).width * 0.72, 280),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
      );
    }

    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;
    final isPlaying = value.isPlaying;
    final displayDuration =
        isPlaying || position > Duration.zero ? position : duration;

    final player = Row(
      children: [
        Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _togglePlayback,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: scheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seek,
              activeColor: scheme.primary,
              inactiveColor: scheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          formatMediaDuration(displayDuration),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );

    if (widget.embedded) {
      return SizedBox(
        width: math.min(MediaQuery.sizeOf(context).width * 0.68, 280),
        child: player,
      );
    }

    return Container(
      width: math.min(MediaQuery.sizeOf(context).width * 0.72, 320),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: player,
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
