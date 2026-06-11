import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// Guards against video/HLS URLs being loaded as raster images.
bool isNonImageMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return true;
  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m3u8') ||
      path.endsWith('.mkv') ||
      path.endsWith('.avi');
}

class ReportSafeAvatar extends StatelessWidget {
  const ReportSafeAvatar({
    super.key,
    required this.url,
    required this.fallbackLabel,
    this.radius = 28,
  });

  final String? url;
  final String fallbackLabel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = fallbackLabel.trim().isNotEmpty
        ? fallbackLabel.trim()[0].toUpperCase()
        : '?';
    final resolved = resolveMediaUrl(url);

    if (resolved == null || isNonImageMediaUrl(resolved)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.72,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.surfaceContainerHighest,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: resolved,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => ColoredBox(
            color: scheme.primaryContainer,
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportSafeThumbnail extends StatelessWidget {
  const ReportSafeThumbnail({
    super.key,
    required this.url,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.video_library_outlined,
  });

  final String? url;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(url);

    if (resolved == null || isNonImageMediaUrl(resolved)) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(fallbackIcon, size: 20, color: scheme.onSurfaceVariant),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: scheme.surfaceContainerHigh,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: scheme.surfaceContainerHigh,
          child: Icon(fallbackIcon, size: 20, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
