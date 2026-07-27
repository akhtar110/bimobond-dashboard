import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../bloc/gift_groups_bloc.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_image_picker.dart';
import 'gift_animation_preview.dart';
import 'gift_audio_preview.dart';
import 'gift_color_picker_field.dart';
import 'gift_dialog_layout.dart';
import 'gift_price_coins_field.dart';
import 'gift_published_at_picker.dart';
import 'gift_type_selector.dart';

void showCreateGiftDialog(BuildContext pageContext) {
  pageContext.read<GiftsBloc>().add(ClearGiftImageEvent());
  showDialog<void>(
    context: pageContext,
    builder: (_) => CreateGiftDialog(pageContext: pageContext),
  );
}

class CreateGiftDialog extends StatefulWidget {
  const CreateGiftDialog({required this.pageContext});
  final BuildContext pageContext;

  @override
  State<CreateGiftDialog> createState() => CreateGiftDialogState();
}

class CreateGiftDialogState extends State<CreateGiftDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _imageError;
  DateTime? _publishedAt = DateTime.now();
  String? _animationUrl;
  String? _animationName;
  Uint8List? _animationBytes;
  bool _uploadingAnimation = false;
  String? _animationError;
  GiftSize _selectedSize = GiftSize.medium;
  GiftType _selectedType = GiftType.image;
  String? _selectedColor;
  bool _isActive = true;
  String? _audioUrl;
  String? _audioName;
  Uint8List? _audioBytes;
  bool _uploadingAudio = false;
  String? _audioError;
  String? _selectedGroupId;
  bool _loadingGroups = false;
  List<GiftGroupEntity> _groups = const [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final blocState = widget.pageContext.read<GiftGroupsBloc>().state;
    if (blocState is GiftGroupsLoaded) {
      setState(() => _groups = blocState.groups);
      return;
    }
    setState(() => _loadingGroups = true);
    try {
      final groups = await di.sl<GetGiftGroupsUseCase>()();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _tagCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickGiftImage();
    if (!mounted || picked == null) return;
    widget.pageContext.read<GiftsBloc>().add(
          SetGiftImageEvent(bytes: picked.bytes, name: picked.name),
        );
    setState(() => _imageError = null);
  }

  Future<void> _pickAnimation() async {
    final picked = await pickGiftAnimation();
    if (!mounted || picked == null) return;

    // Preview immediately from memory; upload URL in the background.
    setState(() {
      _animationBytes = picked.bytes;
      _animationName = picked.name;
      _animationUrl = null;
      _uploadingAnimation = true;
      _animationError = null;
    });

    try {
      final url = await di.sl<GiftsRepository>().uploadGiftFile(
            picked.bytes,
            picked.name,
          );
      if (!mounted) return;
      GiftAnimationBytesCache.put(url, picked.bytes);
      setState(() {
        _animationUrl = url;
        _uploadingAnimation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAnimation = false;
        _animationError = e.toString().replaceFirst('Exception: ', '');
        _animationUrl = null;
      });
    }
  }

  Future<void> _pickAudio() async {
    final picked = await pickGiftAudio();
    if (!mounted || picked == null) return;

    setState(() {
      _audioBytes = picked.bytes;
      _audioName = picked.name;
      _audioUrl = null;
      _uploadingAudio = true;
      _audioError = null;
    });

    try {
      final url = await di.sl<GiftsRepository>().uploadGiftFile(
            picked.bytes,
            picked.name,
          );
      if (!mounted) return;
      setState(() {
        _audioUrl = url;
        _uploadingAudio = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAudio = false;
        _audioError = e.toString().replaceFirst('Exception: ', '');
        _audioUrl = null;
      });
    }
  }

  Future<void> _pickPublishedAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final initialTime = TimeOfDay.fromDateTime(_publishedAt ?? now);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;

    setState(() {
      if (time != null) {
        _publishedAt =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      } else {
        _publishedAt = date;
      }
    });
  }

  String? _normalizedTag() {
    final raw = _tagCtrl.text.trim();
    if (raw.isEmpty) return null;
    return raw.length <= 50 ? raw : raw.substring(0, 50);
  }

  void _submit(GiftsLoaded state) {
    if (_selectedType == GiftType.image && state.pendingImageBytes == null) {
      setState(() => _imageError = context.l10n.t('pleaseSelectImage'));
      return;
    }
    if (_uploadingAnimation || _uploadingAudio) return;
    if (_selectedType == GiftType.audio &&
        (_audioUrl == null || _audioUrl!.trim().isEmpty)) {
      setState(() {
        _audioError = context.l10n.tOr(
          'giftAudioRequired',
          'Audio file is required for audio gifts',
        );
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(
          CreateGiftEvent(
            CreateGiftData(
              name: _nameCtrl.text.trim(),
              imageBytes: _selectedType == GiftType.image
                  ? state.pendingImageBytes
                  : null,
              imageName: _selectedType == GiftType.image
                  ? (state.pendingImageName ?? 'gift.jpg')
                  : null,
              priceCoins: double.parse(_priceCtrl.text.trim()),
              size: _selectedSize,
              type: _selectedType,
              tag: _normalizedTag(),
              color: _selectedType == GiftType.audio ? _selectedColor : null,
              sortOrder: int.tryParse(_sortOrderCtrl.text.trim()),
              isActive: _isActive,
              publishedAt: _publishedAt,
              animationUrl: _selectedType == GiftType.image
                  ? _animationUrl
                  : null,
              audioUrl: _selectedType == GiftType.audio ? _audioUrl : null,
              assignGroupId: _selectedGroupId,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final layout = GiftDialogLayout(MediaQuery.sizeOf(context));
    final hasAnimation = (_animationBytes != null &&
            _animationBytes!.isNotEmpty) ||
        (_animationUrl != null && _animationUrl!.trim().isNotEmpty);

    return BlocBuilder<GiftsBloc, GiftsState>(
      bloc: widget.pageContext.read<GiftsBloc>(),
      buildWhen: (p, c) =>
          c is GiftsLoaded &&
          (p is! GiftsLoaded ||
              p.pendingImageBytes != c.pendingImageBytes ||
              p.isActioning != c.isActioning),
      builder: (_, state) {
        if (state is! GiftsLoaded) return const SizedBox.shrink();

        final hasImage = state.pendingImageBytes != null;
        final canCreate = !state.isActioning &&
            !_uploadingAnimation &&
            !_uploadingAudio &&
            (_selectedType == GiftType.audio || hasImage);

        final mediaColumn = _buildMediaColumn(
          context: context,
          layout: layout,
          l10n: l10n,
          state: state,
          hasImage: hasImage,
          hasAnimation: hasAnimation,
        );
        final fieldsColumn = _buildFieldsColumn(
          context: context,
          layout: layout,
          l10n: l10n,
          state: state,
        );

        return AlertDialog(
          insetPadding: layout.insetPadding,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.t('createNewGift')),
          content: SizedBox(
            width: layout.dialogWidth,
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: layout.maxBodyHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GiftTypeSelector(
                        value: _selectedType,
                        enabled: !state.isActioning,
                        onChanged: (value) => setState(() {
                          _selectedType = value;
                          if (value == GiftType.audio) {
                            _imageError = null;
                          }
                        }),
                      ),
                      SizedBox(height: layout.gap),
                      mediaColumn,
                      SizedBox(height: layout.gap),
                      fieldsColumn,
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: canCreate ? () => _submit(state) : null,
              child: Text(l10n.t('createGift')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required GiftsLoaded state,
    required bool hasImage,
    required bool hasAnimation,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final imageTile = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isActioning ? null : _pickImage,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            hasImage ? l10n.t('changeImage') : l10n.t('uploadImageRequired'),
          ),
          style: layout.denseOutlinedButtonStyle(),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 4),
          Text(
            _imageError!,
            style: TextStyle(color: scheme.error, fontSize: 12),
          ),
        ],
        SizedBox(height: layout.fieldGap),
        layout.mediaFrame(
          child: hasImage
              ? Image.memory(
                  state.pendingImageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      size: 28,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 4),
          Text(
            state.pendingImageName ?? '',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    final animationTile = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed:
              (state.isActioning || _uploadingAnimation) ? null : _pickAnimation,
          icon: _uploadingAnimation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.animation_rounded, size: 18),
          label: Text(
            _uploadingAnimation
                ? l10n.tOr('uploading', 'Uploading…')
                : hasAnimation
                    ? l10n.tOr('changeAnimation', 'Change animation')
                    : l10n.tOr(
                        'uploadAnimationOptional',
                        'Upload animation (optional)',
                      ),
          ),
          style: layout.denseOutlinedButtonStyle(),
        ),
        if (_animationError != null) ...[
          const SizedBox(height: 4),
          Text(
            _animationError!,
            style: TextStyle(color: scheme.error, fontSize: 12),
          ),
        ],
        SizedBox(height: layout.fieldGap),
        if (hasAnimation)
          SizedBox(
            height: layout.mediaMaxHeight + 56,
            child: GiftAnimationPreview(
              key: const ValueKey('create-gift-animation-preview'),
              compact: true,
              expandToFill: true,
              bytes: _animationBytes,
              networkUrl: _animationUrl,
              fileName: _animationName ?? _animationUrl,
              onClear: (state.isActioning || _uploadingAnimation)
                  ? null
                  : () => setState(() {
                        _animationBytes = null;
                        _animationUrl = null;
                        _animationName = null;
                        _animationError = null;
                      }),
            ),
          )
        else if (layout.useWideLayout)
          layout.mediaFrame(
            child: ColoredBox(
              color: scheme.surfaceContainerLow,
              child: Center(
                child: Text(
                  l10n.tOr('noAnimation', 'No animation'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    final hasAudio = (_audioBytes != null && _audioBytes!.isNotEmpty) ||
        (_audioUrl != null && _audioUrl!.trim().isNotEmpty);
    final audioTile = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: (state.isActioning || _uploadingAudio) ? null : _pickAudio,
          icon: _uploadingAudio
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.audiotrack_rounded, size: 18),
          label: Text(
            _uploadingAudio
                ? l10n.tOr('uploading', 'Uploading…')
                : hasAudio
                    ? l10n.tOr('changeAudio', 'Change audio')
                    : l10n.tOr('uploadAudioRequired', 'Upload audio *'),
          ),
          style: layout.denseOutlinedButtonStyle(),
        ),
        if (_audioError != null) ...[
          const SizedBox(height: 4),
          Text(
            _audioError!,
            style: TextStyle(color: scheme.error, fontSize: 12),
          ),
        ],
        if (hasAudio) ...[
          SizedBox(height: layout.fieldGap),
          GiftAudioPreview(
            key: ValueKey('create-audio-${_audioUrl ?? _audioName}'),
            networkUrl: _audioUrl,
            bytes: _audioBytes,
            fileName: _audioName ?? _audioUrl,
            onClear: (state.isActioning || _uploadingAudio)
                ? null
                : () => setState(() {
                      _audioBytes = null;
                      _audioUrl = null;
                      _audioName = null;
                      _audioError = null;
                    }),
          ),
        ],
      ],
    );

    final secondaryTile =
        _selectedType == GiftType.audio ? audioTile : animationTile;

    if (_selectedType == GiftType.audio) {
      final colorTile = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GiftColorPickerField(
            layout: layout,
            value: _selectedColor,
            enabled: !state.isActioning,
            onChanged: (value) => setState(() => _selectedColor = value),
          ),
          SizedBox(height: layout.fieldGap),
          layout.mediaFrame(
            child: ColoredBox(
              color: parseGiftHex(_selectedColor) ??
                  scheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.audiotrack_rounded,
                  size: 28,
                  color: (parseGiftHex(_selectedColor) == null
                          ? scheme.onSurfaceVariant
                          : _contrastingOnColor(
                              parseGiftHex(_selectedColor)!))
                      .withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      );

      if (layout.useWideLayout) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: colorTile),
            SizedBox(width: layout.fieldGap),
            Expanded(child: audioTile),
          ],
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          colorTile,
          SizedBox(height: layout.fieldGap),
          audioTile,
        ],
      );
    }

    if (layout.useWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: imageTile),
          SizedBox(width: layout.fieldGap),
          Expanded(child: secondaryTile),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        imageTile,
        SizedBox(height: layout.fieldGap),
        secondaryTile,
      ],
    );
  }

  Color _contrastingOnColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.55 ? Colors.black87 : Colors.white;
  }

  Widget _buildFieldsColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required GiftsLoaded state,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: layout.denseDecoration(labelText: l10n.t('giftNameLabel')),
          validator: (v) =>
              v?.trim().isEmpty == true ? l10n.t('requiredField') : null,
        ),
        SizedBox(height: layout.fieldGap),
        TextFormField(
          controller: _tagCtrl,
          enabled: !state.isActioning,
          maxLength: 50,
          decoration: layout.denseDecoration(
            labelText: l10n.tOr('giftTag', 'Tag'),
            helperText: l10n.tOr(
              'giftTagHint',
              'Any string up to 50 chars, e.g. NEW, HOT, LIMITED',
            ),
          ),
        ),
        SizedBox(height: layout.fieldGap),
        if (layout.useWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<GiftSize>(
                  value: _selectedSize,
                  isDense: true,
                  decoration: layout.denseDecoration(
                    labelText: l10n.tOr('giftSizeLabel', 'Size'),
                  ),
                  items: GiftSize.values
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text(size.apiValue),
                        ),
                      )
                      .toList(),
                  onChanged: state.isActioning
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedSize = value);
                          }
                        },
                ),
              ),
              SizedBox(width: layout.fieldGap),
              Expanded(
                child: _loadingGroups
                    ? const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<String?>(
                        value: _groups.any((g) => g.id == _selectedGroupId)
                            ? _selectedGroupId
                            : null,
                        isDense: true,
                        decoration: layout.denseDecoration(
                          labelText: l10n.tOr('giftGroupName', 'Tab name'),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.tOr('giftAddNoneGroup', 'None')),
                          ),
                          for (final group in _groups)
                            DropdownMenuItem<String?>(
                              value: group.id,
                              child: Text(group.name),
                            ),
                        ],
                        onChanged: state.isActioning
                            ? null
                            : (value) =>
                                setState(() => _selectedGroupId = value),
                      ),
              ),
            ],
          )
        else ...[
          DropdownButtonFormField<GiftSize>(
            value: _selectedSize,
            isDense: true,
            decoration: layout.denseDecoration(
              labelText: l10n.tOr('giftSizeLabel', 'Size'),
            ),
            items: GiftSize.values
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(size.apiValue),
                  ),
                )
                .toList(),
            onChanged: state.isActioning
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _selectedSize = value);
                    }
                  },
          ),
          SizedBox(height: layout.fieldGap),
          if (_loadingGroups)
            const LinearProgressIndicator()
          else
            DropdownButtonFormField<String?>(
              value: _groups.any((g) => g.id == _selectedGroupId)
                  ? _selectedGroupId
                  : null,
              isDense: true,
              decoration: layout.denseDecoration(
                labelText: l10n.tOr('giftGroupName', 'Tab name'),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.tOr('giftAddNoneGroup', 'None')),
                ),
                for (final group in _groups)
                  DropdownMenuItem<String?>(
                    value: group.id,
                    child: Text(group.name),
                  ),
              ],
              onChanged: state.isActioning
                  ? null
                  : (value) => setState(() => _selectedGroupId = value),
            ),
        ],
        SizedBox(height: layout.fieldGap),
        if (layout.useWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GiftPriceCoinsField(
                  controller: _priceCtrl,
                  enabled: !state.isActioning,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) {
                      return l10n.t('requiredField');
                    }
                    if (double.tryParse(v!.trim()) == null) {
                      return l10n.t('requiredField');
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: layout.fieldGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: GiftPublishedAtPicker(
                    value: _publishedAt,
                    onTap: state.isActioning ? null : _pickPublishedAt,
                    onClear: _publishedAt != null
                        ? () => setState(() => _publishedAt = null)
                        : null,
                  ),
                ),
              ),
            ],
          )
        else ...[
          GiftPriceCoinsField(
            controller: _priceCtrl,
            enabled: !state.isActioning,
            validator: (v) {
              if (v?.trim().isEmpty == true) return l10n.t('requiredField');
              if (double.tryParse(v!.trim()) == null) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
          SizedBox(height: layout.fieldGap),
          GiftPublishedAtPicker(
            value: _publishedAt,
            onTap: state.isActioning ? null : _pickPublishedAt,
            onClear: _publishedAt != null
                ? () => setState(() => _publishedAt = null)
                : null,
          ),
        ],
        SizedBox(height: layout.fieldGap),
        TextFormField(
          controller: _sortOrderCtrl,
          enabled: !state.isActioning,
          keyboardType: TextInputType.number,
          decoration: layout.denseDecoration(
            labelText: l10n.tOr('giftSortOrder', 'Sort order'),
          ),
        ),
        SizedBox(height: layout.fieldGap),
        SwitchListTile.adaptive(
          value: _isActive,
          onChanged: state.isActioning
              ? null
              : (value) => setState(() => _isActive = value),
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            l10n.tOr('activeLabel', 'Active'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        if (state.isActioning) ...[
          SizedBox(height: layout.fieldGap),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.t('uploadingCreatingGift'))),
            ],
          ),
        ],
      ],
    );
  }
}
