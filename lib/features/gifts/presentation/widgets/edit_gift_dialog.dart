import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_image_picker.dart';
import 'gift_animation_preview.dart';
import 'gift_price_coins_field.dart';
import 'gift_published_at_picker.dart';

void showEditGiftDialog(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => EditGiftDialog(pageContext: pageContext, gift: gift),
  );
}

void showPreviewGiftDialog(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => EditGiftDialog(
      pageContext: pageContext,
      gift: gift,
      previewOnly: true,
    ),
  );
}

class EditGiftDialog extends StatefulWidget {
  const EditGiftDialog({
    required this.pageContext,
    required this.gift,
    this.previewOnly = false,
  });

  final BuildContext pageContext;
  final GiftEntity gift;
  final bool previewOnly;

  @override
  State<EditGiftDialog> createState() => EditGiftDialogState();
}

class EditGiftDialogState extends State<EditGiftDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();

  Uint8List? _newImageBytes;
  String? _newImageName;
  String? _animationUrl;
  String? _animationName;
  Uint8List? _animationBytes;
  bool _clearAnimation = false;
  bool _uploadingAnimation = false;
  String? _animationError;
  DateTime? _publishedAt;
  late GiftSize _selectedSize;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.gift.name);
    _priceCtrl = TextEditingController(
        text: widget.gift.priceCoins.toStringAsFixed(2));
    _publishedAt = widget.gift.publishedAt;
    _selectedSize = widget.gift.size;
    _animationUrl = widget.gift.animationUrl;
    _animationName = widget.gift.animationUrl;
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
    setState(() {
      _newImageBytes = picked.bytes;
      _newImageName = picked.name;
    });
  }

  Future<void> _pickAnimation() async {
    final picked = await pickGiftAnimation();
    if (!mounted || picked == null) return;

    setState(() {
      _animationBytes = picked.bytes;
      _animationName = picked.name;
      _animationUrl = null;
      _uploadingAnimation = true;
      _animationError = null;
      _clearAnimation = false;
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
      _publishedAt = time != null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          : date;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadingAnimation) return;

    final originalUrl = widget.gift.animationUrl;
    String? animationUrl;
    var clearAnimationUrl = false;
    if (_clearAnimation) {
      clearAnimationUrl = true;
    } else if (_animationUrl != null &&
        _animationUrl!.trim().isNotEmpty &&
        _animationUrl != originalUrl) {
      animationUrl = _animationUrl;
    }

    widget.pageContext.read<GiftsBloc>().add(UpdateGiftEvent(
          widget.gift.id,
          UpdateGiftData(
            name: _nameCtrl.text.trim().isEmpty
                ? null
                : _nameCtrl.text.trim(),
            priceCoins: double.tryParse(_priceCtrl.text.trim()),
            size: _selectedSize,
            publishedAt: _publishedAt,
            clearPublishedAt:
                widget.gift.publishedAt != null && _publishedAt == null,
            imageBytes: _newImageBytes,
            imageName: _newImageName,
            animationUrl: animationUrl,
            clearAnimationUrl: clearAnimationUrl,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewOnly) {
      return _buildPreviewDialog(context);
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final screenW = screenSize.width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final maxContentH = screenSize.height * 0.7;
    final hasNewImage = _newImageBytes != null;
    final showAnimation = !_clearAnimation &&
        ((_animationBytes != null && _animationBytes!.isNotEmpty) ||
            (_animationUrl != null && _animationUrl!.trim().isNotEmpty));

    return BlocListener<GiftsBloc, GiftsState>(
      bloc: widget.pageContext.read<GiftsBloc>(),
      // Only close after a save we started finishes — not on unrelated
      // isActioning flips (those were disposing the PAG player mid-play).
      listenWhen: (p, c) =>
          p is GiftsLoaded &&
          c is GiftsLoaded &&
          p.isActioning &&
          !c.isActioning,
      listener: (_, state) {
        if (state is GiftsLoaded && !state.isActioning && mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      },
      child: BlocBuilder<GiftsBloc, GiftsState>(
        bloc: widget.pageContext.read<GiftsBloc>(),
        buildWhen: (p, c) =>
            c is GiftsLoaded &&
            (p is! GiftsLoaded || p.isActioning != c.isActioning),
        builder: (_, state) {
          final isActioning =
              state is GiftsLoaded && state.isActioning;

          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenW < 560 ? 16 : 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.t('editGift')),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxContentH,
                minWidth: dialogW,
                maxWidth: dialogW,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // Top padding keeps the floating label of the first field
                  // (gift name) from being clipped by the scroll view.
                  padding: const EdgeInsets.only(top: 8),
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
                        onPressed: isActioning ? null : _pickImage,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(
                          hasNewImage
                              ? l10n.t('changeImage')
                              : l10n.t('uploadNewImage'),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: hasNewImage
                              ? Image.memory(
                                  _newImageBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                )
                              : (widget.gift.thumbnailUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.gift.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          _imagePlaceholder(),
                                      errorWidget: (_, __, ___) =>
                                          _imagePlaceholder(),
                                    )
                                  : _imagePlaceholder()),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasNewImage
                            ? _newImageName ?? ''
                            : l10n.t('currentImageHint'),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        onPressed: (isActioning || _uploadingAnimation)
                            ? null
                            : _pickAnimation,
                        icon: _uploadingAnimation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.animation_rounded, size: 18),
                        label: Text(
                          _uploadingAnimation
                              ? l10n.tOr('uploading', 'Uploading…')
                              : showAnimation
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
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (showAnimation) ...[
                        const SizedBox(height: 12),
                        GiftAnimationPreview(
                          key: const ValueKey('edit-gift-animation-preview'),
                          bytes: _animationBytes,
                          networkUrl: _animationUrl,
                          fileName: _animationName ?? _animationUrl,
                          onClear: (isActioning || _uploadingAnimation)
                              ? null
                              : () => setState(() {
                                    _animationBytes = null;
                                    _animationUrl = null;
                                    _animationName = null;
                                    _clearAnimation = true;
                                    _animationError = null;
                                  }),
                        ),
                      ],

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
                        onChanged: isActioning
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _selectedSize = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),

                      GiftPriceCoinsField(
                        controller: _priceCtrl,
                        enabled: !isActioning,
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
                      const SizedBox(height: 14),

                      GiftPublishedAtPicker(
                        value: _publishedAt,
                        onTap: isActioning ? null : _pickPublishedAt,
                        onClear: _publishedAt != null
                            ? () => setState(() => _publishedAt = null)
                            : null,
                      ),

                      if (isActioning) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.t('savingChanges')),
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
                onPressed:
                    (isActioning || _uploadingAnimation) ? null : _submit,
                child: Text(l10n.t('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewDialog(BuildContext context) {
    final l10n = context.l10n;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final showAnimation = widget.gift.animationUrl != null &&
        widget.gift.animationUrl!.trim().isNotEmpty;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW < 560 ? 16 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('previewGift', 'Preview gift')),
      content: SizedBox(
        width: dialogW,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: widget.gift.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.gift.thumbnailUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => _imagePlaceholder(),
                          errorWidget: (context, url, error) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              if (showAnimation) ...[
                const SizedBox(height: 14),
                GiftAnimationPreview(
                  key: const ValueKey('preview-gift-animation-preview'),
                  networkUrl: widget.gift.animationUrl,
                  fileName: widget.gift.animationUrl,
                ),
              ],
              const SizedBox(height: 14),
              GiftPriceCoinsField(
                controller: _priceCtrl,
                enabled: false,
                validator: (_) => null,
              ),
              const SizedBox(height: 14),
              GiftPublishedAtPicker(
                value: _publishedAt,
                onTap: null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('close')),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.card_giftcard_rounded,
            size: 40, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
