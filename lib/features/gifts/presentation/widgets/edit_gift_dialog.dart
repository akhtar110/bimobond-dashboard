import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_image_picker.dart';
import 'gift_published_at_picker.dart';

void showEditGiftDialog(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => EditGiftDialog(pageContext: pageContext, gift: gift),
  );
}

class EditGiftDialog extends StatefulWidget {
  const EditGiftDialog({required this.pageContext, required this.gift});

  final BuildContext pageContext;
  final GiftEntity gift;

  @override
  State<EditGiftDialog> createState() => EditGiftDialogState();
}

class EditGiftDialogState extends State<EditGiftDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();

  Uint8List? _newImageBytes;
  String? _newImageName;
  DateTime? _publishedAt;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.gift.name);
    _priceCtrl = TextEditingController(
        text: widget.gift.priceCoins.toStringAsFixed(2));
    _publishedAt = widget.gift.publishedAt;
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
    Navigator.pop(context);
    widget.pageContext.read<GiftsBloc>().add(UpdateGiftEvent(
          widget.gift.id,
          UpdateGiftData(
            name: _nameCtrl.text.trim().isEmpty
                ? null
                : _nameCtrl.text.trim(),
            priceCoins: double.tryParse(_priceCtrl.text.trim()),
            publishedAt: _publishedAt,
            imageBytes: _newImageBytes,
            imageName: _newImageName,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = screenW < 560 ? screenW * 0.92 : 480.0;
    final hasNewImage = _newImageBytes != null;

    return BlocListener<GiftsBloc, GiftsState>(
      bloc: widget.pageContext.read<GiftsBloc>(),
      listenWhen: (p, c) =>
          c is GiftsLoaded &&
          (p is! GiftsLoaded || p.isActioning != c.isActioning),
      listener: (_, state) {
        if (state is GiftsLoaded && !state.isActioning) {
          if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
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
            content: SizedBox(
              width: dialogW,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // â”€â”€ Gift Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                      // â”€â”€ Image section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                      // Preview: new bytes OR existing URL
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

                      // â”€â”€ Price â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.t('giftPriceLabel'),
                          prefixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

                      // â”€â”€ Published At â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      GiftPublishedAtPicker(
                        value: _publishedAt,
                        onTap: isActioning ? null : _pickPublishedAt,
                        onClear: _publishedAt != null
                            ? () => setState(() => _publishedAt = null)
                            : null,
                      ),

                      // â”€â”€ Uploading indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                onPressed: isActioning ? null : _submit,
                child: Text(l10n.t('save')),
              ),
            ],
          );
        },
      ),
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
