import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Non-web stub — SWF (Flash) playback via Ruffle is only available on Flutter Web.
class GiftSwfPlayer extends StatelessWidget {
  const GiftSwfPlayer({
    super.key,
    this.bytes,
    this.networkUrl,
  });

  final Uint8List? bytes;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'SWF preview requires Flutter Web',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
