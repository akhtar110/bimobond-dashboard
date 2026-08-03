import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
import '../utils/gift_publisher_name.dart';
import 'gift_animation_upload_section.dart';
import 'gift_audio_preview.dart';
import 'gift_color_picker_field.dart';
import 'gift_dialog_layout.dart';
import 'gift_price_coins_field.dart';
import 'gift_published_at_picker.dart';
import 'gift_thumbnail_image.dart';
import 'gift_type_selector.dart';

void showCreateGiftDialog(BuildContext pageContext) {
  pageContext.read<GiftsBloc>().add(ClearGiftImageEvent());
  showDialog<void>(
    context: pageContext,
    builder: (_) => CreateGiftDialog(pageContext: pageContext),
  );
}

class CreateGiftDialog extends StatefulWidget {
  const CreateGiftDialog({super.key, required this.pageContext});
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
        _publishedAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
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
              animationUrl:
                  _selectedType == GiftType.image ? _animationUrl : null,
              audioUrl: _selectedType == GiftType.audio ? _audioUrl : null,
              assignGroupId: _selectedGroupId,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasAnimation =
        (_animationBytes != null && _animationBytes!.isNotEmpty) ||
            (_animationUrl != null && _animationUrl!.trim().isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = GiftDialogLayout(constraints.biggest);
          final isWide = constraints.maxWidth >= 720;

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
                                        child: _buildMediaColumn(
                                          context: context,
                                          layout: layout,
                                          l10n: l10n,
                                          state: state,
                                          hasImage: hasImage,
                                          hasAnimation: hasAnimation,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Right Form Fields Column
                                      Expanded(
                                        flex: 6,
                                        child: _buildFieldsColumn(
                                          context: context,
                                          layout: layout,
                                          l10n: l10n,
                                          state: state,
                                          isWide: isWide,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildMediaColumn(
                                        context: context,
                                        layout: layout,
                                        l10n: l10n,
                                        state: state,
                                        hasImage: hasImage,
                                        hasAnimation: hasAnimation,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildFieldsColumn(
                                        context: context,
                                        layout: layout,
                                        l10n: l10n,
                                        state: state,
                                        isWide: isWide,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const Divider(height: 1, thickness: 1),

                        // --- Footer Action Bar ---
                        _buildFooter(context, l10n, state, canCreate),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Header Bar Widget
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
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('createNewGift'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.tOr(
                    'createGiftSubtitle',
                    'Configure media, coin price, tags, and publishing options',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

  // Left Column: Media & Type Configuration
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
                  l10n.tOr('giftImageHeader', 'Gift Image *'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: state.isActioning ? null : _pickImage,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: Text(
                  hasImage
                      ? l10n.t('changeImage')
                      : l10n.t('uploadImageRequired'),
                ),
                style: layout.denseOutlinedButtonStyle(),
              ),
            ],
          ),
          if (_imageError != null) ...[
            const SizedBox(height: 6),
            Text(
              _imageError!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ],
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
              // Avoid clipping platform views on web (native SVG <img>).
              clipBehavior: kIsWeb ? Clip.none : Clip.antiAlias,
              child: hasImage
                  ? GiftThumbnailImage(
                      key: ValueKey(
                        'create-gift-img-${state.pendingImageName}-'
                        '${state.pendingImageBytes?.length ?? 0}',
                      ),
                      bytes: state.pendingImageBytes,
                      fileName: state.pendingImageName,
                      fit: BoxFit.contain,
                      errorWidget: _errorPlaceholder(scheme),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t('uploadImageRequired'),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 6),
            Text(
              state.pendingImageName ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Animation Upload Card
    final animationTile = GiftAnimationUploadSection(
      layout: layout,
      hasAnimation: hasAnimation,
      uploading: _uploadingAnimation,
      animationBytes: _animationBytes,
      animationUrl: _animationUrl,
      animationName: _animationName ?? _animationUrl,
      animationError: _animationError,
      isActioning: state.isActioning,
      onPickAnimation: (state.isActioning || _uploadingAnimation)
          ? null
          : _pickAnimation,
      onClearAnimation: (state.isActioning || _uploadingAnimation)
          ? null
          : () => setState(() {
                _animationBytes = null;
                _animationUrl = null;
                _animationName = null;
                _animationError = null;
              }),
    );

    final hasAudio = (_audioBytes != null && _audioBytes!.isNotEmpty) ||
        (_audioUrl != null && _audioUrl!.trim().isNotEmpty);

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
                    (state.isActioning || _uploadingAudio) ? null : _pickAudio,
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
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift Type Segment Selector
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
        const SizedBox(height: 14),

        // Type specific Media Cards
        if (_selectedType == GiftType.image) ...[
          imageTile,
          const SizedBox(height: 12),
          animationTile,
        ] else ...[
          GiftColorPickerField(
            layout: layout,
            value: _selectedColor,
            enabled: !state.isActioning,
            onChanged: (value) => setState(() => _selectedColor = value),
          ),
          const SizedBox(height: 12),
          audioTile,
        ],
      ],
    );
  }

  Widget _errorPlaceholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
      ),
    );
  }

  // Right Column: Form Fields & Settings
  Widget _buildFieldsColumn({
    required BuildContext context,
    required GiftDialogLayout layout,
    required AppLocalizations l10n,
    required GiftsLoaded state,
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
          enabled: !state.isActioning,
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
                onChanged: state.isActioning
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
                      onChanged: state.isActioning
                          ? null
                          : (value) =>
                                setState(() => _selectedGroupId = value),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _tagCtrl,
                enabled: !state.isActioning,
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
                publisherName: resolveGiftPublisherName(context),
                onTap: state.isActioning ? null : _pickPublishedAt,
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
                enabled: !state.isActioning,
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
            onChanged: state.isActioning
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
    GiftsLoaded state,
    bool canCreate,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: scheme.surfaceContainerLowest,
      child: Row(
        children: [
          if (state.isActioning || _uploadingAnimation || _uploadingAudio) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.isActioning
                    ? l10n.t('uploadingCreatingGift')
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
            onPressed: canCreate ? () => _submit(state) : null,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(l10n.t('createGift')),
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
