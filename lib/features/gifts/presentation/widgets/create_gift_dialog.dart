import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../bloc/gift_groups_bloc.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_image_picker.dart';
import 'gift_animation_preview.dart';
import 'gift_price_coins_field.dart';
import 'gift_published_at_picker.dart';

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
  final _formKey = GlobalKey<FormState>();
  String? _imageError;
  DateTime? _publishedAt = DateTime.now();
  String? _animationUrl;
  String? _animationName;
  Uint8List? _animationBytes;
  bool _uploadingAnimation = false;
  String? _animationError;
  GiftSize _selectedSize = GiftSize.medium;
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

  void _submit(GiftsLoaded state) {
    if (state.pendingImageBytes == null) {
      setState(() => _imageError = context.l10n.t('pleaseSelectImage'));
      return;
    }
    if (_uploadingAnimation) return;
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(
          CreateGiftEvent(
            CreateGiftData(
              name: _nameCtrl.text.trim(),
              imageBytes: state.pendingImageBytes!,
              imageName: state.pendingImageName ?? 'gift.jpg',
              priceCoins: double.parse(_priceCtrl.text.trim()),
              size: _selectedSize,
              publishedAt: _publishedAt,
              animationUrl: _animationUrl,
              assignGroupId: _selectedGroupId,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
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
        final canCreate =
            hasImage && !state.isActioning && !_uploadingAnimation;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenW < 560 ? 16 : 24,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.t('createNewGift')),
          content: SizedBox(
            width: dialogW,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.t('giftNameLabel'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => v?.trim().isEmpty == true
                          ? l10n.t('requiredField')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: state.isActioning ? null : _pickImage,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: Text(
                        hasImage
                            ? l10n.t('changeImage')
                            : l10n.t('uploadImageRequired'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_imageError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _imageError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (hasImage) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.memory(
                            state.pendingImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.pendingImageName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: (state.isActioning || _uploadingAnimation)
                          ? null
                          : _pickAnimation,
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
                                ? l10n.tOr(
                                    'changeAnimation',
                                    'Change animation',
                                  )
                                : l10n.tOr(
                                    'uploadAnimationOptional',
                                    'Upload animation (MP4 / PAG / JSON / Lottie / GIF / SWF, optional)',
                                  ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_animationError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _animationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (hasAnimation) ...[
                      const SizedBox(height: 12),
                      GiftAnimationPreview(
                        key: const ValueKey('create-gift-animation-preview'),
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
                    ],
                    const SizedBox(height: 14),
                    GiftPublishedAtPicker(
                      value: _publishedAt,
                      onTap: state.isActioning ? null : _pickPublishedAt,
                      onClear: _publishedAt != null
                          ? () => setState(() => _publishedAt = null)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<GiftSize>(
                      value: _selectedSize,
                      decoration: InputDecoration(
                        labelText: l10n.tOr('giftSizeLabel', 'Size'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                    const SizedBox(height: 14),
                    if (_loadingGroups)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String?>(
                        value: _groups.any((g) => g.id == _selectedGroupId)
                            ? _selectedGroupId
                            : null,
                        decoration: InputDecoration(
                          labelText: l10n.tOr('giftGroupName', 'Tab name'),
                          helperText: l10n.tOr(
                            'giftGroupNameHint',
                            'Optional — add to a gift panel tab',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                    const SizedBox(height: 14),
                    GiftPriceCoinsField(
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
                    if (state.isActioning) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.t('uploadingCreatingGift')),
                        ],
                      ),
                    ],
                  ],
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
}
