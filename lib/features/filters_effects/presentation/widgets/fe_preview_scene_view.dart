import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../constants/fe_preview_assets.dart';
import '../utils/fe_filter_preview_support.dart';
import '../utils/fe_preview_adjustment_matrix.dart';
import '../utils/fe_preview_cache.dart';
import '../utils/fe_preview_color_utils.dart';
import '../utils/fe_preview_cube_lut.dart';
import '../utils/fe_preview_face_geometry.dart';
import '../utils/fe_preview_image_loader.dart';
import '../utils/fe_preview_lut_processor.dart';

class FePreviewSceneView extends StatefulWidget {
  const FePreviewSceneView({
    super.key,
    this.previewColorHex,
    this.renderType,
    this.lutUrl,
    this.lutPreviewBytes,
    this.lutPreviewFilename,
    this.colorMatrix = const [],
    this.adjustments = const {},
    this.filterSettings,
    this.thumbnailUrl,
    this.effectRenderType,
    this.effectAssetUrl,
    this.effectEmoji,
    this.effectAnchor = const {},
    this.effectStickers = const [],
    this.distortionPreset,
    this.externalLoading = false,
  });

  final String? previewColorHex;
  final String? renderType;
  final String? lutUrl;
  final Uint8List? lutPreviewBytes;
  final String? lutPreviewFilename;
  final List<double> colorMatrix;
  final Map<String, int> adjustments;
  final FilterSettingsEntity? filterSettings;
  final String? thumbnailUrl;
  final String? effectRenderType;
  final String? effectAssetUrl;
  final String? effectEmoji;
  final Map<String, dynamic> effectAnchor;
  final List<CameraEffectStickerLayer> effectStickers;
  final String? distortionPreset;
  final bool externalLoading;

  @override
  State<FePreviewSceneView> createState() => _FePreviewSceneViewState();
}

class _FePreviewSceneViewState extends State<FePreviewSceneView> {
  ui.Image? _processedImage;
  bool _isProcessing = false;
  String? _processingKey;

