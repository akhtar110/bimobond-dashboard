import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/localization/localization.dart';

/// Compact playable audio preview for gift create / edit / preview dialogs.
class GiftAudioPreview extends StatefulWidget {
  const GiftAudioPreview({
    super.key,
    this.networkUrl,
    this.bytes,
    this.fileName,
    this.onClear,
    this.compact = true,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final String? fileName;
  final VoidCallback? onClear;
  final bool compact;

  @override
  State<GiftAudioPreview> createState() => _GiftAudioPreviewState();
}

class _GiftAudioPreviewState extends State<GiftAudioPreview> {
  final _player = AudioPlayer();
  var _loading = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  var _playing = false;

  bool get _hasSource {
    final bytes = widget.bytes;
    if (bytes != null && bytes.isNotEmpty) return true;
    final url = widget.networkUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
    _loadSource();
  }

  @override
  void didUpdateWidget(covariant GiftAudioPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.bytes != widget.bytes) {
      _loadSource();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadSource() async {
    if (!_hasSource) {
      setState(() {
        _error = null;
        _loading = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await _player.stop();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = widget.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
          ),
        );
      } else {
        await _player.setUrl(widget.networkUrl!.trim());
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_loading || _error != null || !_hasSource) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _format(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final pad = widget.compact ? 10.0 : 12.0;

    if (!_hasSource) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Row(
            children: [
              Icon(Icons.audiotrack_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tOr('giftAudioPreviewEmpty', 'No audio to preview'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxMs = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack_rounded, size: 16, color: scheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fileName ??
                        widget.networkUrl ??
                        l10n.tOr('giftAudioPreview', 'Audio preview'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onClear != null)
                  IconButton(
                    tooltip: l10n.tOr('giftClearAudio', 'Clear audio'),
                    onPressed: () async {
                      await _player.stop();
                      widget.onClear!();
                    },
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: scheme.error),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    onPressed: _loading ? null : _togglePlay,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _playing
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 32,
                            color: scheme.secondary,
                          ),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Slider(
                      value: posMs,
                      max: maxMs,
                      onChanged: _loading || _duration == Duration.zero
                          ? null
                          : (v) => _player.seek(
                                Duration(milliseconds: v.round()),
                              ),
                    ),
                  ),
                  Text(
                    '${_format(_position)} / ${_format(_duration)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
