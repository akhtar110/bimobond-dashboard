import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../injection_container.dart' as di;
import '../../domain/entities/post_report_entities.dart';
import '../services/post_report_media_lookup.dart';

/// Post report thumbnail — mirrors [PostCard] media preview behavior.
class PostReportThumbnail extends StatefulWidget {
  const PostReportThumbnail({
    super.key,
    required this.post,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 8,
  });

  final PostReportListItem post;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<PostReportThumbnail> createState() => _PostReportThumbnailState();
}

class _PostReportThumbnailState extends State<PostReportThumbnail> {
  String? _resolvedUrl;
  bool _loadingLookup = false;

  PostReportMediaLookup get _lookup => di.sl<PostReportMediaLookup>();

  @override
  void initState() {
    super.initState();
    _syncFromPost(widget.post);
  }

  @override
  void didUpdateWidget(PostReportThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.imagePreviewUrl != widget.post.imagePreviewUrl) {
      _syncFromPost(widget.post);
    }
  }

  void _syncFromPost(PostReportListItem post) {
    _resolvedUrl = post.imagePreviewUrl;
    if (post.needsAdminMediaLookup) {
      _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    if (_loadingLookup || (_resolvedUrl != null && _resolvedUrl!.isNotEmpty)) {
      return;
    }
    _loadingLookup = true;
    if (mounted) setState(() {});

    try {
      final url = await _lookup.previewUrlFor(widget.post);
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _resolvedUrl = url);
      }
    } finally {
      _loadingLookup = false;
      if (mounted) setState(() {});
    }
  }

  bool get _isVideo => widget.post.type.toUpperCase() == 'VIDEO';
  bool get _isCarousel => widget.post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = _resolvedUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _Placeholder(
                  scheme: scheme,
                  loading: true,
                ),
                errorWidget: (_, __, ___) => _Placeholder(scheme: scheme),
              )
            else if (_loadingLookup)
              _Placeholder(scheme: scheme, loading: true)
            else
              _Placeholder(scheme: scheme),
            if (_isVideo)
              Center(
                child: Container(
                  width: widget.width * 0.42,
                  height: widget.width * 0.42,
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: scheme.onPrimary,
                    size: widget.width * 0.28,
                  ),
                ),
              ),
            if (_isCarousel)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.collections_outlined,
                    color: scheme.onPrimary,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.scheme,
    this.loading = false,
  });

  final ColorScheme scheme;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            : Icon(
                Icons.image_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
