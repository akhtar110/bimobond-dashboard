import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// Ensures only one sound preview plays at a time across the module.
class SoundPreviewService extends ChangeNotifier {
  String? _activeSoundId;
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _hasError = false;

  String? get activeSoundId => _activeSoundId;
  bool get isLoading => _loading;
  bool get hasError => _hasError;
  VideoPlayerController? get controller => _controller;

  bool isPlaying(String soundId) =>
      _activeSoundId == soundId && (_controller?.value.isPlaying ?? false);

  bool isActive(String soundId) => _activeSoundId == soundId;

  double progressFor(String soundId) {
    if (_activeSoundId != soundId || _controller == null) return 0;
    final value = _controller!.value;
    if (!value.isInitialized || value.duration.inMilliseconds <= 0) return 0;
    return value.position.inMilliseconds / value.duration.inMilliseconds;
  }

  Duration positionFor(String soundId) {
    if (_activeSoundId != soundId || _controller == null) return Duration.zero;
    final value = _controller!.value;
    if (!value.isInitialized) return Duration.zero;
    return value.position;
  }

  Duration durationFor(String soundId) {
    if (_activeSoundId != soundId || _controller == null) return Duration.zero;
    final value = _controller!.value;
    if (!value.isInitialized) return Duration.zero;
    return value.duration;
  }

  Future<void> toggle(String soundId, String audioUrl) async {
    if (_activeSoundId == soundId && _controller != null) {
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      } else {
        await _controller!.play();
      }
      notifyListeners();
      return;
    }

    await _disposeController();
    _activeSoundId = soundId;
    _loading = true;
    _hasError = false;
    notifyListeners();

    final resolved = resolveMediaUrl(audioUrl);
    if (resolved == null || resolved.isEmpty) {
      _loading = false;
      _hasError = true;
      notifyListeners();
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
    _controller = controller;

    try {
      await controller.initialize();
      controller.setLooping(false);
      controller.addListener(_onTick);
      _loading = false;
      await controller.play();
      notifyListeners();
    } catch (_) {
      _loading = false;
      _hasError = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _disposeController();
    notifyListeners();
  }

  void _onTick() {
    notifyListeners();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.position >= controller.value.duration) {
      controller.pause();
      controller.seekTo(Duration.zero);
      notifyListeners();
    }
  }

  Future<void> _disposeController() async {
    _controller?.removeListener(_onTick);
    await _controller?.dispose();
    _controller = null;
    _activeSoundId = null;
    _loading = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}
