import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gift_animation_bytes.dart';

/// Hosts [web/pag_player.html] in a platform view and asks it to play a `.pag`.
///
/// Bytes are sent directly to the iframe via `postMessage` (as a transferable
/// ArrayBuffer) instead of a `blob:` URL. Cross-frame fetch of a `blob:` URL
/// created in a different Window is not reliably supported by every browser
/// build, and any hiccup there previously surfaced as a confusing libpag
/// error. Sending raw bytes avoids that path entirely.
class GiftPagPlayer extends StatefulWidget {
  const GiftPagPlayer({
    super.key,
    this.bytes,
    this.networkUrl,
  });

  final Uint8List? bytes;
  final String? networkUrl;

  @override
  State<GiftPagPlayer> createState() => _GiftPagPlayerState();
}

class _GiftPagPlayerState extends State<GiftPagPlayer> {
  static int _seq = 0;

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
    _containerId = 'gift-pag-host-$token-$_seq';
    _viewType = 'gift-pag-view-$token-$_seq';
    _registerFactory();
  }

  @override
  void didUpdateWidget(covariant GiftPagPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceKey(widget) != _sourceKey(oldWidget)) {
      _armedKey = null;
      _queuePlay();
    }
  }

  String _sourceKey(GiftPagPlayer w) {
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
        ..style.backgroundColor = '#111318';
    });
    _factoryRegistered = true;
  }

  JSObject? _api() {
    try {
      final value = globalContext.getProperty('GiftPagPreview'.toJS);
      if (value == null || value.isUndefinedOrNull) return null;
      return value as JSObject;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playBytes(JSObject api, Uint8List bytes) async {
    // Fresh copy: never hand out a view backed by memory Dart/the cache still
    // owns — the JS side also copies again before transfer, but this keeps
    // ownership unambiguous on both sides.
    final copy = Uint8List.fromList(bytes);
    final promise = api.callMethod<JSPromise<JSAny?>>(
      'playFromBytes'.toJS,
      _containerId.toJS,
      copy.toJS,
    );
    await promise.toDart;
  }

  void _destroy(JSObject api) {
    try {
      api.callMethod<JSAny?>('destroy'.toJS, _containerId.toJS);
    } catch (_) {}
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
      final api = _api();
      if (api == null) {
        throw StateError(
          'PAG helper missing — stop the app, run again, hard refresh (Ctrl+Shift+R).',
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted || token != _playToken) return;

      late final Uint8List playBytes;
      final local = widget.bytes;
      if (local != null && local.isNotEmpty) {
        if (giftBytesLookLikeMp4(local)) {
          throw StateError(
            'This file is MP4 (ftyp), not a PAG animation.',
          );
        }
        playBytes = local;
      } else {
        final raw = widget.networkUrl?.trim();
        if (raw == null || raw.isEmpty) {
          throw StateError('No PAG source');
        }
        final cached = GiftAnimationBytesCache.peek(raw) ??
            await GiftAnimationBytesCache.get(raw);
        if (!mounted || token != _playToken) return;
        if (giftBytesLookLikeMp4(cached)) {
          throw StateError(
            'This file is MP4 (ftyp), not a PAG animation.',
          );
        }
        playBytes = cached;
      }

      if (!mounted || token != _playToken) return;
      if (kDebugMode) {
        debugPrint('GiftPagPlayer: play $key (${playBytes.length} bytes)');
      }

      await _playBytes(api, playBytes);
      if (!mounted || token != _playToken) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('GiftPagPlayer error: $e');
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
    final api = _api();
    if (api != null) _destroy(api);
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
                    'Loading PAG…',
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
                      Icons.videocam_off_outlined,
                      size: 34,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PAG preview unavailable',
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
                        maxLines: 6,
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
