import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../bloc/gifts_bloc.dart';
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
  DateTime? _publishedAt;
  Uint8List? _animationBytes;
  String? _animationName;

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
    setState(() {
      _animationBytes = picked.bytes;
      _animationName = picked.name;
    });
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
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(
          CreateGiftEvent(
            CreateGiftData(
              name: _nameCtrl.text.trim(),
              imageBytes: state.pendingImageBytes!,
              imageName: state.pendingImageName ?? 'gift.jpg',
              priceCoins: double.parse(_priceCtrl.text.trim()),
              publishedAt: _publishedAt,
              animationBytes: _animationBytes,
              animationName: _animationName,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final hasAnimation = _animationBytes != null;

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
        final canCreate = hasImage && !state.isActioning;

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
                      onPressed: state.isActioning ? null : _pickAnimation,
                      icon: const Icon(Icons.animation_rounded, size: 18),
                      label: Text(
                        hasAnimation
                            ? l10n.tOr('changeAnimation', 'Change animation')
                            : l10n.tOr(
                                'uploadAnimationOptional',
                                'Upload animation (MP4, optional)',
                              ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (hasAnimation) ...[
                      const SizedBox(height: 12),
                      GiftAnimationPreview(
                        bytes: _animationBytes,
                        fileName: _animationName,
                        onClear: state.isActioning
                            ? null
                            : () => setState(() {
                                  _animationBytes = null;
                                  _animationName = null;
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
