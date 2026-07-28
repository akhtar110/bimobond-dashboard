import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../../domain/usecases/gift_group_usecases.dart';
import '../bloc/gift_groups_bloc.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gift_animation_bytes.dart';
import '../utils/gift_image_picker.dart';
import 'gift_animation_upload_section.dart';
import 'gift_audio_preview.dart';
import 'gift_color_picker_field.dart';
import 'gift_dialog_layout.dart';
import 'gift_preview_dialog.dart';
import 'gift_price_coins_field.dart';
import 'gift_published_at_picker.dart';
import 'gift_type_selector.dart';

void showEditGiftDialog(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => EditGiftDialog(pageContext: pageContext, gift: gift),
  );
}

void showPreviewGiftDialog(BuildContext pageContext, GiftEntity gift) {
  showDialog<void>(
    context: pageContext,
    builder: (_) => GiftPreviewDialog(pageContext: pageContext, gift: gift),
  );
}

class EditGiftDialog extends StatefulWidget {
  const EditGiftDialog({
    super.key,
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
  late final TextEditingController _tagCtrl;
  late final TextEditingController _sortOrderCtrl;
  final _formKey = GlobalKey<FormState>();

  Uint8List? _newImageBytes;
  String? _newImageName;
  String? _animationUrl;
  String? _animationName;
  Uint8List? _animationBytes;
  bool _clearAnimation = false;
  bool _uploadingAnimation = false;
  String? _animationError;
  String? _audioUrl;
  String? _audioName;
  Uint8List? _audioBytes;
  bool _clearAudio = false;
  bool _uploadingAudio = false;
  String? _audioError;
  DateTime? _publishedAt;
  late GiftSize _selectedSize;
  late GiftType _selectedType;
  String? _selectedColor;
  late bool _isActive;
  String? _selectedGroupId;
  String? _initialGroupId;
  bool _loadingGroups = false;
  List<GiftGroupEntity> _groups = const [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.gift.name);
    _priceCtrl = TextEditingController(
      text: widget.gift.priceCoins.toStringAsFixed(
        widget.gift.priceCoins.truncateToDouble() == widget.gift.priceCoins
            ? 0
            : 2,
      ),
    );
    _tagCtrl = TextEditingController(text: widget.gift.tag ?? '');
    _sortOrderCtrl = TextEditingController(
      text: widget.gift.sortOrder.toString(),
    );
    _publishedAt = widget.gift.publishedAt;
    _selectedSize = widget.gift.size;
    _selectedType = widget.gift.type;
    _selectedColor = widget.gift.color;
    _isActive = widget.gift.isActive;
    _animationUrl = widget.gift.animationUrl;
    _animationName = widget.gift.animationUrl;
    _audioUrl = widget.gift.audioUrl;
    _audioName = widget.gift.audioUrl;
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
    _tagCtrl.dispose();
    _sortOrderCtrl.dispose();
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

  Future<void> _pickAudio() async {
    final picked = await pickGiftAudio();
    if (!mounted || picked == null) return;

    setState(() {
      _audioBytes = picked.bytes;
      _audioName = picked.name;
      _audioUrl = null;
      _uploadingAudio = true;
      _audioError = null;
      _clearAudio = false;
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

  String? _normalizedTag() {
    final raw = _tagCtrl.text.trim();
    if (raw.isEmpty) return null;
    return raw.length <= 50 ? raw : raw.substring(0, 50);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadingAnimation || _uploadingAudio) return;
    if (_selectedType == GiftType.audio &&
        !_clearAudio &&
        (_audioUrl == null || _audioUrl!.trim().isEmpty)) {
      setState(() {
        _audioError = context.l10n.tOr(
          'giftAudioRequired',
          'Audio file is required for audio gifts',
        );
      });
      return;
    }

    final originalAnimationUrl = widget.gift.animationUrl;
    String? animationUrl;
    var clearAnimationUrl = false;
    if (_clearAnimation || _selectedType == GiftType.audio) {
      clearAnimationUrl = originalAnimationUrl != null;
    } else if (_animationUrl != null &&
        _animationUrl!.trim().isNotEmpty &&
        _animationUrl != originalAnimationUrl) {
      animationUrl = _animationUrl;
    }

    final originalAudioUrl = widget.gift.audioUrl;
    String? audioUrl;
    var clearAudioUrl = false;
    if (_clearAudio || _selectedType == GiftType.image) {
      clearAudioUrl = originalAudioUrl != null;
    } else if (_audioUrl != null &&
        _audioUrl!.trim().isNotEmpty &&
        _audioUrl != originalAudioUrl) {
      audioUrl = _audioUrl;
    }

    final tagValue = _normalizedTag();
    final colorValue = _selectedType == GiftType.audio ? _selectedColor : null;

    widget.pageContext.read<GiftsBloc>().add(
          UpdateGiftEvent(
            widget.gift.id,
            UpdateGiftData(
              name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
              priceCoins: double.tryParse(_priceCtrl.text.trim()),
              size: _selectedSize,
              type: _selectedType,
              tag: tagValue,
              clearTag: tagValue == null && widget.gift.tag != null,
              color: colorValue,
              clearColor: _selectedType == GiftType.image
                  ? widget.gift.color != null
                  : (colorValue == null && widget.gift.color != null),
              sortOrder: int.tryParse(_sortOrderCtrl.text.trim()),
              isActive: _isActive,
              publishedAt: _publishedAt,
              clearPublishedAt:
                  widget.gift.publishedAt != null && _publishedAt == null,
              imageBytes:
                  _selectedType == GiftType.image ? _newImageBytes : null,
              imageName:
                  _selectedType == GiftType.image ? _newImageName : null,
              animationUrl: animationUrl,
              clearAnimationUrl: clearAnimationUrl,
              audioUrl: audioUrl,
              clearAudioUrl: clearAudioUrl,
              assignGroupId: _selectedGroupId,
              previousAssignGroupId: _initialGroupId,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.previewOnly) {
      return GiftPreviewDialog(
        pageContext: widget.pageContext,
        gift: widget.gift,
      );
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasNewImage = _newImageBytes != null;
    final showAnimation = !_clearAnimation &&
        ((_animationBytes != null && _animationBytes!.isNotEmpty) ||
            (_animationUrl != null && _animationUrl!.trim().isNotEmpty));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = GiftDialogLayout(constraints.biggest);
          final isWide = constraints.maxWidth >= 720;

          return BlocListener<GiftsBloc, GiftsState>(
            bloc: widget.pageContext.read<GiftsBloc>(),
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

                return Container(
                  width: layout.dialogWidth,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- Header Bar ---
                          _buildHeader(context, l10n),

                          const Divider(height: 1, thickness: 1),

                          // --- Scrollable Body ---
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Left Media Column
                                        Expanded(
                                          flex: 5,
                                          child: _buildEditMediaColumn(
                                            context: context,
                                            layout: layout,
                                            l10n: l10n,
                                            isActioning: isActioning,
                                            hasNewImage: hasNewImage,
                                            showAnimation: showAnimation,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // Right Form Fields Column
                                        Expanded(
                                          flex: 6,
                                          child: _buildEditFieldsColumn(
                                            context: context,
                                            layout: layout,
                                            l10n: l10n,
                                            isActioning: isActioning,
                                            isWide: isWide,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildEditMediaColumn(
                                          context: context,
                                          layout: layout,
                                          l10n: l10n,
                                          isActioning: isActioning,
                                          hasNewImage: hasNewImage,
                                          showAnimation: showAnimation,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildEditFieldsColumn(
                                          context: context,
                                          layout: layout,
                                          l10n: l10n,
                                          isActioning: isActioning,
                                          isWide: isWide,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const Divider(height: 1, thickness: 1),

                          // --- Footer Action Bar ---
                          _buildFooter(context, l10n, isActioning),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.secondary, scheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('editGift'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Left Column: Media & Type Selection
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

    // Image Upload Card
    final imageTile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.image_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tOr('giftImageHeader', 'Gift Image'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isActioning ? null : _pickImage,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: Text(
                  hasNewImage
                      ? l10n.t('changeImage')
                      : l10n.t('uploadNewImage'),
                ),
                style: layout.denseOutlinedButtonStyle(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasNewImage
                  ? Image.memory(
                      _newImageBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : (widget.gift.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.gift.thumbnailUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => _imagePlaceholder(),
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder()),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasNewImage ? _newImageName ?? '' : l10n.t('currentImageHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    // Animation Upload Card
    final animationTile = GiftAnimationUploadSection(
      layout: layout,
      hasAnimation: showAnimation,
      uploading: _uploadingAnimation,
      animationBytes: _animationBytes,
      animationUrl: _animationUrl,
      animationName: _animationName ?? _animationUrl,
      animationError: _animationError,
      isActioning: isActioning,
      onPickAnimation: (isActioning || _uploadingAnimation)
          ? null
          : _pickAnimation,
      onClearAnimation: (isActioning || _uploadingAnimation)
          ? null
          : () => setState(() {
                _animationBytes = null;
                _animationUrl = null;
                _animationName = null;
                _clearAnimation = true;
                _animationError = null;
              }),
    );

    final hasAudio = !_clearAudio &&
        ((_audioBytes != null && _audioBytes!.isNotEmpty) ||
            (_audioUrl != null && _audioUrl!.trim().isNotEmpty));

    // Audio Upload Card
    final audioTile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack_rounded, size: 18, color: scheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tOr('giftAudioHeader', 'Audio File *'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    (isActioning || _uploadingAudio) ? null : _pickAudio,
                icon: _uploadingAudio
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined, size: 16),
                label: Text(
                  _uploadingAudio
                      ? l10n.tOr('uploading', 'Uploading…')
                      : hasAudio
                          ? l10n.tOr('changeAudio', 'Change')
                          : l10n.tOr('uploadAudioRequired', 'Upload'),
                ),
                style: layout.denseOutlinedButtonStyle(),
              ),
            ],
          ),
          if (_audioError != null) ...[
            const SizedBox(height: 6),
            Text(
              _audioError!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ],
          if (hasAudio) ...[
            const SizedBox(height: 10),
            GiftAudioPreview(
              key: ValueKey('edit-audio-${_audioUrl ?? _audioName}'),
              networkUrl: _audioUrl,
              bytes: _audioBytes,
              fileName: _audioName ?? _audioUrl,
              onClear: (isActioning || _uploadingAudio)
                  ? null
                  : () => setState(() {
                        _audioBytes = null;
                        _audioUrl = null;
                        _audioName = null;
                        _clearAudio = true;
                        _audioError = null;
                      }),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift Type Selector
        GiftTypeSelector(
          value: _selectedType,
          enabled: !isActioning,
          onChanged: (value) => setState(() {
            _selectedType = value;
            if (value == GiftType.audio) {
              _newImageBytes = null;
              _newImageName = null;
            }
          }),
        ),
        const SizedBox(height: 14),

        if (_selectedType == GiftType.image) ...[
          imageTile,
          const SizedBox(height: 12),
          animationTile,
        ] else ...[
          GiftColorPickerField(
            layout: layout,
            value: _selectedColor,
            enabled: !isActioning,
            onChanged: (value) => setState(() => _selectedColor = value),
          ),
          const SizedBox(height: 12),
          audioTile,
        ],
      ],
    );
  }

  Widget _imagePlaceholder() {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // Right Column: Form Fields
  Widget _buildEditFieldsColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required bool isActioning,
    required bool isWide,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.tOr('giftInfoSection', 'GIFT DETAILS')),
        const SizedBox(height: 10),

        // Gift Name
        TextFormField(
          controller: _nameCtrl,
          enabled: !isActioning,
          decoration: layout.denseDecoration(
            labelText: l10n.t('giftNameLabel'),
            prefixIcon: const Icon(Icons.card_giftcard_rounded, size: 18),
          ),
          validator: (v) =>
              v?.trim().isEmpty == true ? l10n.t('requiredField') : null,
        ),
        const SizedBox(height: 10),

        // Price & Size Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
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
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<GiftSize>(
                value: _selectedSize,
                isDense: true,
                decoration: layout.denseDecoration(
                  labelText: l10n.tOr('giftSizeLabel', 'Size'),
                  prefixIcon: const Icon(Icons.aspect_ratio_rounded, size: 18),
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
          ],
        ),
        const SizedBox(height: 10),

        // Group Tab & Tag Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        labelText: l10n.tOr('giftGroupName', 'Tab Name'),
                        prefixIcon: const Icon(Icons.folder_outlined, size: 18),
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
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _tagCtrl,
                enabled: !isActioning,
                maxLength: 50,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
                decoration: layout.denseDecoration(
                  labelText: l10n.tOr('giftTag', 'Tag'),
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionHeader(
            title: l10n.tOr('giftPublishSection', 'PUBLISHING & STATUS')),
        const SizedBox(height: 10),

        // Published At & Sort Order Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: GiftPublishedAtPicker(
                value: _publishedAt,
                onTap: isActioning ? null : _pickPublishedAt,
                onClear: _publishedAt != null
                    ? () => setState(() => _publishedAt = null)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _sortOrderCtrl,
                enabled: !isActioning,
                keyboardType: TextInputType.number,
                decoration: layout.denseDecoration(
                  labelText: l10n.tOr('giftSortOrder', 'Sort Order'),
                  prefixIcon:
                      const Icon(Icons.format_list_numbered_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Active Status Switch Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: SwitchListTile.adaptive(
            value: _isActive,
            onChanged: isActioning
                ? null
                : (value) => setState(() => _isActive = value),
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              l10n.tOr('activeLabel', 'Active Status'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              _isActive
                  ? l10n.tOr('giftActiveHint', 'Visible to users in store')
                  : l10n.tOr('giftInactiveHint', 'Hidden from users'),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  // Footer Actions Widget
  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n,
    bool isActioning,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: scheme.surfaceContainerLowest,
      child: Row(
        children: [
          if (isActioning || _uploadingAnimation || _uploadingAudio) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isActioning
                    ? l10n.t('savingChanges')
                    : l10n.tOr('uploadingFile', 'Uploading file…'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ] else
            const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.t('cancel')),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: (isActioning || _uploadingAnimation || _uploadingAudio)
                ? null
                : _submit,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.t('save')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header Helper
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            height: 1,
            color: scheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
