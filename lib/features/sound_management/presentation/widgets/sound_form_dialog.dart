import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';
import '../utils/sound_audio_duration_parser.dart';
import '../utils/sound_audio_duration_web.dart';
import '../utils/sound_file_picker_web.dart';

class SoundFormDialog extends StatefulWidget {
  const SoundFormDialog({
    super.key,
    this.sound,
  });

  final SoundEntity? sound;

  bool get isEditing => sound != null;

  static Future<SoundFormResult?> show(
    BuildContext context, {
    SoundEntity? sound,
  }) {
    return showDialog<SoundFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SoundFormDialog(sound: sound),
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
  });

  final CreateSoundData? createData;
  final UploadSoundData? uploadData;
  final UpdateSoundData? updateData;
}

class _SoundFormDialogState extends State<SoundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _audioUrlController;
  late bool _isActive;

  String? _audioFilename;
  List<int>? _audioBytes;
  String? _coverFilename;
  List<int>? _coverBytes;
  String? _fileError;
  int? _detectedDuration;
  bool _detectingDuration = false;

  @override
  void initState() {
    super.initState();
    final sound = widget.sound;
    _nameController = TextEditingController(text: sound?.name ?? '');
    _authorController = TextEditingController(text: sound?.author ?? '');
    _audioUrlController = TextEditingController(text: sound?.audioUrl ?? '');
    _isActive = sound?.isActive ?? true;
    _detectedDuration = sound?.duration;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudioFile();
    if (!mounted || picked == null) return;

    if (picked.bytes.length > kMaxAudioUploadBytes) {
      setState(() {
        _fileError = context.l10n.t('soundAudioTooLarge');
      });
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
    setState(() {
      _coverBytes = picked.bytes;
      _coverFilename = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _detectingDuration) return;

    if (widget.isEditing) {
      Navigator.of(context).pop(
        SoundFormResult(
          updateData: UpdateSoundData(
            name: _nameController.text.trim(),
            author: _authorController.text.trim(),
            isActive: _isActive,
          ),
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
          isActive: _isActive,
        ),
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
    final busy = _detectingDuration;

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
