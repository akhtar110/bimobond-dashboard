import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/story_viewer_slide.dart';

class StoryViewerMedia extends StatefulWidget {
  const StoryViewerMedia({
    super.key,
    required this.slide,
    this.fit = BoxFit.contain,
  });

  final StoryViewerSlide slide;
  final BoxFit fit;

  @override
  State<StoryViewerMedia> createState() => _StoryViewerMediaState();
}

class _StoryViewerMediaState extends State<StoryViewerMedia> {
  String? _trackedUrl;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _setupMedia();
  }

  @override
  void didUpdateWidget(covariant StoryViewerMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slide.id != widget.slide.id) {
      _releaseController();
      _setupMedia();
    }
  }

  void _setupMedia() {
    final progressUrl = storyProgressMediaUrl(widget.slide);
    if (progressUrl == null) return;

    _trackedUrl = progressUrl;
    _controller = PostVideoControllerCache.instance.obtain(
      progressUrl,
      looping: false,
    );
    PostVideoControllerCache.instance.waitForInitialize(progressUrl).then((_) {
      if (!mounted) return;
      _controller?.play();
      setState(() {});
    });
  }

  void _releaseController() {
    final url = _trackedUrl;
    if (url != null) {
      PostVideoControllerCache.instance.release(url);
    }
    _trackedUrl = null;
    _controller = null;
  }

  @override
  void dispose() {
    _releaseController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final progressUrl = storyProgressMediaUrl(slide);

    if (progressUrl != null) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        final fallback = slide.thumbnailUrl ?? slide.mediaUrl;
        if (fallback != null && fallback.isNotEmpty) {
          return CachedNetworkImage(imageUrl: fallback, fit: widget.fit);
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      return FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    final imageUrl = slide.mediaUrl ?? slide.thumbnailUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: imageUrl, fit: widget.fit);
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 36,
      ),
    );
  }
}
