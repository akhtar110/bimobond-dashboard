import 'package:flutter/material.dart';

import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_media_entity.dart';
import 'media_carousel_item.dart';

class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.post,
    this.fit = BoxFit.contain,
    this.videoLooping = true,
    this.soundLooping = true,
    this.onAspectRatioChanged,
  });

  final ManagedPostEntity post;
  final BoxFit fit;
  final bool videoLooping;
  final bool soundLooping;
  final ValueChanged<double>? onAspectRatioChanged;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, double> _aspectRatios = {};

  List<PostMediaEntity> get _media => widget.post.media;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(PostMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != widget.post.id ||
        !_sameMedia(oldWidget.post.media, widget.post.media)) {
      _currentIndex = 0;
      _aspectRatios.clear();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  bool _sameMedia(List<PostMediaEntity> a, List<PostMediaEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onRatioDetermined(int index, double ratio) {
    if (_aspectRatios[index] == ratio) return;
    _aspectRatios[index] = ratio;
    if (index == _currentIndex) {
      widget.onAspectRatioChanged?.call(ratio);
    }
  }

  void _notifyAspectForIndex(int index) {
    if (_aspectRatios.containsKey(index)) {
      widget.onAspectRatioChanged?.call(_aspectRatios[index]!);
      return;
    }
    final item = _media[index];
    widget.onAspectRatioChanged?.call(item.isVideo ? 9 / 16 : 1.0);
  }

  void _goToPrevious() {
    if (_currentIndex <= 0 || !_pageController.hasClients) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNext() {
    if (_currentIndex >= _media.length - 1 || !_pageController.hasClients) {
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildCarouselNavButton({
    required ColorScheme scheme,
    required IconData icon,
    required VoidCallback? onPressed,
    required Alignment alignment,
  }) {
    final enabled = onPressed != null;

    final backgroundColor = enabled
        ? scheme.primaryContainer.withValues(alpha: 0.94)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final foregroundColor =
        enabled ? scheme.primary : scheme.onSurfaceVariant;
    final borderColor = enabled
        ? scheme.primary.withValues(alpha: 0.42)
        : scheme.outlineVariant.withValues(alpha: 0.65);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Material(
          color: Colors.transparent,
          elevation: enabled ? 2 : 0,
          shadowColor: scheme.shadow.withValues(alpha: 0.18),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: scheme.primary.withValues(alpha: 0.12),
            highlightColor: scheme.primary.withValues(alpha: 0.08),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: enabled ? 1 : 0.55,
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasAttachedSound =>
      widget.post.shouldPlayAttachedSound &&
      widget.post.attachedSoundPlayUrl != null;

  Widget _buildAttachedSoundOverlay() {
    if (!_hasAttachedSound) return const SizedBox.shrink();
    final audioUrl = widget.post.attachedSoundPlayUrl!;
    return PostAttachedSoundPreview(
      key: ValueKey('attached_sound_${widget.post.id}_$audioUrl'),
      audioUrl: audioUrl,
      autoplay: true,
      looping: widget.soundLooping,
    );
  }

  Widget _buildCarouselWithControls(double mediaHeight, ColorScheme scheme) {
    final hasMultiple = _media.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPageView(mediaHeight),
        _buildAttachedSoundOverlay(),
        if (hasMultiple) ...[
          _buildCarouselNavButton(
            scheme: scheme,
            icon: Icons.chevron_left_rounded,
            onPressed: _currentIndex > 0 ? _goToPrevious : null,
            alignment: Alignment.centerLeft,
          ),
          _buildCarouselNavButton(
            scheme: scheme,
            icon: Icons.chevron_right_rounded,
            onPressed:
                _currentIndex < _media.length - 1 ? _goToNext : null,
            alignment: Alignment.centerRight,
          ),
        ],
      ],
    );
  }

  Widget _buildIndicators(ColorScheme scheme) {
    if (_media.length <= 1) {
      return const SizedBox(height: 16);
    }

    return SizedBox(
      height: 36,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_media.length, (index) {
            final selected = index == _currentIndex;

            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFallbackMedia(double mediaHeight) {
    final isVideoPost = widget.post.type.toUpperCase() == 'VIDEO';
    final preview = PostMediaPreview(
      thumbnailUrl: isVideoPost ? null : widget.post.displayThumbnailUrl,
      videoUrl: widget.post.videoUrl,
      hlsUrl: widget.post.hlsUrl,
      type: widget.post.type,
      fit: widget.fit,
      height: mediaHeight,
      autoplay: true,
      looping: widget.videoLooping,
      onAspectRatioDetermined: widget.onAspectRatioChanged,
    );

    final soundOverlay = _buildAttachedSoundOverlay();
    if (!_hasAttachedSound) return preview;

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        soundOverlay,
      ],
    );
  }

  Widget _buildPageView(double mediaHeight) {
    return PageView.builder(
      key: PageStorageKey<String>('post_media_${widget.post.id}'),
      controller: _pageController,
      itemCount: _media.length,
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        _notifyAspectForIndex(index);
      },
      itemBuilder: (context, index) {
        final item = _media[index];
        return MediaCarouselItem(
          key: ValueKey('${widget.post.id}_${item.url}_$index'),
          item: item,
          height: mediaHeight,
          fit: widget.fit,
          isActive: index == _currentIndex,
          videoLooping: widget.videoLooping,
          hlsUrl: widget.post.hlsUrl,
          onAspectRatioDetermined: (ratio) => _onRatioDetermined(index, ratio),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const indicatorHeight = 36.0;
        final hasMultiple = _media.length > 1;
        final reservedIndicator = hasMultiple ? indicatorHeight : 0.0;

        final mediaHeight = (constraints.maxHeight - reservedIndicator)
            .clamp(120.0, double.infinity)
            .toDouble();

        if (_media.isEmpty) {
          return _buildFallbackMedia(
            constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : mediaHeight,
          );
        }

        return Column(
          children: [
            SizedBox(
              height: mediaHeight,
              width: double.infinity,
              child: _buildCarouselWithControls(mediaHeight, scheme),
            ),
            if (hasMultiple) _buildIndicators(scheme),
          ],
        );
      },
    );
  }
}
