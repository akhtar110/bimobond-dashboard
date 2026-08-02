import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Non-web fallback: cannot host a native HTML `<img>`, so show [errorWidget].
class GiftNativeSvgView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return errorWidget ?? const SizedBox.shrink();
  }
}
