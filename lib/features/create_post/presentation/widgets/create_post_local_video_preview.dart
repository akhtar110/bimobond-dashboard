import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/post_video_controls_overlay.dart';
import '../utils/create_post_video_source.dart';

/// Inline preview for a locally picked video file (web blob URL).
class CreatePostLocalVideoPreview extends StatefulWidget {
  const CreatePostLocalVideoPreview({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;

  @override
  State<CreatePostLocalVideoPreview> createState() =>
      _CreatePostLocalVideoPreviewState();
}

class _CreatePostLocalVideoPreviewState
    extends State<CreatePostLocalVideoPreview> {
  VideoPlayerController? _controller;
  String? _objectUrl;
  bool _ready = false;
  bool _failed = false;
  bool _detachedForFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final uri = createVideoPreviewUri(
      Uint8List.fromList(widget.bytes),
      widget.fileName,
    );
    if (uri == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    _objectUrl = uri;
    final controller = VideoPlayerController.networkUrl(Uri.parse(uri));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onFullscreenWillOpen() {
    if (!mounted) return;
    setState(() => _detachedForFullscreen = true);
  }

  void _onFullscreenDidClose() {
    if (!mounted) return;
    setState(() => _detachedForFullscreen = false);
    _reattachPlayer();
  }

  Future<void> _reattachPlayer() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final wasPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    await controller.seekTo(position);
    if (!mounted) return;
    if (wasPlaying) {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    final uri = _objectUrl;
    if (uri != null) {
      disposeVideoPreviewUri(uri);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (_failed || _controller == null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('videoPreviewUnavailable'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_ready || !_controller!.value.isInitialized) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final controller = _controller!;
    final value = controller.value;

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: value.size.width,
                height: value.size.height,
                child: _detachedForFullscreen
                    ? const SizedBox.shrink()
                    : VideoPlayer(
                        controller,
                        key: ValueKey('create_post_${widget.fileName}'),
                      ),
              ),
            ),
          ),
          PostVideoControlsOverlay(
            controller: controller,
            onFullscreenWillOpen: _onFullscreenWillOpen,
            onFullscreenDidClose: _onFullscreenDidClose,
          ),
        ],
      ),
    );
  }
}
