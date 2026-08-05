import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../../create_post/presentation/utils/create_post_video_source.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_embedded_video_frame.dart';
import '../utils/pag_preview.dart';
import '../utils/swf_preview.dart';

bool giftAnimationLooksLikeVideo(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi');
}

bool giftAnimationLooksLikePag(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.pag');
}

bool giftAnimationLooksLikeSwf(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.swf');
}

/// SWF magic: FWS (uncompressed), CWS (zlib), or ZWS (LZMA).
bool giftBytesLookLikeSwf(List<int> bytes) {
  if (bytes.length < 3) return false;
  final a = bytes[0];
  return (a == 0x46 || a == 0x43 || a == 0x5A) &&
      bytes[1] == 0x57 &&
      bytes[2] == 0x53;
}

bool giftAnimationLooksLikeJson(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.json');
}

bool giftAnimationLooksLikeLottie(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.lottie');
}

/// DotLottie (.lottie) archives are ZIP files (PK…).
bool giftBytesLookLikeLottieZip(List<int> bytes) {
  return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
}

bool giftBytesLookLikeJson(List<int> bytes) {
  if (bytes.isEmpty) return false;
  var i = 0;
  // Skip a leading UTF-8 BOM (EF BB BF) if present.
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    i = 3;
  }
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
      i++;
      continue;
    }
    return b == 0x7B || b == 0x5B; // '{' or '['
  }
  return false;
}

bool giftAnimationLooksLikeGif(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.gif');
}

/// GIF87a / GIF89a magic header.
bool giftBytesLookLikeGif(List<int> bytes) {
  if (bytes.length < 6) return false;
  return bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38 &&
      (bytes[4] == 0x37 || bytes[4] == 0x39) &&
      bytes[5] == 0x61;
}

bool giftAnimationLooksLikeImage(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.gif') ||
      lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}

enum _AnimKind { pag, video, image, json, swf, unknown }

String? _displayFileName(String? fileName, String? networkUrl) {
  final raw = (fileName != null && fileName.isNotEmpty)
      ? fileName
      : networkUrl;
  if (raw == null || raw.isEmpty) return null;
  final withoutQuery = raw.split('?').first;
  final parts = withoutQuery.split(RegExp(r'[/\\]'));
  return parts.isNotEmpty ? parts.last : withoutQuery;
}

_AnimKind _kindFromName(String? fileName, String? networkUrl) {
  if (giftAnimationLooksLikePag(fileName) ||
      giftAnimationLooksLikePag(networkUrl)) {
    return _AnimKind.pag;
  }
  if (giftAnimationLooksLikeSwf(fileName) ||
      giftAnimationLooksLikeSwf(networkUrl)) {
    return _AnimKind.swf;
  }
  if (giftAnimationLooksLikeJson(fileName) ||
      giftAnimationLooksLikeJson(networkUrl) ||
      giftAnimationLooksLikeLottie(fileName) ||
      giftAnimationLooksLikeLottie(networkUrl)) {
    return _AnimKind.json;
  }
  if (giftAnimationLooksLikeGif(fileName) ||
      giftAnimationLooksLikeGif(networkUrl) ||
      giftAnimationLooksLikeImage(fileName) ||
      giftAnimationLooksLikeImage(networkUrl)) {
    return _AnimKind.image;
  }
  if (giftAnimationLooksLikeVideo(fileName) ||
      giftAnimationLooksLikeVideo(networkUrl)) {
    return _AnimKind.video;
  }
  return _AnimKind.unknown;
}

_AnimKind _kindFromBytes(Uint8List bytes, String? fileName, String? networkUrl) {
  if (giftBytesLookLikeMp4(bytes)) return _AnimKind.video;
  if (giftBytesLookLikeGif(bytes)) return _AnimKind.image;
  if (giftBytesLookLikeSwf(bytes)) return _AnimKind.swf;
  if (giftBytesLookLikeJson(bytes)) return _AnimKind.json;
  // Sniff DotLottie zips before trusting a `.mp4` URL from upload disguise.
  if (giftBytesLookLikeLottieZip(bytes)) return _AnimKind.json;
  final named = _kindFromName(fileName, networkUrl);
  if (named != _AnimKind.unknown) return named;
  if (giftAnimationLooksLikePag(fileName) ||
      giftAnimationLooksLikePag(networkUrl)) {
    return _AnimKind.pag;
  }
  return _AnimKind.video;
}

