import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';
import '../services/sound_preview_service.dart';
String formatSoundPlaybackTime(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class SoundPreviewButton extends StatelessWidget {
  const SoundPreviewButton({
    super.key,
    required this.soundId,
    required this.audioUrl,
    required this.preview,
    this.compact = false,
    this.fallbackDurationSeconds,
  });

  final String soundId;
  final String audioUrl;
  final SoundPreviewService preview;
  final bool compact;
  final int? fallbackDurationSeconds;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preview,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final active = preview.isActive(soundId);
        final loading = active && preview.isLoading;
        final playing = preview.isPlaying(soundId);
        final progress = preview.progressFor(soundId);

        if (compact) {
          return IconButton(
            tooltip: context.l10n.t('soundPreview'),
            onPressed: loading ? null : () => preview.toggle(soundId, audioUrl),
            icon: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                  ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.t('soundPreview'),
              onPressed:
                  loading ? null : () => preview.toggle(soundId, audioUrl),
              icon: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                    ),
            ),
            if (active && !loading && !preview.hasError) ...[
              SizedBox(
                width: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Playback controls row used inside the sounds table name column.
class SoundTablePlaybackStrip extends StatelessWidget {
  const SoundTablePlaybackStrip({
    super.key,
    required this.sound,
    required this.preview,
  });

  final SoundEntity sound;
  final SoundPreviewService preview;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preview,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final l10n = context.l10n;
        final active = preview.isActive(sound.id);
        final loading = active && preview.isLoading;
        final playing = preview.isPlaying(sound.id);
        final progress = preview.progressFor(sound.id);

        final totalDuration = active &&
                preview.durationFor(sound.id) > Duration.zero
            ? preview.durationFor(sound.id)
            : Duration(seconds: sound.duration);
        final played = active ? preview.positionFor(sound.id) : Duration.zero;
        final remaining = totalDuration - played;
        final safeRemaining =
            remaining.isNegative ? Duration.zero : remaining;

        return Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              tooltip: l10n.t('soundPreview'),
              onPressed: loading
                  ? null
                  : () => preview.toggle(sound.id, sound.audioUrl),
              icon: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 20,
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: active && !loading && !preview.hasError
                          ? progress.clamp(0.0, 1.0)
                          : 0,
                      minHeight: 4,
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active && !loading
                        ? context.tr('soundPlaybackProgress', {
                            'played': formatSoundPlaybackTime(played),
                            'total': formatSoundPlaybackTime(totalDuration),
                            'remaining':
                                formatSoundPlaybackTime(safeRemaining),
                          })
                        : formatSoundPlaybackTime(totalDuration),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: active
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class SoundStatusBadge extends StatelessWidget {
  const SoundStatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;
    final label =
        isActive ? l10n.t('soundStatusActive') : l10n.t('soundStatusHidden');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SoundOriginBadge extends StatelessWidget {
  const SoundOriginBadge({super.key, required this.isFromDashboard});

  final bool isFromDashboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = isFromDashboard ? scheme.tertiary : scheme.secondary;
    final label = isFromDashboard
        ? l10n.tOr('soundSourceDashboardBadge', 'Dashboard')
        : l10n.tOr('soundSourceUserBadge', 'User');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SoundTypeBadge extends StatelessWidget {
  const SoundTypeBadge({super.key, required this.type});

  final SoundLibraryType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (label, color) = switch (type) {
      SoundLibraryType.original =>
        (l10n.t('soundTypeOriginal'), scheme.secondary),
      SoundLibraryType.official =>
        (l10n.t('soundTypeOfficial'), scheme.primary),
      SoundLibraryType.remix => (l10n.t('soundTypeRemix'), scheme.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
