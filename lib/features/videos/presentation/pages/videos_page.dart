import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/video_entity.dart';
import '../bloc/videos_bloc.dart';

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('VideosPage rebuilt');
    return PersistentBlocProvider<VideosBloc>(
      debugLabel: 'VideosPage',
      create: () {
        if (kDebugMode) debugPrint('LoadVideos dispatched');
        return di.sl<VideosBloc>()..add(LoadVideosEvent(refresh: true));
      },
      child: const _VideosPageView(),
    );
  }
}

class _VideosPageView extends StatefulWidget {
  const _VideosPageView();

  @override
  State<_VideosPageView> createState() => _VideosPageViewState();
}

class _VideosPageViewState extends State<_VideosPageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 280) {
      context.read<VideosBloc>().add(LoadVideosEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VideoFilters(
                  onChanged:
                      (filter) => context.read<VideosBloc>().add(
                        FilterVideosEvent(filter),
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? theme.dividerColor
                            : const Color(0xFFE6E8EC),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BlocBuilder<VideosBloc, VideosState>(
                      builder: (context, state) {
                        if (state is VideosLoading) {
                          return const Center(child: LoadingView());
                        }
                        if (state is VideosError) {
                          return ErrorView(
                            message: l10n.t('errorOccurred'),
                            retryLabel: l10n.t('retry'),
                            onRetry:
                                () => context.read<VideosBloc>().add(
                                  LoadVideosEvent(refresh: true),
                                ),
                          );
                        }
                        if (state is VideosEmpty) {
                          return EmptyView(message: l10n.t('noData'));
                        }
                        if (state is VideosLoaded) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: _gridItemWidth(
                                    constraints.maxWidth,
                                  ),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount:
                                    state.videos.length +
                                    (state.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == state.videos.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final video = state.videos[index];
                                  return _VideoCard(video: video);
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _gridItemWidth(double availableWidth) {
    if (availableWidth >= 1400) return 168;
    if (availableWidth >= 1100) return 176;
    if (availableWidth >= 800) return 184;
    if (availableWidth >= 560) return 192;
    return 200;
  }
}

class _VideoFilters extends StatelessWidget {
  const _VideoFilters({required this.onChanged});

  final ValueChanged<VideoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<VideosBloc>().state;
    final current = state is VideosLoaded ? state.filter : VideoFilter.all;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labels = <VideoFilter, String>{
      VideoFilter.all: l10n.t('all'),
      VideoFilter.reported: l10n.t('reported'),
      VideoFilter.trending: l10n.t('trending'),
      VideoFilter.newest: l10n.t('newVideos'),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            labels.entries.map((entry) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: current == entry.key,
                  onSelected: (_) => onChanged(entry.key),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  const _VideoCard({required this.video});
  final VideoEntity video;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? primary.withValues(alpha: 0.35)
                : (isDark ? theme.dividerColor : const Color(0xFFE8ECF1)),
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFF1F5F9),
                      child: Icon(
                        Icons.videocam_off_outlined,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (widget.video.reportCount > 0)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.video.reportCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.ownerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.t('reportsCount')}: ${widget.video.reportCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(
                          color: Colors.red.shade600.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          () => context.read<VideosBloc>().add(
                            DeleteVideoEvent(widget.video.id),
                          ),
                      child: Text(
                        l10n.t('deleteVideo'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