String _badgeFor(_AnimKind kind, String? fileName, String? networkUrl) {
  switch (kind) {
    case _AnimKind.pag:
      return 'PAG';
    case _AnimKind.swf:
      return 'SWF';
    case _AnimKind.json:
      final name =
          _displayFileName(fileName, networkUrl)?.toLowerCase() ?? '';
      if (name.endsWith('.lottie')) return 'LOTTIE';
      return 'JSON';
    case _AnimKind.image:
      final name =
          _displayFileName(fileName, networkUrl)?.toLowerCase() ?? '';
      if (name.endsWith('.gif')) return 'GIF';
      return 'IMAGE';
    case _AnimKind.video:
      final name =
          _displayFileName(fileName, networkUrl)?.toLowerCase() ?? '';
      if (name.endsWith('.webm')) return 'WEBM';
      if (name.endsWith('.mov')) return 'MOV';
      return 'MP4';
    case _AnimKind.unknown:
      return _formatBadgeFallback(fileName, networkUrl);
  }
}

String _formatBadgeFallback(String? fileName, String? networkUrl) {
  final name = _displayFileName(fileName, networkUrl)?.toLowerCase() ?? '';
  if (name.endsWith('.pag')) return 'PAG';
  if (name.endsWith('.swf')) return 'SWF';
  if (name.endsWith('.lottie')) return 'LOTTIE';
  if (name.endsWith('.json')) return 'JSON';
  if (name.endsWith('.gif')) return 'GIF';
  if (name.endsWith('.mp4')) return 'MP4';
  if (name.endsWith('.webm')) return 'WEBM';
  if (name.endsWith('.mov')) return 'MOV';
  if (giftAnimationLooksLikeImage(name)) return 'IMAGE';
  if (giftAnimationLooksLikeVideo(name)) return 'VIDEO';
  return 'FILE';
}

