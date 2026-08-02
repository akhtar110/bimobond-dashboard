import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// Web-native SVG renderer using an HTML `<img>` (handles CSS-styled SVGs
/// that [flutter_svg] cannot paint).
class GiftNativeSvgView extends StatefulWidget {
  const GiftNativeSvgView({
    super.key,
    this.bytes,
    this.networkUrl,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final BoxFit fit;
  final Widget? errorWidget;

  @override
  State<GiftNativeSvgView> createState() => _GiftNativeSvgViewState();
}

class _GiftNativeSvgViewState extends State<GiftNativeSvgView> {
  static int _seq = 0;

  late final String _viewType;
  String? _objectUrl;
  var _failed = false;
  var _factoryRegistered = false;

  @override
  void initState() {
    super.initState();
    _seq += 1;
    final token = DateTime.now().microsecondsSinceEpoch;
    _viewType = 'gift-svg-img-$token-$_seq';
    _registerFactory();
  }

  @override
  void didUpdateWidget(covariant GiftNativeSvgView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Factories are immutable once registered; recreate the platform view
    // when the source changes by swapping the widget key at the call site.
    // If source changes without a new key, rebuild src on the live element.
    if (_sourceKey(widget) != _sourceKey(oldWidget)) {
      _revokeObjectUrl();
      _failed = false;
      _applySrcToExisting();
    }
  }

  @override
  void dispose() {
    _revokeObjectUrl();
    super.dispose();
  }

  String _sourceKey(GiftNativeSvgView w) {
    final b = w.bytes;
    if (b != null && b.isNotEmpty) {
      return 'b:${identityHashCode(b)}:${b.length}';
    }
    return 'u:${w.networkUrl ?? ''}';
  }

  String _cssObjectFit(BoxFit fit) {
    return switch (fit) {
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'scale-down',
      BoxFit.fitHeight => 'scale-down',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scale-down',
      BoxFit.contain => 'contain',
    };
  }

  String? _resolvedNetworkUrl() {
    final raw = widget.networkUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    return resolveMediaUrl(raw) ?? raw;
  }

  void _revokeObjectUrl() {
    final url = _objectUrl;
    if (url == null) return;
    html.Url.revokeObjectUrl(url);
    _objectUrl = null;
  }

  String? _buildSrc() {
    final bytes = widget.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      _objectUrl = html.Url.createObjectUrlFromBlob(
        html.Blob([bytes], 'image/svg+xml'),
      );
      return _objectUrl;
    }
    return _resolvedNetworkUrl();
  }

  void _registerFactory() {
    if (_factoryRegistered) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..id = _viewType
        ..draggable = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.margin = '0'
        ..style.padding = '0'
        ..style.border = '0'
        ..style.objectFit = _cssObjectFit(widget.fit)
        ..style.objectPosition = 'center';

      final src = _buildSrc();
      if (src == null || src.isEmpty) {
        _scheduleFailed();
      } else {
        img.src = src;
      }

      img.onError.listen((_) => _scheduleFailed());
      img.onLoad.listen((_) {
        if (!mounted || !_failed) return;
        setState(() => _failed = false);
      });

      return img;
    });
    _factoryRegistered = true;
  }

  void _applySrcToExisting() {
    final el = html.document.getElementById(_viewType);
    if (el is! html.ImageElement) return;
    el.style.objectFit = _cssObjectFit(widget.fit);
    final src = _buildSrc();
    if (src == null || src.isEmpty) {
      _scheduleFailed();
      return;
    }
    el.src = src;
  }

  void _scheduleFailed() {
    if (!mounted) {
      _failed = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _failed) return;
      setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }
    return HtmlElementView(viewType: _viewType);
  }
}
