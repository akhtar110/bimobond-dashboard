import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/localization/localization.dart';

/// Playable preview for an attached audio file or remote URL in the sound form.
class SoundFormAudioPreview extends StatefulWidget {
  const SoundFormAudioPreview({
    super.key,
    this.networkUrl,
    this.bytes,
    this.fileName,
    this.onClear,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final String? fileName;
  final VoidCallback? onClear;

  @override
  State<SoundFormAudioPreview> createState() => _SoundFormAudioPreviewState();
}

class _SoundFormAudioPreviewState extends State<SoundFormAudioPreview> {
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
  void didUpdateWidget(covariant SoundFormAudioPreview oldWidget) {
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
            Uri.dataFromBytes(bytes, mimeType: _mimeFor(widget.fileName)),
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

  String _mimeFor(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) return 'audio/mp4';
    return 'audio/mpeg';
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

    if (!_hasSource) {
      return const SizedBox.shrink();
    }

    final maxMs = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack_rounded,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fileName ??
                        l10n.tOr('soundPreview', 'Play'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onClear != null)
                  IconButton(
                    tooltip: l10n.tOr('remove', 'Remove'),
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
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ] else
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.t('soundPreview'),
                    onPressed: _loading ? null : _togglePlay,
                    icon: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : Icon(
                            _playing
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 30,
                            color: scheme.primary,
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
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