/// Compact animation preview for gift create/edit dialogs
/// (MP4 / PAG / JSON / Lottie / GIF / SWF / image).
/// Prefers in-memory [bytes] (instant after pick). Network sources download once
/// and sniff magic bytes so mislabeled `.pag` MP4s use the video player.
class GiftAnimationPreview extends StatefulWidget {
  const GiftAnimationPreview({
    super.key,
    this.bytes,
    this.networkUrl,
    this.fileName,
    this.onClear,
    this.compact = false,
    this.expandToFill = false,
    this.showChrome = true,
    this.clipBorderRadius,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final String? fileName;
  final VoidCallback? onClear;

  /// Tighter chrome for create/edit/preview dialogs.
  final bool compact;

  /// When true, fills a parent with bounded height (uses [Expanded]
  /// instead of [AspectRatio]) so dialogs don't overflow.
  final bool expandToFill;

  /// When false, renders only the animation stage (no header, footer, or dark frame).
  final bool showChrome;

  /// Clips the stage (e.g. gift preview dialog frame). Defaults to 16 when [showChrome] is false.
  final double? clipBorderRadius;

  @override
  State<GiftAnimationPreview> createState() => _GiftAnimationPreviewState();
}

class _GiftAnimationPreviewState extends State<GiftAnimationPreview> {
  Uint8List? _resolvedBytes;
  _AnimKind? _resolvedKind;
  var _resolving = false;
  String? _resolveError;
  int _resolveToken = 0;

  double get _effectiveClipRadius =>
      widget.clipBorderRadius ?? (widget.showChrome ? 0 : 16);

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant GiftAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.fileName != widget.fileName) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final local = widget.bytes;
    if (local != null && local.isNotEmpty) {
      final kind = _kindFromBytes(local, widget.fileName, widget.networkUrl);
      if (identical(_resolvedBytes, local) &&
          _resolvedKind == kind &&
          !_resolving &&
          _resolveError == null) {
        return;
      }
      _resolveToken++;
      setState(() {
        _resolvedBytes = local;
        _resolvedKind = kind;
        _resolving = false;
        _resolveError = null;
      });
      return;
    }

    final url = widget.networkUrl?.trim();
    if (url == null || url.isEmpty) {
      if (_resolvedBytes == null &&
          _resolvedKind == null &&
          !_resolving &&
          _resolveError == null) {
        return;
      }
      _resolveToken++;
      setState(() {
        _resolvedBytes = null;
        _resolvedKind = null;
        _resolving = false;
        _resolveError = null;
      });
      return;
    }

    final named = _kindFromName(widget.fileName, url);

    // PAG / SWF by extension: hand off to dedicated players (they load/cache).
    // Do NOT download here — that was remounting the player and fighting WASM.
    if (named == _AnimKind.pag || named == _AnimKind.swf) {
      if (_resolvedBytes == null &&
          _resolvedKind == named &&
          !_resolving &&
          _resolveError == null) {
        return;
      }
      _resolveToken++;
      setState(() {
        _resolvedBytes = GiftAnimationBytesCache.peek(url);
        _resolvedKind = named;
        _resolving = false;
        _resolveError = null;
      });
      return;
    }

    // Video URLs may be Lottie JSON/DotLottie in disguise — download once and
    // sniff magic bytes (same workaround as `/posts/upload` MIME limits).
    if (named == _AnimKind.video) {
      final cached = GiftAnimationBytesCache.peek(url);
      if (cached != null) {
        final kind = _kindFromBytes(cached, widget.fileName, url);
        if (identical(_resolvedBytes, cached) &&
            _resolvedKind == kind &&
            !_resolving &&
            _resolveError == null) {
          return;
        }
        _resolveToken++;
        setState(() {
          _resolvedBytes = cached;
          _resolvedKind = kind;
          _resolving = false;
          _resolveError = null;
        });
        return;
      }
      _startNetworkResolve(url);
      return;
    }

    // Extension-clear image/json: players resolve network URLs themselves.
    if (named == _AnimKind.image || named == _AnimKind.json) {
      if (_resolvedBytes == null &&
          _resolvedKind == named &&
          !_resolving &&
          _resolveError == null) {
        return;
      }
      _resolveToken++;
      setState(() {
        _resolvedBytes = null;
        _resolvedKind = named;
        _resolving = false;
        _resolveError = null;
      });
      return;
    }

    // Unknown extension: download once, sniff magic bytes, route.
    final cached = GiftAnimationBytesCache.peek(url);
    if (cached != null) {
      final kind = _kindFromBytes(cached, widget.fileName, url);
      if (identical(_resolvedBytes, cached) &&
          _resolvedKind == kind &&
          !_resolving &&
          _resolveError == null) {
        return;
      }
      _resolveToken++;
      setState(() {
        _resolvedBytes = cached;
        _resolvedKind = kind;
        _resolving = false;
        _resolveError = null;
      });
      return;
    }

    _startNetworkResolve(url);
  }

  Future<void> _startNetworkResolve(String url) async {
    final token = ++_resolveToken;
    setState(() {
      _resolving = true;
      _resolveError = null;
    });
    try {
      final bytes = await GiftAnimationBytesCache.get(url);
      if (!mounted || token != _resolveToken) return;
      setState(() {
        _resolvedBytes = bytes;
        _resolvedKind = _kindFromBytes(bytes, widget.fileName, url);
        _resolving = false;
      });
    } catch (e) {
      if (!mounted || token != _resolveToken) return;
      setState(() {
        _resolving = false;
        _resolveError = e.toString().replaceFirst('Exception: ', '');
        _resolvedKind = _kindFromName(widget.fileName, url);
      });
    }
  }

