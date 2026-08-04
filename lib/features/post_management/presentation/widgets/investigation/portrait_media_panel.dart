import 'package:flutter/material.dart';

import '../../../../../core/utils/media_url_resolver.dart';
import '../../../../../injection_container.dart';
import '../../../../sound_management/domain/usecases/sound_usecases.dart';
import '../../../domain/entities/managed_post_sound_entity.dart';
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
  ManagedPostSoundEntity? _resolvedSound;
  bool _resolvingSound = false;

  @override
  void initState() {
    super.initState();
    _aspectRatio = _calculateInitialAspectRatio();
    _resolvedSound = widget.snapshot.sound;
    _ensurePlayableSound();
  }

  @override
  void didUpdateWidget(PortraitMediaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      setState(() {
        _aspectRatio = _calculateInitialAspectRatio();
        _resolvedSound = widget.snapshot.sound;
      });
      _ensurePlayableSound();
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
      if (item.isVideo) return InvestigationTheme.portraitAspect;
    }

    if (snap.type.toUpperCase() == 'VIDEO') {
      return InvestigationTheme.portraitAspect;
    }
    return 1.0;
  }

  Future<void> _ensurePlayableSound() async {
    final snap = widget.snapshot;
    final existingUrl = snap.attachedSoundPlayUrl;
    if (existingUrl != null && existingUrl.isNotEmpty) {
      final resolved = resolveMediaUrl(existingUrl) ?? existingUrl;
      if (_resolvedSound?.audioUrl != resolved) {
        setState(() {
          _resolvedSound = (snap.sound ??
                  ManagedPostSoundEntity(
                    id: snap.resolvedSoundId ?? resolved,
                  ))
              .copyWith(audioUrl: resolved);
        });
      }
      return;
    }

    final soundId = snap.resolvedSoundId;
    if (soundId == null || soundId.isEmpty || _resolvingSound) return;

    setState(() => _resolvingSound = true);
    try {
      final detail = await sl<GetSoundByIdUseCase>()(soundId);
      if (!mounted) return;
      final audioUrl =
          resolveMediaUrl(detail.audioUrl) ?? detail.audioUrl.trim();
      if (audioUrl.isEmpty) {
        setState(() => _resolvingSound = false);
        return;
      }
      setState(() {
        _resolvingSound = false;
        _resolvedSound = ManagedPostSoundEntity(
          id: detail.id.isNotEmpty ? detail.id : soundId,
          name: detail.name,
          author: detail.author,
          audioUrl: audioUrl,
          duration: detail.duration,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingSound = false);
    }
  }

  /// Fills the available media column: portrait prefers height, landscape width.
  ({double width, double height}) _fitMediaSize({
    required double maxWidth,
    required double maxHeight,
    required double aspectRatio,
  }) {
    final isPortrait = aspectRatio < 0.98;
    final isLandscape = aspectRatio > 1.02;

    double width;
    double height;

    if (isPortrait) {
      // Use the full portrait viewport height, then clamp width.
      height = maxHeight;
      width = height * aspectRatio;
      if (width > maxWidth) {
        width = maxWidth;
        height = width / aspectRatio;
      }
    } else if (isLandscape) {
      // Use the full landscape viewport width, then clamp height.
      width = maxWidth;
      height = width / aspectRatio;
      if (height > maxHeight) {
        height = maxHeight;
        width = height * aspectRatio;
      }
    } else {
      // Near-square: take the largest square that fits.
      final side = maxWidth < maxHeight ? maxWidth : maxHeight;
      width = side;
      height = side;
    }

    return (width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final post = widget.snapshot.toPostShell().copyWith(
          soundId: widget.snapshot.resolvedSoundId ?? _resolvedSound?.id,
          sound: _resolvedSound ?? widget.snapshot.sound,
        );
    final isCarousel = post.media.length > 1;
    const double dotsHeight = 36.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : size.width;

        // Leave room for app chrome / side panels; prefer tall portrait frames.
        final viewportCap = size.height *
            (size.width < InvestigationTheme.tablet
                ? 0.78
                : size.width < InvestigationTheme.desktop
                    ? 0.82
                    : 0.88);
        final availableHeight = constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0 &&
                constraints.maxHeight < viewportCap
            ? constraints.maxHeight
            : viewportCap;

        final rawHeight = availableHeight - (isCarousel ? dotsHeight : 0.0);
        final maxMediaHeight = (rawHeight.isNaN || rawHeight.isInfinite)
            ? 300.0
            : (rawHeight < 160.0 ? 160.0 : rawHeight);

        final fitted = _fitMediaSize(
          maxWidth: availableWidth,
          maxHeight: maxMediaHeight,
          aspectRatio: _aspectRatio <= 0 ? 1 : _aspectRatio,
        );

        final containerWidth = fitted.width;
        final containerHeight =
            fitted.height + (isCarousel ? dotsHeight : 0.0);

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
                borderRadius:
                    BorderRadius.circular(InvestigationTheme.radiusSm),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(InvestigationTheme.radiusSm),
                child: PostMediaCarousel(
                  // Keep media identity stable when attached sound hydrates so
                  // video/image playback is not remounted / interrupted.
                  key: ValueKey('post_media_${post.id}'),
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
      },
    );
  }
}
