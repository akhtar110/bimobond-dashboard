import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../../domain/repositories/sound_management_repository.dart';
import '../../domain/usecases/sound_usecases.dart';
import '../bloc/sound_form_cubit.dart';
import '../utils/sound_file_picker_web.dart';
import 'sound_form_audio_preview.dart';
import 'sound_form_cover_preview.dart';

class SoundFormDialog extends StatelessWidget {
  const SoundFormDialog({
    super.key,
    this.sound,
    this.initialGroups,
  });

  final SoundEntity? sound;
  final List<SoundGroupEntity>? initialGroups;

  bool get isEditing => sound != null;

  static Future<SoundFormResult?> show(
    BuildContext context, {
    SoundEntity? sound,
    List<SoundGroupEntity>? groups,
  }) {
    return showDialog<SoundFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => SoundFormCubit(
          repository: di.sl<SoundManagementRepository>(),
          sound: sound,
        ),
        child: SoundFormDialog(sound: sound, initialGroups: groups),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SoundFormDialogBody(
      sound: sound,
      initialGroups: initialGroups,
    );
  }
}

class SoundFormResult {
  SoundFormResult({
    this.createData,
    this.uploadData,
    this.updateData,
    this.assignGroupId,
    this.previousAssignGroupId,
  });

  final CreateSoundData? createData;
  final UploadSoundData? uploadData;
  final UpdateSoundData? updateData;

  /// Desired shelf for the sound (`PUT .../groups/:id/sounds`).
  final String? assignGroupId;

  /// Group the sound belonged to when the edit dialog opened (if any).
  final String? previousAssignGroupId;
}

class _SoundFormDialogBody extends StatefulWidget {
  const _SoundFormDialogBody({
    this.sound,
    this.initialGroups,
  });

  final SoundEntity? sound;
  final List<SoundGroupEntity>? initialGroups;

  bool get isEditing => sound != null;

  @override
  State<_SoundFormDialogBody> createState() => _SoundFormDialogBodyState();
}

