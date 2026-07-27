import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../../create_post/presentation/utils/create_post_video_source.dart';
import '../bloc/ar_overlay_media_preview_cubit.dart';

/// Plays AR overlay animation media (Lottie JSON or MP4) via cubit sniffing.
class ArOverlayMediaPlayer extends StatelessWidget {
  const ArOverlayMediaPlayer({
    super.key,
    this.networkUrl,
    this.bytes,
    this.fileName,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final String? fileName;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArOverlayMediaPreviewCubit()
        ..load(networkUrl: networkUrl, bytes: bytes, fileName: fileName),
      child: _ArOverlayMediaPlayerView(
        networkUrl: networkUrl,
        bytes: bytes,
        fileName: fileName,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      ),
    );
  }
}

class _ArOverlayMediaPlayerView extends StatefulWidget {
  const _ArOverlayMediaPlayerView({
    this.networkUrl,
    this.bytes,
    this.fileName,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final String? fileName;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  State<_ArOverlayMediaPlayerView> createState() =>
      _ArOverlayMediaPlayerViewState();
}

class _ArOverlayMediaPlayerViewState extends State<_ArOverlayMediaPlayerView> {
  @override
  void didUpdateWidget(covariant _ArOverlayMediaPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.fileName != widget.fileName) {
      context.read<ArOverlayMediaPreviewCubit>().load(
            networkUrl: widget.networkUrl,
            bytes: widget.bytes,
            fileName: widget.fileName,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ArOverlayMediaPreviewCubit, ArOverlayMediaPreviewState>(
      buildWhen: (prev, next) =>
          prev.loading != next.loading ||
          prev.error != next.error ||
          prev.kind != next.kind ||
          prev.composition != next.composition ||
          prev.videoNetworkUrl != next.videoNetworkUrl ||
          prev.videoBytes != next.videoBytes,
      builder: (context, state) {
        final error = state.error;
        if (error != null) {
          return widget.errorBuilder?.call(context, error) ??
              Center(
                child: Icon(Icons.error_outline, color: scheme.error),
              );
        }
        if (state.loading) {
          return widget.loadingBuilder?.call(context) ??
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
              );
        }

        if (state.isVideo) {
          final networkUrl = state.videoNetworkUrl;
          if (networkUrl != null && networkUrl.isNotEmpty) {
            return _ArOverlayNetworkVideo(url: networkUrl);
          }
          final bytes = state.videoBytes;
          if (bytes != null && bytes.isNotEmpty) {
            return _ArOverlayLocalVideo(
              bytes: bytes,
              fileName: state.videoFileName ?? 'overlay.mp4',
            );
          }
        }

        final composition = state.composition;
        if (composition != null) {
          return RepaintBoundary(
            child: Lottie(
              composition: composition,
              fit: BoxFit.contain,
              repeat: true,
              frameRate: const FrameRate(30),
              renderCache: RenderCache.drawingCommands,
              addRepaintBoundary: false,
            ),
          );
        }

        return widget.loadingBuilder?.call(context) ??
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              ),
            );
      },
    );
  }
}

class _ArOverlayNetworkVideo extends StatefulWidget {
  const _ArOverlayNetworkVideo({required this.url});

  final String url;

  @override
  State<_ArOverlayNetworkVideo> createState() => _ArOverlayNetworkVideoState();
}

class _ArOverlayNetworkVideoState extends State<_ArOverlayNetworkVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _ArOverlayNetworkVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
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
    return _ArOverlayVideoSurface(
      controller: _controller,
      ready: _ready,
      failed: _failed,
    );
  }
}

class _ArOverlayLocalVideo extends StatefulWidget {
  const _ArOverlayLocalVideo({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;

  @override
  State<_ArOverlayLocalVideo> createState() => _ArOverlayLocalVideoState();
}

class _ArOverlayLocalVideoState extends State<_ArOverlayLocalVideo> {
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
  void didUpdateWidget(covariant _ArOverlayLocalVideo oldWidget) {
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
    return _ArOverlayVideoSurface(
      controller: _controller,
      ready: _ready,
      failed: _failed,
    );
  }
}

class _ArOverlayVideoSurface extends StatelessWidget {
  const _ArOverlayVideoSurface({
    required this.controller,
    required this.ready,
    required this.failed,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (failed) {
      return Center(
        child: Icon(Icons.videocam_off_outlined, color: scheme.error),
      );
    }
    final c = controller;
    if (!ready || c == null || !c.value.isInitialized) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}
