import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// Emoji values may be Unicode text or an uploaded image URL stored in `emoji`.
abstract final class FeEffectEmojiDisplay {
  static bool isImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('/');
  }

  static String? resolvedImageUrl(String? value) {
    if (!isImageUrl(value)) return null;
    return resolveMediaUrl(value);
  }

  static String? listImageUrl({String? emoji, String? assetUrl}) {
    final fromEmoji = resolvedImageUrl(emoji);
    if (fromEmoji != null) return fromEmoji;
    final fromAsset = assetUrl?.trim();
    if (fromAsset == null || fromAsset.isEmpty) return null;
    return resolveMediaUrl(fromAsset);
  }

  static String? textEmoji(String? emoji) {
    if (emoji == null || emoji.trim().isEmpty || isImageUrl(emoji)) return null;
    return emoji.trim();
  }

  static Widget build({
    required String? emoji,
    String? assetUrl,
    double size = 32,
    TextStyle? textStyle,
    String fallback = '—',
  }) {
    final imageUrl = listImageUrl(emoji: emoji, assetUrl: assetUrl);
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(fallback, style: textStyle),
        ),
      );
    }

    final text = textEmoji(emoji);
    if (text != null) {
      return Text(
        text,
        style: textStyle ?? TextStyle(fontSize: size * 0.75),
      );
    }

    return Text(fallback, style: textStyle);
  }
}
