import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/sound_entities.dart';
import '../../domain/usecases/sound_usecases.dart';
import '../services/sound_preview_service.dart';
import 'sound_preview_scope.dart';
import 'sound_preview_widgets.dart';

class SoundDetailsDialog extends StatefulWidget {
  const SoundDetailsDialog({
    super.key,
    required this.soundId,
    this.initialSound,
  });

  final String soundId;
  final SoundEntity? initialSound;

  static Future<void> show(
    BuildContext context, {
    required String soundId,
    SoundEntity? sound,
    SoundPreviewService? preview,
  }) {
    final soundPreview = preview ?? SoundPreviewScope.maybeOf(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final dialog = SoundDetailsDialog(
          soundId: soundId,
          initialSound: sound,
        );
        if (soundPreview != null) {
          return SoundPreviewScope(
            preview: soundPreview,
            child: dialog,
          );
        }
        return dialog;
      },
    );
  }

  @override
  State<SoundDetailsDialog> createState() => _SoundDetailsDialogState();
}

class _SoundDetailsDialogState extends State<SoundDetailsDialog> {
  SoundEntity? _sound;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sound = widget.initialSound;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await di.sl<GetSoundByIdUseCase>()(widget.soundId);
      if (!mounted) return;
      setState(() {
        _sound = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_sound == null) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sound = _sound;
    final preview = context.soundPreviewMaybe;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 720,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title & close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tOr('soundDetailsTitle', 'Sound Details'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_loading && sound == null) ...[
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else if (_error != null && sound == null) ...[
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ),
              ] else if (sound != null) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sound Header Card
                        _SoundHeaderCard(sound: sound, preview: preview),
                        const SizedBox(height: 16),

                        // Stats & Metadata Grid
                        _SoundMetadataGrid(sound: sound),
                        const SizedBox(height: 20),

                        // Recent Posts section
                        Row(
                          children: [
                            const Icon(Icons.video_library_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.tOr('soundRecentPosts', 'Recent Posts Using Sound'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${sound.posts.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (sound.posts.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                l10n.tOr('soundNoRecentPosts', 'No recent posts found for this sound.'),
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ] else ...[
                          _RecentPostsGrid(posts: sound.posts),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundHeaderCard extends StatelessWidget {
  const _SoundHeaderCard({
    required this.sound,
    this.preview,
  });

  final SoundEntity sound;
  final SoundPreviewService? preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverUrl = resolveMediaUrl(sound.coverUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: scheme.primaryContainer,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.music_note_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sound.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(isActive: sound.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sound.author,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 10),
                  SoundTablePlaybackStrip(
                    sound: sound,
                    preview: preview!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive
        ? scheme.primaryContainer
        : scheme.errorContainer;
    final fg = isActive
        ? scheme.onPrimaryContainer
        : scheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive
            ? l10n.t('soundStatusActive')
            : l10n.t('soundStatusHidden'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _SoundMetadataGrid extends StatelessWidget {
  const _SoundMetadataGrid({required this.sound});

  final SoundEntity sound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = NumberFormat.compact();
    final dateFmt = DateFormat.yMMMd();

    final originLabel = sound.isFromDashboard
        ? l10n.tOr('soundSourceDashboard', 'Dashboard Catalog')
        : l10n.tOr('soundSourceUser', 'User Uploaded');

    final typeLabel = switch (sound.libraryType) {
      SoundLibraryType.official => l10n.tOr('soundTypeOfficial', 'Official'),
      SoundLibraryType.original => l10n.tOr('soundTypeOriginal', 'Original'),
      SoundLibraryType.remix => l10n.tOr('soundTypeRemix', 'Remix'),
    };

    final durationText = sound.duration < 60
        ? '${sound.duration}s'
        : '${sound.duration ~/ 60}m ${sound.duration % 60}s';

    final items = [
      (l10n.t('soundUsageCount'), compact.format(sound.useCount), Icons.equalizer_rounded),
      (l10n.t('soundDuration'), durationText, Icons.timer_outlined),
      (l10n.tOr('origin', 'Origin'), originLabel, Icons.dashboard_customize_outlined),
      (l10n.tOr('type', 'Library Type'), typeLabel, Icons.category_outlined),
      (
        l10n.t('soundColPublished'),
        sound.createdAt != null ? dateFmt.format(sound.createdAt!) : '—',
        Icons.calendar_today_outlined,
      ),
      (
        l10n.tOr('creator', 'Creator'),
        sound.creator?.username ?? (sound.creatorId != null ? 'User' : 'Dashboard Staff'),
        Icons.person_outline_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          for (final item in items)
            SizedBox(
              width: 180,
              child: Row(
                children: [
                  Icon(item.$3, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentPostsGrid extends StatelessWidget {
  const _RecentPostsGrid({required this.posts});

  final List<SoundRecentPostEntity> posts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = NumberFormat.compact();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final coverUrl = resolveMediaUrl(post.coverUrl);

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl != null && coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.movie_outlined),
                            ),
                          )
                        : Container(
                            color: scheme.surfaceContainerHighest,
                            child: const Icon(Icons.movie_outlined),
                          ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            compact.format(post.likeCount),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.mode_comment_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            compact.format(post.commentCount),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (post.caption != null && post.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    post.caption!,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
