import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gift_animation_bytes.dart';

/// Plays a Shockwave Flash (`.swf`) animation in a platform view via Ruffle.
class GiftSwfPlayer extends StatefulWidget {
  const GiftSwfPlayer({
    super.key,
    this.bytes,
    this.networkUrl,
  });

  final Uint8List? bytes;
  final String? networkUrl;

  @override
  State<GiftSwfPlayer> createState() => _GiftSwfPlayerState();
}

class _GiftSwfPlayerState extends State<GiftSwfPlayer> {
  static int _seq = 0;
  static Future<void>? _ruffleLoading;

  late final String _viewType;
  late final String _containerId;
  var _factoryRegistered = false;
  var _viewCreated = false;
  var _ready = false;
  var _failed = false;
  var _starting = false;
  String? _error;
  int _playToken = 0;
  String? _armedKey;

  @override
  void initState() {
    super.initState();
    _seq += 1;
    final token = DateTime.now().microsecondsSinceEpoch;
    _containerId = 'gift-swf-host-$token-$_seq';
    _viewType = 'gift-swf-view-$token-$_seq';
    _registerFactory();
  }

  @override
  void didUpdateWidget(covariant GiftSwfPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceKey(widget) != _sourceKey(oldWidget)) {
      _armedKey = null;
      _queuePlay();
    }
  }

  String _sourceKey(GiftSwfPlayer w) {
    final b = w.bytes;
    if (b != null && b.isNotEmpty) {
      return 'b:${identityHashCode(b)}:${b.length}';
    }
    return 'u:${w.networkUrl ?? ''}';
  }

  void _registerFactory() {
    if (_factoryRegistered) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final existing = html.document.getElementById(_containerId);
      if (existing != null) return existing;
      return html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..style.margin = '0'
        ..style.padding = '0'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#111318'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center';
    });
    _factoryRegistered = true;
  }

  Future<void> _ensureRuffle() {
    final existing = globalContext.getProperty('RufflePlayer'.toJS);
    if (existing != null && !existing.isUndefinedOrNull) {
      return Future<void>.value();
    }
    return _ruffleLoading ??= () async {
      final completer = Completer<void>();
      final script = html.ScriptElement()
        ..src = 'https://cdn.jsdelivr.net/npm/@ruffle-rs/ruffle/ruffle.js'
        ..async = true
        ..setAttribute('data-gift-ruffle', '1');
      script.onLoad.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      script.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Failed to load Ruffle SWF player'),
          );
        }
      });
      html.document.head?.append(script);
      await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw StateError('Ruffle load timeout'),
      );
    }().whenComplete(() {
      // Allow a retry after failure by clearing the cached future.
      if (globalContext.getProperty('RufflePlayer'.toJS) == null ||
          globalContext.getProperty('RufflePlayer'.toJS)!.isUndefinedOrNull) {
        _ruffleLoading = null;
      }
    });
  }

  void _clearPlayer() {
    final host = html.document.getElementById(_containerId);
    host?.children.clear();
  }

  Future<void> _playBytes(Uint8List bytes) async {
    await _ensureRuffle();
    final host = html.document.getElementById(_containerId);
    if (host == null) {
      throw StateError('SWF container not found');
    }

    _clearPlayer();

    final ruffleNs = globalContext.getProperty('RufflePlayer'.toJS);
    if (ruffleNs == null || ruffleNs.isUndefinedOrNull) {
      throw StateError('RufflePlayer missing after script load');
    }
    final newest = (ruffleNs as JSObject).callMethod<JSAny?>('newest'.toJS);
    if (newest == null || newest.isUndefinedOrNull) {
      throw StateError('RufflePlayer.newest() returned null');
    }
    final playerAny =
        (newest as JSObject).callMethod<JSAny?>('createPlayer'.toJS);
    if (playerAny == null || playerAny.isUndefinedOrNull) {
      throw StateError('Ruffle createPlayer() returned null');
    }

    final player = playerAny as JSObject;
    // Ruffle returns a custom HTMLElement (<ruffle-player>).
    final el = playerAny as html.Element;
    el.style
      ..setProperty('width', '100%')
      ..setProperty('height', '100%')
      ..setProperty('border', '0');
    host.append(el);

    final copy = Uint8List.fromList(bytes);
    final config = JSObject()
      ..setProperty('data'.toJS, copy.toJS)
      ..setProperty('autoplay'.toJS, 'on'.toJS)
      ..setProperty('letterbox'.toJS, 'on'.toJS)
      ..setProperty('scale'.toJS, 'showAll'.toJS);

    try {
      final loadPromise = player.callMethod<JSPromise<JSAny?>>(
        'load'.toJS,
        config,
      );
      await loadPromise.toDart;
    } catch (e) {
      if (kDebugMode) debugPrint('Ruffle load promise notice: $e');
    }
  }

  void _onViewCreated(int _) {
    _viewCreated = true;
    _queuePlay();
  }

  void _queuePlay() {
    if (!mounted || !_viewCreated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startPlayback());
    });
  }

  Future<void> _startPlayback({bool force = false}) async {
    if (!mounted || _starting) return;

    final key = _sourceKey(widget);
    if (!force && _ready && key == _armedKey) return;
    if (!force && _failed && key == _armedKey) return;
    if (!force && key == _armedKey && !_ready && !_failed) return;

    _starting = true;
    final token = ++_playToken;
    _armedKey = key;

    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
        _error = null;
      });
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted || token != _playToken) return;

      late final Uint8List playBytes;
      final local = widget.bytes;
      if (local != null && local.isNotEmpty) {
        playBytes = local;
      } else {
        final raw = widget.networkUrl?.trim();
        if (raw == null || raw.isEmpty) {
          throw StateError('No SWF source');
        }
        playBytes = GiftAnimationBytesCache.peek(raw) ??
            await GiftAnimationBytesCache.get(raw);
        if (!mounted || token != _playToken) return;
      }

      if (kDebugMode) {
        debugPrint('GiftSwfPlayer: play $key (${playBytes.length} bytes)');
      }

      await _playBytes(playBytes);
      if (!mounted || token != _playToken) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('GiftSwfPlayer error: $e');
      if (!mounted || token != _playToken) return;
      setState(() {
        _failed = true;
        _ready = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _starting = false;
    }
  }

  @override
  void dispose() {
    _playToken++;
    _clearPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF111318)),
        HtmlElementView(
          viewType: _viewType,
          onPlatformViewCreated: _onViewCreated,
        ),
        if (!_ready && !_failed)
          const IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF8AB4FF),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading SWF…',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_failed)
          ColoredBox(
            color: const Color(0xCC111318),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_filter_outlined,
                      size: 34,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SWF ready to upload',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        _armedKey = null;
                        unawaited(_startPlayback(force: true));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
