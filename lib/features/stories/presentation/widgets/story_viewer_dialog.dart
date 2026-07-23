import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../posts/presentation/utils/posts_responsive.dart';
import '../../../../core/widgets/post_media_preview.dart';
import '../../domain/entities/story_viewer_slide.dart';
import '../utils/stories_admin_l10n.dart';
import 'story_viewer_media.dart';

const Duration _kImageStoryDuration = Duration(seconds: 5);

typedef StoryIndexChanged = void Function(int index);
typedef StoryViewDetailsCallback = Future<void> Function(StoryViewerSlide story);

Future<bool?> showStoryViewerDialog(
  BuildContext context, {
  required List<StoryViewerSlide> stories,
  required int initialIndex,
  StoryIndexChanged? onIndexChanged,
  VoidCallback? onStoryCompleted,
  StoryViewDetailsCallback? onViewDetails,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'story_viewer',
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.94),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      return StoryViewerDialog(
        stories: stories,
        initialIndex: initialIndex,
        onIndexChanged: onIndexChanged,
        onStoryCompleted: onStoryCompleted,
        onViewDetails: onViewDetails,
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class StoryViewerDialog extends StatefulWidget {
  const StoryViewerDialog({
    super.key,
    required this.stories,
    required this.initialIndex,
    this.onIndexChanged,
    this.onStoryCompleted,
    this.onViewDetails,
  });

  final List<StoryViewerSlide> stories;
  final int initialIndex;
  final StoryIndexChanged? onIndexChanged;
  final VoidCallback? onStoryCompleted;
  final StoryViewDetailsCallback? onViewDetails;

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _imageProgressController;

  VideoPlayerController? _trackedController;
  String? _trackedUrl;
  int _setupGeneration = 0;
  bool _isPaused = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _imageProgressController = AnimationController(vsync: this);
    _imageProgressController
      ..addStatusListener(_onImageProgressStatus)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentStory());
  }

  @override
  void dispose() {
    _detachMediaListener();
    _releaseTrackedController();
    PostVideoControllerCache.instance.pauseAll();
    _imageProgressController
      ..removeStatusListener(_onImageProgressStatus)
      ..dispose();
    super.dispose();
  }

  StoryViewerSlide get _currentStory => widget.stories[_currentIndex];

  void _onImageProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_isPaused) {
      _goNext(auto: true);
    }
  }

  Future<void> _loadCurrentStory() async {
    _detachMediaListener();
    _releaseTrackedController();
    _imageProgressController.stop();
    _imageProgressController.reset();
    if (!mounted) return;

    setState(() => _isPaused = false);

    final generation = ++_setupGeneration;
    final mediaUrl = storyProgressMediaUrl(_currentStory);

    if (mediaUrl != null) {
      PostVideoControllerCache.instance.obtain(mediaUrl, looping: false);
      await _attachProgressTracking(mediaUrl, generation: generation);
      _trackedController?.play();
      return;
    }

    _imageProgressController.duration = _kImageStoryDuration;
    _imageProgressController.forward(from: 0);
  }

  Future<void> _attachProgressTracking(
    String url, {
    required int generation,
  }) async {
    _trackedUrl = url;
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted || generation != _setupGeneration) return;

      await PostVideoControllerCache.instance.waitForInitialize(url);
      final controller = PostVideoControllerCache.instance.controllerFor(url);
      if (controller != null && controller.value.isInitialized) {
        _trackedController = controller;
        controller.addListener(_onMediaTick);
        if (mounted) setState(() {});
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _releaseTrackedController() {
    final url = _trackedUrl;
    if (url != null) {
      PostVideoControllerCache.instance.release(url);
    }
    _trackedUrl = null;
  }

  void _onMediaTick() {
    if (!mounted || _isPaused) return;

    final controller = _trackedController;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    final duration = value.duration;
    if (duration > Duration.zero &&
        value.position >= duration - const Duration(milliseconds: 250)) {
      _goNext(auto: true);
      return;
    }

    setState(() {});
  }

  void _detachMediaListener() {
    _trackedController?.removeListener(_onMediaTick);
    _trackedController = null;
  }

  void _pauseStory() {
    if (_isPaused) return;
    _isPaused = true;
    _imageProgressController.stop();
    _trackedController?.pause();
    setState(() {});
  }

  void _resumeStory() {
    if (!_isPaused) return;
    _isPaused = false;

    final mediaUrl = storyProgressMediaUrl(_currentStory);
    if (mediaUrl != null) {
      _trackedController?.play();
    } else if (_imageProgressController.value < 1) {
      _imageProgressController.forward();
    }
    setState(() {});
  }

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    _setIndex(_currentIndex - 1);
  }

  void _goNext({bool auto = false}) {
    if (_currentIndex >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    if (auto) widget.onStoryCompleted?.call();
    _setIndex(_currentIndex + 1);
  }

  void _setIndex(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    widget.onIndexChanged?.call(index);
    _loadCurrentStory();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _openDetails() {
    final story = _currentStory;
    Navigator.of(context).pop(true);
    widget.onViewDetails?.call(story);
  }

  double _segmentProgress(int index) {
    if (index < _currentIndex) return 1;
    if (index > _currentIndex) return 0;

    final controller = _trackedController;
    if (controller != null && controller.value.isInitialized) {
      final duration = controller.value.duration.inMilliseconds;
      if (duration <= 0) return 0;
      return (controller.value.position.inMilliseconds / duration)
          .clamp(0.0, 1.0);
    }

    if (storyProgressMediaUrl(_currentStory) != null) return 0;

    return _imageProgressController.value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              setState(() => _dragOffset += details.delta.dy);
            }
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset > 90 || (details.primaryVelocity ?? 0) > 700) {
              _close();
            } else {
              setState(() => _dragOffset = 0);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final device = getPostsDeviceType(width);
                  final isPhone = device == PostsDeviceType.mobileSmall ||
                      device == PostsDeviceType.mobileLarge;
                  final isTablet = device == PostsDeviceType.tablet;

                  final maxWidth = switch (device) {
                    PostsDeviceType.mobileSmall => width - 16,
                    PostsDeviceType.mobileLarge => width - 20,
                    PostsDeviceType.tablet =>
                      (width * 0.52).clamp(300.0, 440.0),
                    PostsDeviceType.desktop =>
                      (width * 0.62).clamp(320.0, 520.0),
                  };
                  final maxHeight = switch (device) {
                    PostsDeviceType.mobileSmall => height * 0.58,
                    PostsDeviceType.mobileLarge => height * 0.62,
                    PostsDeviceType.tablet => height * 0.7,
                    PostsDeviceType.desktop =>
                      (height * 0.82).clamp(420.0, 760.0),
                  };
                  final radius = isPhone ? 14.0 : (isTablet ? 18.0 : 22.0);

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _StoryProgressHeader(
                              stories: widget.stories,
                              currentIndex: _currentIndex,
                              segmentProgressFor: _segmentProgress,
                              story: _currentStory,
                              onClose: _close,
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) {
                                  final tapWidth =
                                      context.size?.width ?? maxWidth;
                                  final dx = details.localPosition.dx;
                                  if (dx < tapWidth * 0.35) {
                                    _goPrevious();
                                  } else if (dx > tapWidth * 0.65) {
                                    _goNext();
                                  } else {
                                    _isPaused
                                        ? _resumeStory()
                                        : _pauseStory();
                                  }
                                },
                                onLongPressStart: (_) => _pauseStory(),
                                onLongPressEnd: (_) => _resumeStory(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    StoryViewerMedia(
                                      key: ValueKey(_currentStory.id),
                                      slide: _currentStory,
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      left: 12,
                                      right: 12,
                                      bottom: 12,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _currentStory.caption,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: scheme.onSurface,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          if (widget.onViewDetails != null) ...[
                                            const SizedBox(width: 8),
                                            FilledButton.tonal(
                                              onPressed: _openDetails,
                                              style: FilledButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                              child: Text(
                                                StoriesAdminL10n.viewDetails(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryProgressHeader extends StatelessWidget {
  const _StoryProgressHeader({
    required this.stories,
    required this.currentIndex,
    required this.segmentProgressFor,
    required this.story,
    required this.onClose,
  });

  final List<StoryViewerSlide> stories;
  final int currentIndex;
  final double Function(int index) segmentProgressFor;
  final StoryViewerSlide story;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < stories.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _StorySegmentBar(
                    progress: segmentProgressFor(i),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: story.author.avatarUrl != null
                    ? CachedNetworkImageProvider(story.author.avatarUrl!)
                    : null,
                child: story.author.avatarUrl == null
                    ? Text(
                        story.author.name.isNotEmpty
                            ? story.author.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StoriesAdminL10n.viewerAuthorName(context, story.author),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      StoriesAdminL10n.formatDate(context, story.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorySegmentBar extends StatelessWidget {
  const _StorySegmentBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.outlineVariant.withValues(alpha: 0.55)),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress.clamp(0.0, 1.0),
              child: ColoredBox(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
