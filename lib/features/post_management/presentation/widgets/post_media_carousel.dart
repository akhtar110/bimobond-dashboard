import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/managed_post_entity.dart';
import 'media_carousel_item.dart';

class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.post,
    this.fit = BoxFit.contain,
    this.videoLooping = true,
    this.soundLooping = true,
    this.showSeekBar = true,
    this.onAspectRatioChanged,
  });

  final ManagedPostEntity post;
  final BoxFit fit;
  final bool videoLooping;
  final bool soundLooping;
  final bool showSeekBar;
  final ValueChanged<double>? onAspectRatioChanged;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, double> _aspectRatios = {};
  String? _linkedSoundUrl;

  List<PostMediaEntity> get _media => widget.post.media;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _linkPlaybackGroup();
  }

  @override
  void didUpdateWidget(PostMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != widget.post.id ||
        !_sameMedia(oldWidget.post.media, widget.post.media) ||
        oldWidget.post.attachedSoundPlayUrl !=
            widget.post.attachedSoundPlayUrl) {
      if (oldWidget.post.id != widget.post.id ||
          !_sameMedia(oldWidget.post.media, widget.post.media)) {
        _currentIndex = 0;
        _aspectRatios.clear();
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
      _linkPlaybackGroup();
    }
  }

  String? _resolveUrl(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return resolveMediaUrl(trimmed) ?? trimmed;
  }

  String? _primaryVideoUrl() {
    for (final item in _media) {
      if (item.isVideo) return _resolveUrl(item.url);
    }
    final direct = widget.post.videoUrl;
    if (direct != null && direct.trim().isNotEmpty) {
      return _resolveUrl(direct);
    }
    final hls = widget.post.hlsUrl;
    if (hls != null && hls.trim().isNotEmpty) {
      return _resolveUrl(hls);
    }
    return null;
  }

  void _unlinkPlaybackGroup() {
    final sound = _linkedSoundUrl;
    if (sound != null) {
      PostVideoControllerCache.instance.unlinkPlayback(sound);
    }
    _linkedSoundUrl = null;
  }

  void _linkPlaybackGroup() {
    _unlinkPlaybackGroup();
    if (!_hasAttachedSound) return;
    final soundUrl = _resolveUrl(widget.post.attachedSoundPlayUrl);
    final videoUrl = _primaryVideoUrl();
    if (soundUrl == null || videoUrl == null) return;
    PostVideoControllerCache.instance.linkPlayback(videoUrl, soundUrl);
    _linkedSoundUrl = soundUrl;
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
    _unlinkPlaybackGroup();
    _pageController.dispose();
    super.dispose();
  }

  void _onRatioDetermined(int index, double ratio) {
    if (_aspectRatios[index] == ratio) return;
    _aspectRatios[index] = ratio;
    // Keep carousel viewport size stable while paging — resizing the parent
    // mid-swipe cancels PageView animations and breaks back/forth navigation.
    if (_media.length > 1) {
      if (index == 0 && _currentIndex == 0) {
        widget.onAspectRatioChanged?.call(ratio);
      }
      return;
    }
    if (index == _currentIndex) {
      widget.onAspectRatioChanged?.call(ratio);
    }
  }

  void _notifyAspectForIndex(int index) {
    if (_media.length > 1) return;
    if (_aspectRatios.containsKey(index)) {
      widget.onAspectRatioChanged?.call(_aspectRatios[index]!);
      return;
    }
    final item = _media[index];
    widget.onAspectRatioChanged?.call(item.isVideo ? 9 / 16 : 1.0);
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    if (index < 0 || index >= _media.length || index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPrevious() => _goToPage(_currentIndex - 1);

  void _goToNext() => _goToPage(_currentIndex + 1);

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

  Widget _buildAttachedSoundBar() {
    if (!_hasAttachedSound) return const SizedBox.shrink();
    final audioUrl = widget.post.attachedSoundPlayUrl!;
    final sound = widget.post.sound;
    final title = [
      if (sound?.name.trim().isNotEmpty == true) sound!.name.trim(),
      if (sound?.author.trim().isNotEmpty == true) sound!.author.trim(),
    ].join(' · ');
    return PostAttachedSoundPreview(
      key: ValueKey('attached_sound_${widget.post.id}_$audioUrl'),
      audioUrl: audioUrl,
      title: title.isEmpty ? null : title,
      autoplay: true,
      looping: widget.soundLooping,
      showSeekBar: widget.showSeekBar,
    );
  }

  Widget _buildCarouselWithControls(double mediaHeight, ColorScheme scheme) {
    final hasMultiple = _media.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPageView(mediaHeight),
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
        // Bottom sound bar stays interactive (progress / play) without
        // blocking carousel swipes on the rest of the media area.
        if (_hasAttachedSound)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildAttachedSoundBar(),
          ),
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
              onTap: () => _goToPage(index),
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
      showSeekBar: widget.showSeekBar,
      muted: _hasAttachedSound,
      onAspectRatioDetermined: widget.onAspectRatioChanged,
    );

    if (!_hasAttachedSound) return preview;

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildAttachedSoundBar(),
        ),
      ],
    );
  }

  Widget _buildPageView(double mediaHeight) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _media.length,
        physics: const ClampingScrollPhysics(),
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
            showSeekBar: widget.showSeekBar,
            muted: _hasAttachedSound,
            hlsUrl: widget.post.hlsUrl,
            onAspectRatioDetermined: (ratio) => _onRatioDetermined(index, ratio),
          );
        },
      ),
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

        final rawHeight = constraints.maxHeight - reservedIndicator;
        final mediaHeight = (rawHeight.isNaN || rawHeight.isInfinite)
            ? 300.0
            : (rawHeight < 120.0 ? 120.0 : rawHeight);

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
