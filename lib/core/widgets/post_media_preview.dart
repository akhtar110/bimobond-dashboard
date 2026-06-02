import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostMediaPreview extends StatelessWidget {
  const PostMediaPreview({
    super.key,
    required this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.type = 'VIDEO',
    this.height = 360,
  });

  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final String type;
  final double height;

  String? get _playUrl {
    if (videoUrl != null && videoUrl!.isNotEmpty) return videoUrl;
    if (hlsUrl != null && hlsUrl!.isNotEmpty) return hlsUrl;
    return null;
  }

  String? get _imageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final playUrl = _playUrl;
    final imageUrl = _imageUrl;
    final isVideo = type.toUpperCase() == 'VIDEO' && playUrl != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: isVideo
            ? PostVideoPreview(videoUrl: playUrl!)
            : (imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFFF1F5F9),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const _MediaFallback(),
                    )
                  : const _MediaFallback()),
      ),
    );
  }
}

class PostVideoPreview extends StatefulWidget {
  const PostVideoPreview({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<PostVideoPreview> createState() => _PostVideoPreviewState();
}

class _PostVideoPreviewState extends State<PostVideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() {});
      }).catchError((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        if (value.hasError || !value.isInitialized) {
          return const _MediaFallback();
        }
        return ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: value.size.width,
              height: value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        );
      },
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE2E8F0),
      child: Center(
        child: Icon(Icons.videocam_off_outlined, size: 48, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
