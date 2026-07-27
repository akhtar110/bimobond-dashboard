import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../bloc/gift_groups_bloc.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_image_picker.dart';
import 'gift_animation_preview.dart';
import 'gift_dialog_layout.dart';
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
  String? _selectedGroupId;
  String? _initialGroupId;
  bool _loadingGroups = false;
  List<GiftGroupEntity> _groups = const [];

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
    if (!widget.previewOnly) {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    final blocState = widget.pageContext.read<GiftGroupsBloc>().state;
    if (blocState is GiftGroupsLoaded) {
      if (!mounted) return;
      _applyGroups(blocState.groups);
      return;
    }
    if (mounted) setState(() => _loadingGroups = true);
    try {
      final groups = await di.sl<GetGiftGroupsUseCase>()();
      if (!mounted) return;
      _applyGroups(groups);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
    }
  }

  void _applyGroups(List<GiftGroupEntity> groups) {
    String? currentGroupId;
    for (final group in groups) {
      if (group.gifts.any((m) => m.gift.id == widget.gift.id)) {
        currentGroupId = group.id;
        break;
      }
    }
    setState(() {
      _groups = groups;
      _initialGroupId = currentGroupId;
      _selectedGroupId = currentGroupId;
      _loadingGroups = false;
    });
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
            assignGroupId: _selectedGroupId,
            previousAssignGroupId: _initialGroupId,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewOnly) {
      return _buildPreviewDialog(context);
    }

    final l10n = context.l10n;
    final layout = GiftDialogLayout(MediaQuery.sizeOf(context));
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
          final isActioning = state is GiftsLoaded && state.isActioning;

          final mediaColumn = _buildEditMediaColumn(
            context: context,
            layout: layout,
            l10n: l10n,
            isActioning: isActioning,
            hasNewImage: hasNewImage,
            showAnimation: showAnimation,
          );
          final fieldsColumn = _buildEditFieldsColumn(
            context: context,
            layout: layout,
            l10n: l10n,
            isActioning: isActioning,
          );

          return AlertDialog(
            insetPadding: layout.insetPadding,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.t('editGift')),
            content: SizedBox(
              width: layout.dialogWidth,
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: layout.maxBodyHeight),
                  child: SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

  Widget _buildEditMediaColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required bool isActioning,
    required bool hasNewImage,
    required bool showAnimation,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final imageTile = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isActioning ? null : _pickImage,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            hasNewImage ? l10n.t('changeImage') : l10n.t('uploadNewImage'),
          ),
          style: layout.denseOutlinedButtonStyle(),
        ),
        SizedBox(height: layout.fieldGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: layout.mediaAspectRatio,
            child: hasNewImage
                ? Image.memory(
                    _newImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  )
                : (widget.gift.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.gift.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _imagePlaceholder(),
                        errorWidget: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasNewImage ? _newImageName ?? '' : l10n.t('currentImageHint'),
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final animationTile = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed:
              (isActioning || _uploadingAnimation) ? null : _pickAnimation,
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
                : showAnimation
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
        if (showAnimation)
          GiftAnimationPreview(
            key: const ValueKey('edit-gift-animation-preview'),
            compact: true,
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
          )
        else if (layout.useWideLayout)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: layout.mediaAspectRatio,
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
          ),
      ],
    );

    if (layout.useWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: imageTile),
          SizedBox(width: layout.fieldGap),
          Expanded(child: animationTile),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        imageTile,
        SizedBox(height: layout.fieldGap),
        animationTile,
      ],
    );
  }

  Widget _buildEditFieldsColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required bool isActioning,
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
                onChanged: isActioning
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
                      onChanged: isActioning
                          ? null
                          : (value) =>
                              setState(() => _selectedGroupId = value),
                    ),
            ),
          ],
        ),
        SizedBox(height: layout.fieldGap),
        if (layout.useWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GiftPriceCoinsField(
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
              ),
              SizedBox(width: layout.fieldGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: GiftPublishedAtPicker(
                    value: _publishedAt,
                    onTap: isActioning ? null : _pickPublishedAt,
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
            enabled: !isActioning,
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
            onTap: isActioning ? null : _pickPublishedAt,
            onClear: _publishedAt != null
                ? () => setState(() => _publishedAt = null)
                : null,
          ),
        ],
        if (isActioning) ...[
          SizedBox(height: layout.fieldGap),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.t('savingChanges'))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewDialog(BuildContext context) {
    final l10n = context.l10n;
    final layout = GiftDialogLayout(MediaQuery.sizeOf(context));
    final theme = Theme.of(context);
    final showAnimation = widget.gift.animationUrl != null &&
        widget.gift.animationUrl!.trim().isNotEmpty;

    final imageTile = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: layout.mediaAspectRatio,
        child: widget.gift.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.gift.thumbnailUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => _imagePlaceholder(),
                errorWidget: (context, url, error) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );

    final animationTile = showAnimation
        ? AspectRatio(
            aspectRatio: layout.mediaAspectRatio,
            child: GiftAnimationPreview(
              key: const ValueKey('preview-gift-animation-preview'),
              compact: true,
              expandToFill: true,
              networkUrl: widget.gift.animationUrl,
              fileName: widget.gift.animationUrl,
            ),
          )
        : null;

    final mediaColumn = layout.useWideLayout && animationTile != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: imageTile),
              SizedBox(width: layout.fieldGap),
              Expanded(child: animationTile),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              imageTile,
              if (animationTile != null) ...[
                SizedBox(height: layout.fieldGap),
                animationTile,
              ],
            ],
          );

    final detailsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.gift.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: layout.fieldGap),
        _PreviewMetaChip(
          label: l10n.tOr('giftSizeLabel', 'Size'),
          value: widget.gift.size.apiValue,
        ),
        SizedBox(height: layout.fieldGap),
        GiftPriceCoinsField(
          controller: _priceCtrl,
          enabled: false,
          validator: (_) => null,
        ),
        SizedBox(height: layout.fieldGap),
        GiftPublishedAtPicker(
          value: _publishedAt,
          onTap: null,
        ),
      ],
    );

    return AlertDialog(
      insetPadding: layout.insetPadding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.tOr('previewGift', 'Preview gift')),
      content: SizedBox(
        width: layout.dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: layout.maxBodyHeight),
          child: SingleChildScrollView(
            primary: false,
            child: layout.useWideLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: mediaColumn),
                      SizedBox(width: layout.gap),
                      Expanded(flex: 5, child: detailsColumn),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      mediaColumn,
                      SizedBox(height: layout.gap),
                      detailsColumn,
                    ],
                  ),
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

class _PreviewMetaChip extends StatelessWidget {
  const _PreviewMetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
