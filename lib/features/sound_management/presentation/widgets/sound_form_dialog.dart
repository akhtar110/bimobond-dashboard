import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../../domain/repositories/sound_management_repository.dart';
import '../../domain/usecases/sound_usecases.dart';
import '../utils/sound_audio_duration_parser.dart';
import '../utils/sound_audio_duration_web.dart';
import '../utils/sound_file_picker_web.dart';

class SoundFormDialog extends StatefulWidget {
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
      builder: (_) => SoundFormDialog(sound: sound, initialGroups: groups),
    );
  }

  @override
  State<SoundFormDialog> createState() => _SoundFormDialogState();
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

class _SoundFormDialogState extends State<SoundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _audioUrlController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _durationController;
  late bool _isActive;

  String? _audioFilename;
  List<int>? _audioBytes;
  String? _coverFilename;
  List<int>? _coverBytes;
  String? _coverUrl;
  Uint8List? _coverPreviewBytes;
  bool _uploadingCover = false;
  String? _coverError;
  String? _fileError;
  int? _detectedDuration;
  bool _detectingDuration = false;
  List<SoundGroupEntity> _groups = const [];
  bool _loadingGroups = false;
  String? _selectedGroupId;
  String? _initialGroupId;

  bool get _hasCover =>
      (_coverPreviewBytes != null && _coverPreviewBytes!.isNotEmpty) ||
      (_coverUrl != null && _coverUrl!.trim().isNotEmpty) ||
      (_coverBytes != null && _coverBytes!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final sound = widget.sound;
    _nameController = TextEditingController(text: sound?.name ?? '');
    _authorController = TextEditingController(text: sound?.author ?? '');
    _audioUrlController = TextEditingController(
      text: resolveMediaUrl(sound?.audioUrl) ?? sound?.audioUrl ?? '',
    );
    _coverUrlController = TextEditingController(
      text: resolveMediaUrl(sound?.coverUrl) ?? sound?.coverUrl ?? '',
    );
    _coverUrl = resolveMediaUrl(sound?.coverUrl) ?? sound?.coverUrl;
    _durationController = TextEditingController(
      text: sound != null && sound.duration > 0 ? '${sound.duration}' : '',
    );
    _isActive = sound?.isActive ?? true;
    _detectedDuration = sound?.duration;
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
    _audioUrlController.dispose();
    _coverUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudioFile();
    if (!mounted || picked == null) return;

    if (picked.bytes.length > kMaxAudioUploadBytes) {
      final message = context.l10n.t('soundAudioMaxSizeExceeded');
      setState(() {
        _fileError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (!isAllowedAudioFilename(picked.name)) {
      setState(() {
        _fileError = context.l10n.t('soundInvalidAudioFormat');
      });
      return;
    }

    setState(() {
      _detectingDuration = true;
      _fileError = null;
      _audioBytes = picked.bytes;
      _audioFilename = picked.name;
      _detectedDuration = null;
      _audioUrlController.clear();
    });

    final duration = parseAudioDurationFromBytes(picked.bytes, picked.name) ??
        await probeAudioDurationFromBytes(picked.bytes, picked.name);
    if (!mounted) return;

    setState(() {
      _detectingDuration = false;
      _detectedDuration = duration;
    });
  }

  Future<void> _pickCover() async {
    final picked = await pickCoverImageFile();
    if (!mounted || picked == null) return;

    if (widget.isEditing) {
      setState(() {
        _coverPreviewBytes = picked.bytes;
        _coverFilename = picked.name;
        _uploadingCover = true;
        _coverError = null;
      });
      try {
        final url = await di.sl<SoundManagementRepository>().uploadSoundFile(
              picked.bytes,
              picked.name,
            );
        if (!mounted) return;
        setState(() {
          _coverUrl = url;
          _coverBytes = picked.bytes;
          _uploadingCover = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _uploadingCover = false;
          _coverPreviewBytes = null;
          _coverFilename = null;
          _coverBytes = null;
          _coverError = e.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }

    setState(() {
      _coverBytes = picked.bytes;
      _coverFilename = picked.name;
      _coverPreviewBytes = picked.bytes;
      _coverUrlController.clear();
      _coverError = null;
    });
  }

  void _clearCover() {
    setState(() {
      _coverUrl = null;
      _coverBytes = null;
      _coverFilename = null;
      _coverPreviewBytes = null;
      _coverError = null;
      _coverUrlController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _detectingDuration ||
        _uploadingCover) {
      return;
    }

    if (widget.isEditing) {
      final durationText = _durationController.text.trim();
      final parsedDuration = int.tryParse(durationText);
      final coverUrl = resolveMediaUrl(_coverUrl?.trim()) ?? _coverUrl?.trim();
      final audioUrl = resolveMediaUrl(_audioUrlController.text.trim()) ??
          _audioUrlController.text.trim();
      Navigator.of(context).pop(
        SoundFormResult(
          updateData: UpdateSoundData(
            name: _nameController.text.trim(),
            author: _authorController.text.trim(),
            audioUrl: audioUrl.isEmpty ? null : audioUrl,
            coverUrl: coverUrl == null || coverUrl.isEmpty ? null : coverUrl,
            clearCoverUrl: coverUrl == null || coverUrl.isEmpty,
            duration: parsedDuration != null && parsedDuration > 0
                ? parsedDuration
                : null,
            isActive: _isActive,
          ),
          assignGroupId: _selectedGroupId,
          previousAssignGroupId: _initialGroupId,
        ),
      );
      return;
    }

    if (_audioBytes == null &&
        _audioFilename == null &&
        _audioUrlController.text.trim().isEmpty) {
      setState(() {
        _fileError = context.l10n.t('soundAudioRequired');
      });
      return;
    }

    final duration = _detectedDuration ?? 0;

    if (_audioBytes != null && _audioFilename != null) {
      if (_audioBytes!.length > kMaxAudioUploadBytes) {
        final message = context.l10n.t('soundAudioMaxSizeExceeded');
        setState(() {
          _fileError = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      Navigator.of(context).pop(
        SoundFormResult(
          uploadData: UploadSoundData(
            bytes: _audioBytes!,
            filename: _audioFilename!,
            name: _nameController.text.trim(),
            author: _authorController.text.trim(),
            duration: duration,
            coverBytes: _coverBytes,
            coverFilename: _coverFilename,
          ),
          assignGroupId: _selectedGroupId,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      SoundFormResult(
        createData: CreateSoundData(
          name: _nameController.text.trim(),
          author: _authorController.text.trim(),
          audioUrl: _audioUrlController.text.trim(),
          duration: duration,
          coverUrl: _coverUrlController.text.trim().isEmpty
              ? null
              : _coverUrlController.text.trim(),
          isActive: _isActive,
        ),
        assignGroupId: _selectedGroupId,
      ),
    );
  }

  String? _detectedDurationLabel(BuildContext context) {
    final seconds = _detectedDuration;
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
    final durationLabel = _detectedDurationLabel(context);
    final busy = _detectingDuration || _uploadingCover;

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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (_audioFilename != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _audioFilename!,
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(l10n.t('soundOrUseUrl'), style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _audioUrlController,
                    enabled: !busy && _audioBytes == null,
                    onChanged: (_) {
                      if (_audioBytes != null) return;
                      setState(() {
                        _detectedDuration = null;
                        _fileError = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: l10n.t('soundAudioUrl'),
                      hintText: '/uploads/sounds/beat.mp3',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _pickCover,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.t('soundUploadCover')),
                  ),
                  if (_coverFilename != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_coverFilename!),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coverUrlController,
                    enabled: !busy && _coverBytes == null,
                    decoration: InputDecoration(
                      labelText: l10n.tOr('soundCoverUrl', 'Cover URL'),
                      hintText: '/uploads/sounds/cover.jpg',
                    ),
                  ),
                  if (_detectingDuration) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ] else if (durationLabel != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.t('soundDuration')}: $durationLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ] else ...[
                  TextFormField(
                    controller: _audioUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.t('soundAudioUrl'),
                      hintText: '/uploads/sounds/beat.mp3',
                    ),
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
                  OutlinedButton.icon(
                    onPressed: busy ? null : _pickCover,
                    icon: _uploadingCover
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _uploadingCover
                          ? l10n.tOr('uploading', 'Uploading…')
                          : _hasCover
                              ? l10n.t('changeImage')
                              : l10n.tOr('uploadImage', 'Upload image'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_coverError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _coverError!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ],
                  if (_hasCover) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 72,
                            height: 72,
                            color: scheme.surfaceContainerHighest,
                            child: _coverPreviewBytes != null
                                ? Image.memory(
                                    _coverPreviewBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : (_coverUrl != null &&
                                        _coverUrl!.trim().isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: _coverUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                          Icons.broken_image_outlined,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_outlined,
                                        color: scheme.onSurfaceVariant,
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_coverFilename != null)
                                Text(
                                  _coverFilename!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              TextButton.icon(
                                onPressed: busy ? null : _clearCover,
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: Text(l10n.tOr('remove', 'Remove')),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.t('soundDuration'),
                      helperText: l10n.tOr('soundDurationSecondsHint', 'Seconds'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.t('soundName')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  decoration: InputDecoration(labelText: l10n.t('soundAuthor')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.t('requiredField') : null,
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
                      labelText: l10n.tOr('soundGroupName', 'Group name'),
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
                        : (value) => setState(() => _selectedGroupId = value),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.t('soundStatusActive')),
                  value: _isActive,
                  onChanged: busy ? null : (v) => setState(() => _isActive = v),
                ),
                if (_fileError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _fileError!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
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
  }
}