  Widget _placeholder(ColorScheme scheme) {
    final onStage = !widget.showChrome;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.animation_rounded, size: 34, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            'Animation preview',
            style: TextStyle(
              color: onStage
                  ? scheme.onSurfaceVariant
                  : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme scheme) {
    final kind = _resolvedKind;
    final bytes = _resolvedBytes;
    final url = widget.networkUrl;

    // Keep a single child subtree so PAG / video players are not disposed and
    // recreated on every parent rebuild (that was causing BindingError loops).
    Widget? body;

    if (_resolveError != null && bytes == null && !_resolving) {
      final onStage = !widget.showChrome;
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 34,
                color: onStage ? scheme.onSurfaceVariant : Colors.white54,
              ),
              const SizedBox(height: 8),
              Text(
                'Preview unavailable',
                style: TextStyle(
                  color: onStage ? scheme.onSurface : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _resolveError!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onStage
                      ? scheme.onSurfaceVariant
                      : Colors.white38,
                  fontSize: 10,
                ),
              ),
              if (url != null && url.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _startNetworkResolve(url),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (kind == _AnimKind.pag &&
        ((bytes != null && bytes.isNotEmpty) ||
            (url != null && url.trim().isNotEmpty))) {
      body = GiftPagPlayer(
        key: const ValueKey('gift-pag-player'),
        bytes: bytes,
        networkUrl: (bytes == null || bytes.isEmpty) ? url : null,
      );
    } else if (kind == _AnimKind.swf &&
        ((bytes != null && bytes.isNotEmpty) ||
            (url != null && url.trim().isNotEmpty))) {
      body = GiftSwfPlayer(
        key: const ValueKey('gift-swf-player'),
        bytes: bytes,
        networkUrl: (bytes == null || bytes.isEmpty) ? url : null,
      );
    } else if (kind == _AnimKind.json) {
      body = _JsonLottiePreview(
        key: const ValueKey('gift-json-lottie'),
        bytes: bytes,
        networkUrl: (bytes == null || bytes.isEmpty) ? url : null,
      );
    } else if (kind == _AnimKind.image) {
      final imageFit =
          widget.showChrome ? BoxFit.contain : BoxFit.cover;
      if (bytes != null) {
        body = Image.memory(
          bytes,
          fit: imageFit,
          width: widget.showChrome ? null : double.infinity,
          height: widget.showChrome ? null : double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        );
      } else if (url != null && url.isNotEmpty) {
        body = Image.network(
          resolveMediaUrl(url) ?? url,
          fit: imageFit,
          width: widget.showChrome ? null : double.infinity,
          height: widget.showChrome ? null : double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        );
      }
    } else if (kind == _AnimKind.video || kind == _AnimKind.unknown) {
      if (bytes != null) {
        final name = widget.fileName?.isNotEmpty == true
            ? widget.fileName!
            : 'animation.mp4';
        body = _LocalVideoPreview(
          bytes: bytes,
          fileName: name,
          embeddedPreview: !widget.showChrome,
          clipBorderRadius: _effectiveClipRadius,
        );
      } else if (url != null && url.isNotEmpty) {
        body = _NetworkVideoPreview(
          url: url,
          embeddedPreview: !widget.showChrome,
          clipBorderRadius: _effectiveClipRadius,
        );
      }
    }

    body ??= _placeholder(scheme);

    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        if (_resolving)
          ColoredBox(
            color: widget.showChrome
                ? const Color(0x99111318)
                : scheme.surface.withValues(alpha: 0.72),
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: widget.showChrome
                      ? const Color(0xFF8AB4FF)
                      : scheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = _displayFileName(widget.fileName, widget.networkUrl) ??
        switch (_resolvedKind) {
          _AnimKind.pag => 'animation.pag',
          _AnimKind.swf => 'animation.swf',
          _AnimKind.json =>
            giftAnimationLooksLikeLottie(widget.fileName) ||
                    giftAnimationLooksLikeLottie(widget.networkUrl)
                ? 'animation.lottie'
                : 'animation.json',
          _AnimKind.image =>
            giftAnimationLooksLikeGif(widget.fileName) ||
                    giftAnimationLooksLikeGif(widget.networkUrl)
                ? 'animation.gif'
                : 'animation.png',
          _ => 'animation.mp4',
        };
    final badge = _badgeFor(
      _resolvedKind ?? _kindFromName(widget.fileName, widget.networkUrl),
      widget.fileName,
      widget.networkUrl,
    );

    final compact = widget.compact;
    final expandToFill = widget.expandToFill;
    final radius = compact ? 10.0 : 14.0;
    final headerPad = compact
        ? const EdgeInsets.fromLTRB(8, 6, 4, 4)
        : const EdgeInsets.fromLTRB(12, 10, 8, 8);
    final previewPad = compact
        ? const EdgeInsets.fromLTRB(6, 0, 6, 6)
        : const EdgeInsets.fromLTRB(10, 0, 10, 10);
    final footerPad = compact
        ? const EdgeInsets.fromLTRB(8, 0, 8, 8)
        : const EdgeInsets.fromLTRB(12, 0, 12, 12);

    final stageRadius = widget.showChrome ? (compact ? 8.0 : 12.0) : 0.0;

    Widget previewStage = _buildPreview(scheme);
    if (widget.showChrome) {
      previewStage = ClipRRect(
        borderRadius: BorderRadius.circular(stageRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: previewStage,
        ),
      );
    }

    if (!widget.showChrome) {
      return SizedBox.expand(child: previewStage);
    }

    final header = Padding(
      padding: headerPad,
      child: Row(
        children: [
          Flexible(
            child: Wrap(
              spacing: compact ? 6 : 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8,
                    vertical: compact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.animation_rounded,
                        size: compact ? 12 : 14,
                        color: scheme.primary,
                      ),
                      SizedBox(width: compact ? 4 : 5),
                      Text(
                        'Animation',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          fontSize: compact ? 10 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 5 : 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClear != null)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(
                minWidth: compact ? 30 : 34,
                minHeight: compact ? 30 : 34,
              ),
              onPressed: widget.onClear,
              icon: Icon(
                Icons.close_rounded,
                size: compact ? 16 : 18,
                color: scheme.error,
              ),
            ),
        ],
      ),
    );

    final footer = Padding(
      padding: footerPad,
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: expandToFill ? MainAxisSize.max : MainAxisSize.min,
          children: [
            header,
            if (expandToFill)
              Expanded(
                child: Padding(
                  padding: previewPad,
                  child: previewStage,
                ),
              )
            else
              Padding(
                padding: previewPad,
                child: AspectRatio(
                  aspectRatio: compact ? 16 / 9 : 16 / 10,
                  child: previewStage,
                ),
              ),
            footer,
          ],
        ),
      ),
    );
  }
}

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
    this.embeddedPreview = false,
    this.clipBorderRadius = 0,
  });

  final Uint8List bytes;
  final String fileName;
  final bool embeddedPreview;
  final double clipBorderRadius;

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
      await controller.setVolume(1);
      await controller.play();
      if (!mounted) return;
      if (widget.embeddedPreview && widget.clipBorderRadius > 0) {
        styleGiftEmbeddedVideo(uri, borderRadius: widget.clipBorderRadius);
      }
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
      embeddedPreview: widget.embeddedPreview,
      clipBorderRadius: widget.clipBorderRadius,
    );
  }
}