  @override
  void didUpdateWidget(covariant FePreviewSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldReprocessLut(oldWidget)) {
      _scheduleLutProcessing();
    }
  }

  @override
  void initState() {
    super.initState();
    FeFilterPreviewSupport.ensureConfigured();
    _scheduleLutProcessing();
  }

  @override
  void dispose() {
    _processedImage?.dispose();
    _processedImage = null;
    super.dispose();
  }

  bool _shouldReprocessLut(FePreviewSceneView oldWidget) {
    return oldWidget.lutUrl != widget.lutUrl ||
        oldWidget.renderType != widget.renderType ||
        oldWidget.lutPreviewBytes != widget.lutPreviewBytes ||
        oldWidget.lutPreviewFilename != widget.lutPreviewFilename;
  }

  void _scheduleLutProcessing() {
    final isLut = CameraFilterRenderTypeApi.isLut(widget.renderType ?? '');
    if (!isLut) {
      if (_processedImage != null || _isProcessing) {
        setState(() {
          _processedImage?.dispose();
          _processedImage = null;
          _isProcessing = false;
          _processingKey = null;
        });
      }
      return;
    }

    final lutUrl = widget.lutUrl?.trim();
    final localBytes = widget.lutPreviewBytes;
    final hasLocalLutBytes = localBytes != null && localBytes.isNotEmpty;
    if ((lutUrl == null || lutUrl.isEmpty) && !hasLocalLutBytes) {
      if (_processedImage != null || _isProcessing) {
        setState(() {
          _processedImage?.dispose();
          _processedImage = null;
          _isProcessing = false;
          _processingKey = null;
        });
      }
      return;
    }

    final key = hasLocalLutBytes
        ? 'local:${localBytes.hashCode}:${widget.lutPreviewFilename ?? ''}'
        : lutUrl!;
    if (_processingKey == key && _processedImage != null) {
      return;
    }

    _processedImage?.dispose();
    _processedImage = null;
    _processingKey = key;
    unawaited(_processLut(lutUrl, key, localBytes: localBytes));
  }

  Future<ui.Image?> _decodeImageBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<void> _processLut(
    String? lutUrl,
    String key, {
    Uint8List? localBytes,
  }) async {
    if (!mounted || _processingKey != key) return;
    setState(() => _isProcessing = true);
    ui.Image? lutImage;
    try {
      final resolvedLutUrl = (lutUrl != null && lutUrl.isNotEmpty)
          ? (resolveMediaUrl(lutUrl) ?? lutUrl)
          : null;

      // Load scene + LUT bytes in parallel when both are needed.
      final needsNetworkLut = (localBytes == null || localBytes.isEmpty) &&
          resolvedLutUrl != null &&
          resolvedLutUrl.isNotEmpty;

      final sceneFuture = FePreviewCache.loadSceneImage();
      final lutBytesFuture = needsNetworkLut
          ? loadFePreviewNetworkBytes(resolvedLutUrl)
          : Future<Uint8List?>.value(localBytes);

      final results = await Future.wait<Object?>([sceneFuture, lutBytesFuture]);
      if (!mounted || _processingKey != key) {
        _finishProcessing(key, processed: null);
        return;
      }

      final scene = results[0] as ui.Image?;
      var bytes = results[1] as Uint8List?;
      if (scene == null) {
        _finishProcessing(key, processed: null);
        return;
      }

      ui.Image? processed;

      if (bytes != null && bytes.isNotEmpty) {
        final preferCube = isFeCubeLutSource(
          url: lutUrl,
          filename: widget.lutPreviewFilename,
          bytes: bytes,
        );

        // Always apply .cube at high resolution — never soft-scale to ~240px.
        if (preferCube) {
          final cube = parseFeCubeLutBytes(bytes);
          if (cube != null) {
            processed = await applyFePreviewCubeLut(
              scene,
              cube,
              maxWidth: 720,
            ).timeout(
              const Duration(seconds: 20),
              onTimeout: () => null,
            );
          }
        }

        // PNG/JPEG Hald CLUT (or server-converted LUT).
        if (processed == null && isFeImageLutBytes(bytes)) {
          lutImage = await _decodeImageBytes(bytes);
          final decodedLut = lutImage;
          if (decodedLut != null) {
            processed = await applyFePreviewLut(
              scene,
              decodedLut,
              maxWidth: 720,
            ).timeout(
              const Duration(seconds: 12),
              onTimeout: () => null,
            );
          }
        }
      }

      if (!mounted || _processingKey != key) return;
      _finishProcessing(key, processed: processed);
    } catch (_) {
      if (!mounted || _processingKey != key) return;
      _finishProcessing(key, processed: null);
    } finally {
      lutImage?.dispose();
    }
  }

  void _finishProcessing(String key, {required ui.Image? processed}) {
    if (!mounted || _processingKey != key) {
      processed?.dispose();
      return;
    }
    setState(() {
      _processedImage?.dispose();
      _processedImage = processed;
      _isProcessing = false;
    });
  }

  bool get _showsLoadingOverlay => widget.externalLoading || _isProcessing;

  @override
  Widget build(BuildContext context) {
    final matrix = _resolveColorMatrix();
    final showsFaceEffects = _showsFaceEffects();

    Widget scene;
    if (_processedImage != null) {
      scene = RawImage(
        image: _processedImage,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    } else {
      scene = Image.asset(
        FePreviewAssets.previewScene,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const _PreviewFallbackScene(),
      );
    }

    if (matrix != null) {
      scene = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: scene);
    }

    scene = _PreviewColorTint(hex: widget.previewColorHex, child: scene);

    if (_showsDistortion()) {
      scene = _DistortionPreviewLayer(
        preset: widget.distortionPreset,
        child: scene,
      );
    }

    final lipTintHex = widget.filterSettings?.lipTint?.trim();
    final lipStrength = widget.filterSettings?.lipStrength ?? 0;
    final hasLipTint = lipTintHex != null && lipTintHex.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        scene,
        if (hasLipTint)
          _LipTintOverlay(hex: lipTintHex, strength: lipStrength),
        if (_showsLoadingOverlay)
          const ColoredBox(
            color: Color(0x44000000),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        if (showsFaceEffects) const _FaceGuideOverlay(),
        ..._buildEffectOverlays(),
      ],
    );
  }

  List<Widget> _buildEffectOverlays() {
    final type = CameraEffectRenderTypeApi.fromResponse(
      widget.effectRenderType ?? '',
    );

    if (CameraEffectRenderTypeApi.isComposite(type)) {
      return [
        for (final layer in widget.effectStickers)
          if (layer.hasAsset)
            _AnchoredStickerOverlay(
              key: ValueKey(
                '${layer.assetUrl}|${layer.assetAsset}|${layer.anchor}',
              ),
              assetUrl: _resolveStickerUrl(layer),
              emoji: null,
              anchor: layer.anchor,
            ),
      ];
    }

    if (CameraEffectRenderTypeApi.isSticker(type)) {
      final url = widget.effectAssetUrl?.trim();
      final emoji = widget.effectEmoji?.trim();
      if ((url == null || url.isEmpty) && (emoji == null || emoji.isEmpty)) {
        return const [];
      }
      return [
        _AnchoredStickerOverlay(
          key: ValueKey('$url|$emoji|${widget.effectAnchor}'),
          assetUrl: url != null && url.isNotEmpty
              ? resolveMediaUrl(url) ?? url
              : null,
          emoji: emoji,
          anchor: widget.effectAnchor,
        ),
      ];
    }

    if (CameraEffectRenderTypeApi.isDistortion(type)) {
      return [
        _DistortionBadge(preset: widget.distortionPreset),
      ];
    }

    return const [];
  }

  String? _resolveStickerUrl(CameraEffectStickerLayer layer) {
    final url = layer.assetUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return resolveMediaUrl(url) ?? url;
    }
    return null;
  }

  bool _showsFaceEffects() {
    final type = CameraEffectRenderTypeApi.fromResponse(
      widget.effectRenderType ?? '',
    );
    return CameraEffectRenderTypeApi.isSticker(type) ||
        CameraEffectRenderTypeApi.isComposite(type) ||
        CameraEffectRenderTypeApi.isDistortion(type);
  }

  bool _showsDistortion() {
    return CameraEffectRenderTypeApi.isDistortion(
      widget.effectRenderType ?? '',
    );
  }

  List<double>? _resolveColorMatrix() {
    return resolveFePreviewFilterMatrix(
      renderType: widget.renderType,
      filterSettings: widget.filterSettings,
      adjustments: widget.adjustments,
      colorMatrix: widget.colorMatrix,
    );
  }
}

