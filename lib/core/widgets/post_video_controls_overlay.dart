import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// TikTok-style playback controls overlaid on [VideoPlayerController] content.
class PostVideoControlsOverlay extends StatefulWidget {
  const PostVideoControlsOverlay({
    super.key,
    required this.controller,
    this.autoHideAfter = const Duration(seconds: 3),
    this.enableFullscreen = true,
    this.showSeekBar = true,
    this.onFullscreenWillOpen,
    this.onFullscreenDidClose,
  });

  final VideoPlayerController controller;
  final Duration autoHideAfter;
  final bool enableFullscreen;
  final bool showSeekBar;
  final VoidCallback? onFullscreenWillOpen;
  final VoidCallback? onFullscreenDidClose;

  @override
  State<PostVideoControlsOverlay> createState() =>
      _PostVideoControlsOverlayState();
}

class _PostVideoControlsOverlayState extends State<PostVideoControlsOverlay> {
  bool _controlsVisible = false;
  bool _isMuted = false;
  double _volumeBeforeMute = 1.0;
  double? _dragPositionMs;
  Timer? _hideTimer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerTick);
    _syncMuteFromController();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(PostVideoControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
      _syncMuteFromController();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    if (!mounted) return;
    if (_dragPositionMs != null) return;
    setState(() {});
    if (widget.controller.value.isPlaying) {
      _scheduleAutoHide();
    }
  }

  void _syncMuteFromController() {
    final volume = widget.controller.value.volume;
    _isMuted = volume == 0;
    if (!_isMuted) {
      _volumeBeforeMute = volume;
    }
  }

  void _showControls({bool resetTimer = true}) {
    setState(() => _controlsVisible = true);
    if (resetTimer) {
      _scheduleAutoHide();
    }
  }

  void _hideControls() {
    if (!widget.controller.value.isPlaying) return;
    if (_hovered) return;
    setState(() => _controlsVisible = false);
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (!widget.controller.value.isPlaying || _hovered) return;
    _hideTimer = Timer(widget.autoHideAfter, () {
      if (!mounted) return;
      _hideControls();
    });
  }

  void _onSurfaceTap() {
    if (_controlsVisible) {
      _togglePlayPause();
    } else {
      _showControls();
    }
  }

  void _togglePlayPause() {
    final controller = widget.controller;
    if (!controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    } else {
      controller.play();
      _scheduleAutoHide();
    }
    setState(() {});
  }

  void _seekRelative(int seconds) {
    final controller = widget.controller;
    if (!controller.value.isInitialized) return;
    final total = controller.value.duration;
    var next = controller.value.position + Duration(seconds: seconds);
    if (next < Duration.zero) next = Duration.zero;
    if (total > Duration.zero && next > total) next = total;
    controller.seekTo(next);
    _showControls();
  }

  void _toggleMute() {
    final controller = widget.controller;
    if (!controller.value.isInitialized) return;
    if (_isMuted) {
      controller.setVolume(_volumeBeforeMute.clamp(0.0, 1.0));
      _isMuted = false;
    } else {
      _volumeBeforeMute =
          controller.value.volume > 0 ? controller.value.volume : 1.0;
      controller.setVolume(0);
      _isMuted = true;
    }
    setState(() {});
    _showControls();
  }

  Future<void> _openFullscreen() async {
    _hideTimer?.cancel();
    if (!mounted) return;
    widget.onFullscreenWillOpen?.call();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => PostVideoFullscreenPage(
          controller: widget.controller,
        ),
      ),
    );
    if (!mounted) return;
    widget.onFullscreenDidClose?.call();
    _showControls();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = widget.controller;
    final value = controller.value;

    if (!value.isInitialized) {
      return const SizedBox.shrink();
    }

    final durationMs = value.duration.inMilliseconds;
    final positionMs = _dragPositionMs ?? value.position.inMilliseconds.toDouble();
    final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
    final isPlaying = value.isPlaying;
    final showChrome = _controlsVisible || !isPlaying || _hovered;
    final showCenterTransport = _hovered || !isPlaying;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _showControls(resetTimer: false);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scheduleAutoHide();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onSurfaceTap,
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            ignoring: !showChrome,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showChrome ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _onSurfaceTap,
                child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.scrim.withValues(alpha: 0.35),
                      Colors.transparent,
                      scheme.scrim.withValues(alpha: 0.5),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OverlayIconButton(
                              icon: _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              tooltip: _isMuted ? 'Unmute' : 'Mute',
                              onPressed: _toggleMute,
                            ),
                            if (widget.enableFullscreen) ...[
                              const SizedBox(width: 4),
                              _OverlayIconButton(
                                icon: Icons.fullscreen_rounded,
                                tooltip: 'Fullscreen',
                                onPressed: _openFullscreen,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: showCenterTransport ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !showCenterTransport,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _OverlayIconButton(
                              icon: Icons.replay_10_rounded,
                              tooltip: 'Back 10 seconds',
                              size: 40,
                              onPressed: () => _seekRelative(-10),
                            ),
                            const SizedBox(width: 12),
                            _OverlayPlayButton(
                              isPlaying: isPlaying,
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(width: 12),
                            _OverlayIconButton(
                              icon: Icons.forward_10_rounded,
                              tooltip: 'Forward 10 seconds',
                              size: 40,
                              onPressed: () => _seekRelative(10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.showSeekBar)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                    scheme.onSurface.withValues(alpha: 0.35),
                                thumbColor: scheme.primary,
                                overlayColor:
                                    scheme.primary.withValues(alpha: 0.16),
                              ),
                              child: Slider(
                                value: positionMs.clamp(0, maxMs),
                                max: maxMs,
                                onChangeStart: (_) {
                                  _hideTimer?.cancel();
                                  setState(() => _controlsVisible = true);
                                },
                                onChanged: (v) {
                                  setState(() => _dragPositionMs = v);
                                },
                                onChangeEnd: (v) {
                                  controller.seekTo(
                                    Duration(milliseconds: v.round()),
                                  );
                                  setState(() => _dragPositionMs = null);
                                  _showControls();
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _OverlayTimeLabel(
                                  text: _formatDuration(
                                    Duration(
                                      milliseconds: positionMs.round(),
                                    ),
                                  ),
                                  emphasized: true,
                                ),
                                _OverlayTimeLabel(
                                  text: _formatDuration(value.duration),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class PostVideoFullscreenPage extends StatelessWidget {
  const PostVideoFullscreenPage({
    super.key,
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.scrim,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.isInitialized
                    ? controller.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(controller),
              ),
            ),
            PostVideoControlsOverlay(
              controller: controller,
              enableFullscreen: false,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _OverlayIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayTimeLabel extends StatelessWidget {
  const _OverlayTimeLabel({
    required this.text,
    this.emphasized = false,
  });

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.scrim.withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface.withValues(alpha: 0.92),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.scrim.withValues(alpha: 0.55),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.52,
            color: scheme.onSurface,
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _OverlayPlayButton extends StatelessWidget {
  const _OverlayPlayButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.scrim.withValues(alpha: 0.55),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: scheme.onSurface,
            size: isPlaying ? 30 : 32,
          ),
        ),
      ),
    );
  }
}