class _SoundFormDialogBodyState extends State<_SoundFormDialogBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late bool _isActive;
  late bool _isFromDashboard;

  List<SoundGroupEntity> _groups = const [];
  bool _loadingGroups = false;
  String? _selectedGroupId;
  String? _initialGroupId;

  @override
  void initState() {
    super.initState();
    final sound = widget.sound;
    _nameController = TextEditingController(text: sound?.name ?? '');
    _authorController = TextEditingController(text: sound?.author ?? '');
    _isActive = sound?.isActive ?? true;
    _isFromDashboard = sound?.isFromDashboard ?? true;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (widget.initialGroups != null) {
      setState(() {
        _groups = widget.initialGroups!;
        _applyInitialGroupSelection();
      });
      return;
    }
    setState(() => _loadingGroups = true);
    try {
      final groups = await di.sl<GetSoundGroupsUseCase>()();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingGroups = false;
        _applyInitialGroupSelection();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
    }
  }

  void _applyInitialGroupSelection() {
    final soundId = widget.sound?.id;
    if (soundId == null || soundId.isEmpty) return;
    for (final group in _groups) {
      final inGroup = group.sounds.any((member) => member.sound.id == soundId);
      if (inGroup) {
        _selectedGroupId = group.id;
        _initialGroupId = group.id;
        return;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final l10n = context.l10n;
    final cubit = context.read<SoundFormCubit>();
    final before = cubit.state.fileError;
    await cubit.pickAudio(
      maxSizeMessage: () => l10n.t('soundAudioMaxSizeExceeded'),
      invalidFormatMessage: () => l10n.t('soundInvalidAudioFormat'),
    );
    if (!mounted) return;
    final error = cubit.state.fileError;
    if (error != null &&
        error == l10n.t('soundAudioMaxSizeExceeded') &&
        error != before) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final cubit = context.read<SoundFormCubit>();
    final media = cubit.state;
    if (!_formKey.currentState!.validate() || media.isBusy) return;

    if (widget.isEditing) {
      final coverUrl = media.resolvedCoverUrl;
      final audioUrl = media.resolvedAudioUrl ?? '';
      Navigator.of(context).pop(
        SoundFormResult(
          updateData: UpdateSoundData(
            name: _nameController.text.trim(),
            author: _authorController.text.trim(),
            audioUrl: audioUrl.isEmpty ? null : audioUrl,
            coverUrl: coverUrl == null || coverUrl.isEmpty ? null : coverUrl,
            clearCoverUrl: coverUrl == null || coverUrl.isEmpty,
            isActive: _isActive,
            isFromDashboard: _isFromDashboard,
          ),
          assignGroupId: _selectedGroupId,
          previousAssignGroupId: _initialGroupId,
        ),
      );
      return;
    }

    if (media.audioBytes == null || media.audioFilename == null) {
      cubit.setFileError(context.l10n.t('soundAudioRequired'));
      return;
    }

    if (media.audioBytes!.length > kMaxAudioUploadBytes) {
      final message = context.l10n.t('soundAudioMaxSizeExceeded');
      cubit.setFileError(message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final duration = media.detectedDuration ?? 0;

    Navigator.of(context).pop(
      SoundFormResult(
        uploadData: UploadSoundData(
          bytes: media.audioBytes!,
          filename: media.audioFilename!,
          name: _nameController.text.trim(),
          author: _authorController.text.trim(),
          duration: duration,
          coverBytes: media.coverBytes,
          coverFilename: media.coverFilename,
          isFromDashboard: _isFromDashboard,
        ),
        assignGroupId: _selectedGroupId,
      ),
    );
  }

  String? _detectedDurationLabel(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.isEditing;

    return BlocSelector<SoundFormCubit, SoundFormState, bool>(
      selector: (s) => s.isBusy,
      builder: (context, busy) {
        return AlertDialog(
          title: Text(
            editing ? l10n.t('soundEditTitle') : l10n.t('soundAddTitle'),
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!editing) ...[
                      OutlinedButton.icon(
                        onPressed: busy ? null : _pickAudio,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(l10n.t('soundUploadAudio')),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.t('soundAudioMaxSizeHint'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      BlocSelector<SoundFormCubit, SoundFormState,
                          ({Uint8List? bytes, String? name})>(
                        selector: (s) => (
                          bytes: s.audioBytes,
                          name: s.audioFilename,
                        ),
                        builder: (context, audio) {
                          if (audio.bytes == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SoundFormAudioPreview(
                              key: ValueKey('create-audio-${audio.name}'),
                              bytes: audio.bytes,
                              fileName: audio.name,
                              onClear: busy
                                  ? null
                                  : () => context
                                      .read<SoundFormCubit>()
                                      .clearAudio(),
                            ),
                          );
                        },
                      ),
                      BlocSelector<SoundFormCubit, SoundFormState,
                          ({bool detecting, int? duration})>(
                        selector: (s) => (
                          detecting: s.detectingDuration,
                          duration: s.detectedDuration,
                        ),
                        builder: (context, meta) {
                          final durationLabel =
                              _detectedDurationLabel(meta.duration);
                          if (meta.detecting) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (durationLabel == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '${l10n.t('soundDuration')}: $durationLabel',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => context.read<SoundFormCubit>().pickCover(),
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l10n.t('soundUploadCover')),
                      ),
                      BlocSelector<SoundFormCubit, SoundFormState,
                          ({
                            Uint8List? bytes,
                            String? url,
                            String? name,
                          })>(
                        selector: (s) => (
                          bytes: s.coverPreviewBytes,
                          url: s.resolvedCoverUrl,
                          name: s.coverFilename,
                        ),
                        builder: (context, cover) {
                          if (cover.bytes == null &&
                              (cover.url == null || cover.url!.isEmpty)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SoundFormCoverPreview(
                              previewBytes: cover.bytes,
                              imageUrl: cover.url,
                              fileName: cover.name,
                              enabled: !busy,
                              onClear: () =>
                                  context.read<SoundFormCubit>().clearCover(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      BlocSelector<SoundFormCubit, SoundFormState, String>(
                        selector: (s) => s.resolvedAudioUrl ?? '',
                        builder: (context, audioUrl) {
                          if (audioUrl.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return SoundFormAudioPreview(
                            key: ValueKey('edit-audio-$audioUrl'),
                            networkUrl: audioUrl,
                            fileName: audioUrl,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('thumbnail'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.tOr(
                          'soundGroupIconHint',
                          'Optional. Upload an image from your computer.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      BlocSelector<SoundFormCubit, SoundFormState,
                          ({bool uploading, bool hasCover})>(
                        selector: (s) => (
                          uploading: s.uploadingCover,
                          hasCover: s.hasCover,
                        ),
                        builder: (context, coverBtn) {
                          return OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () =>
                                    context.read<SoundFormCubit>().pickCover(),
                            icon: coverBtn.uploading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  )
                                : const Icon(Icons.upload_file_outlined,
                                    size: 18),
                            label: Text(
                              coverBtn.uploading
                                  ? l10n.tOr('uploading', 'Uploading…')
                                  : coverBtn.hasCover
                                      ? l10n.t('changeImage')
                                      : l10n.tOr(
                                          'uploadImage', 'Upload image'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                      BlocSelector<SoundFormCubit, SoundFormState, String?>(
                        selector: (s) => s.coverError,
                        builder: (context, coverError) {
                          if (coverError == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              coverError,
                              style: TextStyle(
                                  color: scheme.error, fontSize: 12),
                            ),
                          );
                        },
                      ),
                      BlocSelector<SoundFormCubit, SoundFormState,
                          ({
                            Uint8List? bytes,
                            String? url,
                            String? name,
                            bool hasCover,
                          })>(
                        selector: (s) => (
                          bytes: s.coverPreviewBytes,
                          url: s.resolvedCoverUrl,
                          name: s.coverFilename,
                          hasCover: s.hasCover,
                        ),
                        builder: (context, cover) {
                          if (!cover.hasCover) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SoundFormCoverPreview(
                              previewBytes: cover.bytes,
                              imageUrl: cover.url,
                              fileName: cover.name,
                              enabled: !busy,
                              onClear: () =>
                                  context.read<SoundFormCubit>().clearCover(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          InputDecoration(labelText: l10n.t('soundName')),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.t('requiredField')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _authorController,
                      decoration:
                          InputDecoration(labelText: l10n.t('soundAuthor')),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.t('requiredField')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (_loadingGroups)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      )
                    else
                      DropdownButtonFormField<String?>(
                        value: _groups.any((g) => g.id == _selectedGroupId)
                            ? _selectedGroupId
                            : null,
                        decoration: InputDecoration(
                          labelText:
                              l10n.tOr('soundGroupName', 'Group name'),
                          helperText: l10n.tOr(
                            'soundGroupNameHint',
                            'Optional — add this sound to a library shelf',
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.t('soundAddNoneGroup')),
                          ),
                          for (final group in _groups)
                            DropdownMenuItem<String?>(
                              value: group.id,
                              child: Text(group.name),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) =>
                                setState(() => _selectedGroupId = value),
                      ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.t('soundStatusActive')),
                      value: _isActive,
                      onChanged:
                          busy ? null : (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.tOr(
                          'soundIsFromDashboard',
                          'Public Dashboard Catalog Track',
                        ),
                      ),
                      subtitle: Text(
                        l10n.tOr(
                          'soundIsFromDashboardHint',
                          'Visible in public app library catalog',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      value: _isFromDashboard,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => _isFromDashboard = v),
                    ),
                    BlocSelector<SoundFormCubit, SoundFormState, String?>(
                      selector: (s) => s.fileError,
                      builder: (context, fileError) {
                        if (fileError == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            fileError,
                            style: TextStyle(color: scheme.error),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: Text(l10n.t('save')),
            ),
          ],
        );
      },
    );
  }
}
