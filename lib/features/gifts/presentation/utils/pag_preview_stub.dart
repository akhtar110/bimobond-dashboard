import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Non-web stub — PAG canvas playback is only available on Flutter Web.
class GiftPagPlayer extends StatelessWidget {
  const GiftPagPlayer({
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
        'PAG preview requires Flutter Web',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
