import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/sound_group_entities.dart';
import '../../domain/repositories/sound_management_repository.dart';
import '../utils/sound_file_picker_web.dart';

class SoundGroupFormDialog extends StatefulWidget {
  const SoundGroupFormDialog({super.key, this.group});

  final SoundGroupEntity? group;

  bool get isEditing => group != null;

  static Future<SoundGroupFormResult?> show(
    BuildContext context, {
    SoundGroupEntity? group,
  }) {
    return showDialog<SoundGroupFormResult>(
      context: context,
      builder: (_) => SoundGroupFormDialog(group: group),
    );
  }

  @override
  State<SoundGroupFormDialog> createState() => _SoundGroupFormDialogState();
}

class SoundGroupFormResult {
  SoundGroupFormResult.create(this.createData) : updateData = null;
  SoundGroupFormResult.update(this.updateData) : createData = null;

  final CreateSoundGroupData? createData;
  final UpdateSoundGroupData? updateData;
}

class _SoundGroupFormDialogState extends State<SoundGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _sortOrderController;
  late bool _isActive;

  String? _iconUrl;
  Uint8List? _iconPreviewBytes;
  String? _iconFileName;
  bool _uploadingIcon = false;
  String? _iconError;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _slugController = TextEditingController(text: group?.slug ?? '');
    _sortOrderController =
        TextEditingController(text: '${group?.sortOrder ?? 0}');
    _isActive = group?.isActive ?? true;
    _iconUrl = group?.iconUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  bool get _hasIcon =>
      (_iconPreviewBytes != null && _iconPreviewBytes!.isNotEmpty) ||
      (_iconUrl != null && _iconUrl!.trim().isNotEmpty);

  Future<void> _pickIcon() async {
    final picked = await pickCoverImageFile();
    if (!mounted || picked == null) return;

    setState(() {
      _iconPreviewBytes = picked.bytes;
      _iconFileName = picked.name;
      _uploadingIcon = true;
      _iconError = null;
    });

    try {
      final url = await di.sl<SoundManagementRepository>().uploadSoundFile(
            picked.bytes,
            picked.name,
          );
      if (!mounted) return;
      setState(() {
        _iconUrl = url;
        _uploadingIcon = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingIcon = false;
        _iconPreviewBytes = null;
        _iconFileName = null;
        _iconError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _clearIcon() {
    setState(() {
      _iconUrl = null;
      _iconPreviewBytes = null;
      _iconFileName = null;
      _iconError = null;
    });
  }

  void _submit() {
    if (_uploadingIcon) return;
    if (!_formKey.currentState!.validate()) return;
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final iconUrl = _iconUrl?.trim();

    if (widget.isEditing) {
      Navigator.of(context).pop(
        SoundGroupFormResult.update(
          UpdateSoundGroupData(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            iconUrl: iconUrl?.isEmpty ?? true ? null : iconUrl,
            clearIconUrl: iconUrl == null || iconUrl.isEmpty,
            sortOrder: sortOrder,
            isActive: _isActive,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      SoundGroupFormResult.create(
        CreateSoundGroupData(
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          iconUrl: iconUrl?.isEmpty ?? true ? null : iconUrl,
          sortOrder: sortOrder,
          isActive: _isActive,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.isEditing
            ? l10n.tOr('soundGroupEditTitle', 'Edit group')
            : l10n.tOr('soundGroupAddTitle', 'Add group'),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('soundGroupName', 'Name'),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('soundGroupSlug', 'Slug'),
                    helperText: l10n.tOr('soundGroupSlugHint', 'Unique, lowercase'),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tOr('soundGroupIconUrl', 'Group icon'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
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
                  onPressed: _uploadingIcon ? null : _pickIcon,
                  icon: _uploadingIcon
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
                    _uploadingIcon
                        ? l10n.tOr('uploading', 'Uploading…')
                        : _hasIcon
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
                if (_iconError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _iconError!,
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ],
                if (_hasIcon) ...[
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
                          child: _iconPreviewBytes != null
                              ? Image.memory(
                                  _iconPreviewBytes!,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: _iconUrl!,
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
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image_outlined,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_iconFileName != null)
                              Text(
                                _iconFileName!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            TextButton.icon(
                              onPressed: _uploadingIcon ? null : _clearIcon,
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
                  controller: _sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.tOr('soundGroupSortOrder', 'Sort order'),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.t('soundStatusActive')),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _uploadingIcon ? null : _submit,
          child: Text(l10n.t('save')),
        ),
      ],
    );
  }
}