class _PreviewColorTint extends StatelessWidget {
  const _PreviewColorTint({required this.child, this.hex});

  final Widget child;
  final String? hex;

  @override
  Widget build(BuildContext context) {
    final trimmed = hex?.trim();
    if (trimmed == null || trimmed.isEmpty) return child;

    final gradient = previewGradientForHex(trimmed);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradient.first.withValues(alpha: 0.18),
                gradient.last.withValues(alpha: 0.48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFallbackScene extends StatelessWidget {
  const _PreviewFallbackScene();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
        ),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, size: 72, color: Colors.white70),
      ),
    );
  }
}

class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.22),
      child: Container(
        width: 92,
        height: 118,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AnchoredStickerOverlay extends StatelessWidget {
  const _AnchoredStickerOverlay({
    super.key,
    required this.anchor,
    this.assetUrl,
    this.emoji,
  });

  final String? assetUrl;
  final String? emoji;
  final Map<String, dynamic> anchor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final pin = FePreviewFaceGeometry.resolvePin(size: size, anchor: anchor);
        final width = FePreviewFaceGeometry.resolveStickerWidth(
          size: size,
          anchor: anchor,
        );
        final height = FePreviewFaceGeometry.resolveStickerHeight(
          size: size,
          anchor: anchor,
          width: width,
        );
        final pivot = FePreviewFaceGeometry.resolvePivotFraction(anchor);
        final left = pin.dx - width * pivot.dx;
        final top = pin.dy - height * pivot.dy;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: _StickerVisual(assetUrl: assetUrl, emoji: emoji),
            ),
          ],
        );
      },
    );
  }
}

class _StickerVisual extends StatelessWidget {
  const _StickerVisual({this.assetUrl, this.emoji});

  final String? assetUrl;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    if (assetUrl != null && assetUrl!.isNotEmpty) {
      return Image.network(
        assetUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _emojiFallback(),
      );
    }
    return _emojiFallback();
  }

  Widget _emojiFallback() {
    final value = emoji?.trim();
    if (value != null && value.isNotEmpty) {
      return Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 42,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12),
            ],
          ),
        ),
      );
    }
    return Icon(
      Icons.emoji_emotions_outlined,
      size: 36,
      color: Colors.white.withValues(alpha: 0.85),
    );
  }
}

class _DistortionPreviewLayer extends StatelessWidget {
  const _DistortionPreviewLayer({required this.child, this.preset});

  final Widget child;
  final String? preset;

  @override
  Widget build(BuildContext context) {
    final normalized = CameraDistortionPresetApi.fromResponse(preset ?? '');
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Align(
            alignment: const Alignment(0, -0.22),
            child: Transform(
              alignment: Alignment.center,
              transform: switch (normalized) {
                CameraDistortionPresetApi.bigEyes => Matrix4.diagonal3Values(
                  1.08,
                  1.12,
                  1,
                ),
                CameraDistortionPresetApi.bigLips => Matrix4.diagonal3Values(
                  1.04,
                  1.08,
                  1,
                ),
                CameraDistortionPresetApi.longNose => Matrix4.diagonal3Values(
                  1.0,
                  1.14,
                  1,
                ),
                _ => Matrix4.identity(),
              },
              child: Container(
                width: 92,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.45),
                    width: 2,
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

class _DistortionBadge extends StatelessWidget {
  const _DistortionBadge({this.preset});

  final String? preset;

  @override
  Widget build(BuildContext context) {
    final icon = switch (CameraDistortionPresetApi.fromResponse(preset ?? '')) {
      CameraDistortionPresetApi.bigEyes => Icons.remove_red_eye_outlined,
      CameraDistortionPresetApi.bigLips => Icons.sentiment_satisfied_alt,
      CameraDistortionPresetApi.longNose => Icons.arrow_downward_rounded,
      _ => Icons.face_retouching_natural_rounded,
    };

    return Align(
      alignment: const Alignment(0, -0.22),
      child: Icon(icon, size: 46, color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}

class _LipTintOverlay extends StatelessWidget {
  const _LipTintOverlay({
    required this.hex,
    required this.strength,
  });

  final String hex;
  final int strength;

  @override
  Widget build(BuildContext context) {
    final color = parsePreviewColorHex(hex);
    if (color == null) return const SizedBox.shrink();

    final effectiveStrength = strength <= 0 ? 60 : strength.clamp(1, 100);
    final opacity = (effectiveStrength / 100.0 * 0.65 + 0.15).clamp(0.0, 0.85);

    return Align(
      alignment: const Alignment(0.0, 0.04),
      child: Container(
        width: 54,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(27, 11)),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.7),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.6),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}
