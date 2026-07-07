import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Keeps a loaded feed thumbnail visible across route transitions and bloc patches.
class PostListThumbnail extends StatefulWidget {
  const PostListThumbnail({
    super.key,
    required this.postId,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
  });

  final String postId;
  final String? imageUrl;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? error;

  @override
  State<PostListThumbnail> createState() => _PostListThumbnailState();
}

class _PostListThumbnailState extends State<PostListThumbnail> {
  ImageProvider? _provider;
  String? _loadedUrl;
  int _retryGeneration = 0;

  @override
  void initState() {
    super.initState();
    _syncProvider(force: true);
  }

  @override
  void didUpdateWidget(PostListThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _retryGeneration = 0;
      _loadedUrl = null;
      _provider = null;
      _syncProvider(force: true);
      return;
    }
    if (oldWidget.imageUrl != widget.imageUrl) {
      _syncProvider(force: true);
    }
  }

  String? get _displayUrl {
    final url = widget.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return _loadedUrl;
  }

  void _syncProvider({required bool force}) {
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      if (force && _loadedUrl == null) {
        _provider = null;
      }
      return;
    }

    if (!force && url == _loadedUrl) return;

    _loadedUrl = url;
    _provider = CachedNetworkImageProvider(
      url,
      cacheKey: 'post_list_thumb_${widget.postId}_$url',
    );
  }

  void _retry() {
    setState(() {
      _retryGeneration++;
      _syncProvider(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _displayUrl;
    if (url == null || url.isEmpty || _provider == null) {
      return widget.error?.call(context) ?? const SizedBox.shrink();
    }

    return Image(
      key: ValueKey(
        'post_list_thumb_${widget.postId}_${url}_$_retryGeneration',
      ),
      image: _provider!,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder?.call(context) ?? child;
      },
      errorBuilder: (context, error, stackTrace) {
        final fallback = widget.error?.call(context);
        if (fallback == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: _retry,
          behavior: HitTestBehavior.opaque,
          child: fallback,
        );
      },
    );
  }
}