class _NetworkVideoPreview extends StatefulWidget {
  const _NetworkVideoPreview({
    required this.url,
    this.embeddedPreview = false,
    this.clipBorderRadius = 0,
  });

  final String url;
  final bool embeddedPreview;
  final double clipBorderRadius;

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
      await controller.setVolume(1);
      await controller.play();
      if (!mounted) return;
      if (widget.embeddedPreview && widget.clipBorderRadius > 0) {
        styleGiftEmbeddedVideo(resolved, borderRadius: widget.clipBorderRadius);
      }
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
      embeddedPreview: widget.embeddedPreview,
      clipBorderRadius: widget.clipBorderRadius,
    );
  }
}

class _GiftVideoSurface extends StatelessWidget {
  const _GiftVideoSurface({
    required this.controller,
    required this.ready,
    required this.failed,
    this.embeddedPreview = false,
    this.clipBorderRadius = 0,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool failed;
  final bool embeddedPreview;
  final double clipBorderRadius;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _framedVideo(
    VideoPlayerController controller,
    VideoPlayerValue value,
  ) {
    if (embeddedPreview) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: value.size.width,
          height: value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ar = value.aspectRatio;
        if (ar <= 0 || !ar.isFinite) {
          return Center(child: VideoPlayer(controller));
        }

        var maxW = constraints.maxWidth;
        var maxH = constraints.maxHeight;
        if (!maxW.isFinite || maxW <= 0) maxW = value.size.width;
        if (!maxH.isFinite || maxH <= 0) maxH = value.size.height;

        late final double w;
        late final double h;
        if (maxW / maxH > ar) {
          h = maxH;
          w = h * ar;
        } else {
          w = maxW;
          h = w / ar;
        }

        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onLightStage = embeddedPreview;

    if (failed || controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 34,
              color: onLightStage ? scheme.onSurfaceVariant : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview unavailable',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onLightStage ? scheme.onSurface : Colors.white70,
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
                    color: onLightStage
                        ? scheme.onSurfaceVariant
                        : Colors.white70,
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

        return _clipIfNeeded(
          Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: _framedVideo(controller!, value),
            ),
            if (!embeddedPreview)
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
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Sound · Loop',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
        ),
        );
      },
    );
  }

  Widget _clipIfNeeded(Widget child) {
    if (clipBorderRadius <= 0) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(clipBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
