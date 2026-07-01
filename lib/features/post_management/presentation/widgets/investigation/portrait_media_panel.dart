import 'package:flutter/material.dart';

import '../post_media_carousel.dart';
import '../post_media_snapshot.dart';
import 'investigation_theme.dart';

class PortraitMediaPanel extends StatefulWidget {
  const PortraitMediaPanel({
    super.key,
    required this.snapshot,
    this.onAspectRatioChanged,
  });

  final PostMediaSnapshot snapshot;
  final ValueChanged<double>? onAspectRatioChanged;

  @override
  State<PortraitMediaPanel> createState() => _PortraitMediaPanelState();
}

class _PortraitMediaPanelState extends State<PortraitMediaPanel> {
  late double _aspectRatio;

  @override
  void initState() {
    super.initState();
    _aspectRatio = _calculateInitialAspectRatio();
  }

  @override
  void didUpdateWidget(PortraitMediaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      setState(() {
        _aspectRatio = _calculateInitialAspectRatio();
      });
    }
  }

  double _calculateInitialAspectRatio() {
    final snap = widget.snapshot;
    if (snap.videoWidth != null &&
        snap.videoHeight != null &&
        snap.videoHeight! > 0) {
      return snap.videoWidth! / snap.videoHeight!;
    }

    for (final item in snap.media) {
      if (item.isVideo) return 9 / 16;
    }

    if (snap.type.toUpperCase() == 'VIDEO') return 9 / 16;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final post = widget.snapshot.toPostShell();
    final isCarousel = post.media.length > 1;
    const double dotsHeight = 36.0;

    final isMobile = size.width < InvestigationTheme.tablet;
    final isTablet = size.width >= InvestigationTheme.tablet &&
        size.width < InvestigationTheme.desktop;

    double maxWidth;
    double maxHeight;

    if (isMobile) {
      maxWidth = size.width - 40;
      maxHeight = size.height * 0.68;
    } else if (isTablet) {
      if (_aspectRatio < 0.95) {
        maxWidth = 360;
      } else if (_aspectRatio > 1.05) {
        maxWidth = 560;
      } else {
        maxWidth = 420;
      }
      maxHeight = size.height * 0.62;
    } else {
      if (_aspectRatio < 0.95) {
        maxWidth = 380;
        maxHeight = size.height * 0.76;
      } else if (_aspectRatio > 1.05) {
        maxWidth = 640;
        maxHeight = size.height * 0.62;
      } else {
        maxWidth = 480;
        maxHeight = size.height * 0.68;
      }
    }

    final maxMediaHeight = maxHeight - (isCarousel ? dotsHeight : 0.0);

    double mediaWidth = maxWidth;
    double mediaHeight = mediaWidth / _aspectRatio;

    if (mediaHeight > maxMediaHeight) {
      mediaHeight = maxMediaHeight;
      mediaWidth = mediaHeight * _aspectRatio;
    }

    final containerWidth = mediaWidth;
    final containerHeight = mediaHeight + (isCarousel ? dotsHeight : 0.0);

    return Center(
      child: AnimatedSize(
        duration: const Duration(milliseconds: InvestigationTheme.animMs),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
            child: PostMediaCarousel(
              key: ValueKey(post.id),
              post: post,
              fit: BoxFit.contain,
              onAspectRatioChanged: (ratio) {
                if (ratio <= 0 || ratio == _aspectRatio) return;
                setState(() => _aspectRatio = ratio);
                widget.onAspectRatioChanged?.call(ratio);
              },
            ),
          ),
        ),
      ),
    );
  }
}
