import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/post_video_controls_overlay.dart';
import '../../domain/entities/create_post_media_filter_entity.dart';
import '../../domain/services/create_post_media_filter_service.dart';
import '../utils/create_post_video_css_filter.dart';
import '../utils/create_post_video_source.dart';

/// Inline preview for a locally picked video file (web blob URL).
///
/// On web, library/custom color filters are applied via CSS `feColorMatrix`
/// because [ColorFiltered] cannot tint HTML `<video>` platform views.
class CreatePostLocalVideoPreview extends StatefulWidget {
  const CreatePostLocalVideoPreview({
    super.key,
    required this.bytes,
    required this.fileName,
    this.filter = CreatePostMediaFilterEntity.neutral,
  });

  final List<int> bytes;
  final String fileName;
  final CreatePostMediaFilterEntity filter;

  @override
  State<CreatePostLocalVideoPreview> createState() =>
      _CreatePostLocalVideoPreviewState();
}

class _CreatePostLocalVideoPreviewState
    extends State<CreatePostLocalVideoPreview> {
  static const _filterService = CreatePostMediaFilterService();

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
      _syncWebCssFilter();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(CreatePostLocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _syncWebCssFilter();
    }
  }

  void _syncWebCssFilter() {
    final uri = _objectUrl;
    if (uri == null || !kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final matrices = _filterService.colorMatricesFor(widget.filter);
      if (matrices.isEmpty) {
        clearCssColorFilterForVideoUrl(uri);
      } else {
        applyCssColorMatricesToVideoUrl(uri, matrices);
      }
    });
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
    if (mounted) {
      setState(() {});
      _syncWebCssFilter();
    }
  }

  @override
  void dispose() {
    final uri = _objectUrl;
    if (uri != null) {
      clearCssColorFilterForVideoUrl(uri);
      disposeVideoPreviewUri(uri);
    }
    _controller?.dispose();
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

    Widget video = Center(
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
    );

    // Native / desktop texture videos still respond to ColorFiltered.
    if (!kIsWeb && !widget.filter.isNeutral) {
      video = _filterService.buildFilteredPreview(
        child: video,
        filter: widget.filter,
      );
    }

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          video,
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
