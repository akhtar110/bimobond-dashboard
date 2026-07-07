import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/create_post_entity.dart';
import '../bloc/create_post_bloc.dart';
import 'create_post_sound_picker_sheet.dart';

/// Sound selection card for post settings step.
class CreatePostSoundSection extends StatelessWidget {
  const CreatePostSoundSection({super.key, required this.form});

  final CreatePostEntity form;

  Future<void> _openPicker(BuildContext context) async {
    final bloc = context.read<CreatePostBloc>();
    await showCreatePostSoundPicker(
      context: context,
      selected: form.selectedSound,
      onSelect: (sound) => bloc.add(SelectSound(sound)),
      onUpload: (bytes, filename, name, duration) => bloc.add(
        UploadOriginalSound(
          bytes: bytes,
          filename: filename,
          name: name,
          duration: duration,
        ),
      ),
      onClear: () => bloc.add(ClearSound()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sound = form.selectedSound;
    final isNewSound = form.newSound != null;

    return BlocBuilder<CreatePostBloc, CreatePostState>(
      buildWhen: (p, n) =>
          p.soundUploadProgress != n.soundUploadProgress ||
          p.form.selectedSound != n.form.selectedSound,
      builder: (context, state) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(top: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.t('createPostSound'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (sound != null)
                      TextButton(
                        onPressed: () =>
                            context.read<CreatePostBloc>().add(ClearSound()),
                        child: Text(l10n.t('remove')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.soundUploadProgress != null) ...[
                  LinearProgressIndicator(
                    value: state.soundUploadProgress,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('createPostSoundUploading'),
                    style: theme.textTheme.labelSmall,
                  ),
                ] else if (sound != null) ...[
                  Row(
                    children: [
                      if (sound.coverUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            resolveMediaUrl(sound.coverUrl!) ?? sound.coverUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverFallback(theme),
                          ),
                        )
                      else
                        _coverFallback(theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sound.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              sound.author,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            if (isNewSound)
                              Text(
                                l10n.t('createPostSoundOriginal'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    l10n.t('createPostSoundEmpty'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade500
                          : const Color(0xFF6B7280),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.soundUploadProgress != null
                      ? null
                      : () => _openPicker(context),
                  icon: Icon(sound != null ? Icons.edit_outlined : Icons.add),
                  label: Text(
                    sound != null
                        ? l10n.t('createPostSoundChange')
                        : l10n.t('createPostSoundAdd'),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coverFallback(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.audiotrack, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
