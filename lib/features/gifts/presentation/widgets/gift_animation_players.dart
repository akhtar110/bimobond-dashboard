import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../../create_post/presentation/utils/create_post_video_source.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/utils/gift_animation_byte_sniffer.dart';
import '../utils/gift_animation_bytes.dart';
/// Picks playable animation JSON inside a DotLottie (.lottie) zip.
/// Plain `decodeZip` / `firstWhere(.json)` often resolves `manifest.json` first,
/// which is not a Lottie composition — preview then fails silently.
Future<LottieComposition?> _giftLottieDecoder(List<int> bytes) async {
  if (bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
    return null; // Not a zip → Lottie falls back to raw JSON parsing.
  }

  final archive = ZipDecoder().decodeBytes(bytes);
  final candidates = _dotLottieJsonCandidates(archive.files);
  if (candidates.isEmpty) {
    debugPrint(
      'Gift DotLottie: zip has no .json entries '
      '(files: ${archive.files.map((f) => f.name).join(', ')})',
    );
    return null;
  }

  Object? lastError;
  for (final candidate in candidates) {
    try {
      final composition = await LottieComposition.decodeZip(
        bytes,
        filePicker: (_) => candidate,
      );
      if (composition != null) {
        debugPrint(
          'Gift DotLottie: using ${candidate.name} '
          '(frames=${composition.durationFrames})',
        );
        return composition;
      }
    } catch (e, st) {
      lastError = e;
      debugPrint('Gift DotLottie: candidate ${candidate.name} failed: $e\n$st');
    }
  }

  debugPrint('Gift DotLottie: all candidates failed: $lastError');
  return null;
}

List<ArchiveFile> _dotLottieJsonCandidates(List<ArchiveFile> files) {
  String norm(String name) => name.replaceAll('\\', '/').toLowerCase();

  bool isManifest(String name) {
    final base = name.split('/').last;
    return base == 'manifest.json' || base == 'm.json';
  }

  final scored = <({ArchiveFile file, int score})>[];
  for (final f in files) {
    if (!f.isFile) continue;
    final name = norm(f.name);
    if (!name.endsWith('.json') || isManifest(name)) continue;
    var score = 0;
    if (name.startsWith('animations/')) {
      score = 300;
    } else if (name.startsWith('a/')) {
      score = 200;
    } else if (!name.contains('/')) {
      score = 100;
    } else {
      score = 50;
    }
    scored.add((file: f, score: score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return [for (final s in scored) s.file];
}

class _JsonLottiePreview extends StatefulWidget {
  const _JsonLottiePreview({
    super.key,
    this.bytes,
    this.networkUrl,
  });

  final Uint8List? bytes;
  final String? networkUrl;

  @override
  State<_JsonLottiePreview> createState() => _JsonLottiePreviewState();
}

class _JsonLottiePreviewState extends State<_JsonLottiePreview> {
  LottieComposition? _composition;
  Uint8List? _fallbackBytes;
  Object? _error;
  var _loading = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void didUpdateWidget(covariant _JsonLottiePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.networkUrl != widget.networkUrl) {
      _startLoad();
    }
  }

  Uint8List _stripBom(Uint8List raw) {
    if (raw.length >= 3 &&
        raw[0] == 0xEF &&
        raw[1] == 0xBB &&
        raw[2] == 0xBF) {
      return raw.sublist(3);
    }
    return raw;
  }

  Future<void> _startLoad() async {
    final token = ++_loadToken;
    final local = widget.bytes;
    final url = widget.networkUrl?.trim();

    setState(() {
      _composition = null;
      _error = null;
      _fallbackBytes = local;
      _loading = true;
    });

    try {
      Uint8List? data = local;
      if ((data == null || data.isEmpty) &&
          url != null &&
          url.isNotEmpty) {
        data = await GiftAnimationBytesCache.get(url);
      }
      if (!mounted || token != _loadToken) return;
      if (data == null || data.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No animation data';
        });
        return;
      }

      final cleaned = _stripBom(data);
      final composition = await LottieComposition.fromBytes(
        cleaned,
        decoder: _giftLottieDecoder,
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _composition = composition;
        _fallbackBytes = cleaned;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('Gift Lottie preview load failed: $e\n$st');
      if (!mounted || token != _loadToken) return;
      setState(() {
        _composition = null;
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final composition = _composition;

    if (composition != null) {
      return Lottie(
        composition: composition,
        fit: BoxFit.contain,
        repeat: true,
      );
    }

    if (_loading) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: scheme.primary,
          ),
        ),
      );
    }

    return _jsonFallback(scheme, _fallbackBytes, _error);
  }

  Widget _jsonFallback(ColorScheme scheme, Uint8List? rawBytes, Object? error) {
    var isObject = false;
    var isDotLottie = false;
    if (rawBytes != null) {
      isDotLottie = giftBytesLookLikeLottieZip(rawBytes);
      if (!isDotLottie) {
        try {
          isObject = jsonDecode(utf8.decode(rawBytes)) is Map;
        } catch (_) {
          // Cosmetic only.
        }
      }
    }
    final label = isDotLottie
        ? 'Lottie ready to upload'
        : (isObject ? 'JSON ready to upload' : 'JSON animation');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDotLottie ? Icons.animation_rounded : Icons.data_object_rounded,
            size: 34,
            color: scheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
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
