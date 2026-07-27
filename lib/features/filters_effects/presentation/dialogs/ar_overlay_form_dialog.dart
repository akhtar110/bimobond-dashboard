import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/ar_overlay_entities.dart';
import '../bloc/ar_overlay_form_cubit.dart';
import 'ar_overlay_preview_dialog.dart';

Future<dynamic> openArOverlayFormDialog(
  BuildContext context, {
  ArOverlayEntity? overlay,
}) {
  return showDialog<dynamic>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => BlocProvider(
      create: (_) => ArOverlayFormCubit(dio: sl(), overlay: overlay),
      child: ArOverlayFormDialog(overlay: overlay),
    ),
  );
}

class ArOverlayFormDialog extends StatefulWidget {
  const ArOverlayFormDialog({super.key, this.overlay});

  final ArOverlayEntity? overlay;

  bool get isEdit => overlay != null;

  @override
  State<ArOverlayFormDialog> createState() => _ArOverlayFormDialogState();
}

class _ArOverlayFormDialogState extends State<ArOverlayFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _sortOrderCtrl;
  late final TextEditingController _lottieUrlCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _thumbnailUrlCtrl;
  late final TextEditingController _previewColorCtrl;

  bool _listenersAttached = false;

  @override
  void initState() {
    super.initState();
    final o = widget.overlay;
    _idCtrl = TextEditingController(text: o?.id ?? '');
    _labelCtrl = TextEditingController(text: o?.label ?? '');
    _sortOrderCtrl = TextEditingController(
      text: (o?.sortOrder ?? 0).toString(),
    );
    _lottieUrlCtrl = TextEditingController(text: o?.lottieUrl ?? '');
    _emojiCtrl = TextEditingController(text: o?.emoji ?? '');
    _thumbnailUrlCtrl = TextEditingController(text: o?.thumbnailUrl ?? '');
    _previewColorCtrl = TextEditingController(
      text: o?.previewColorHex ?? '#1E88E5',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenersAttached) return;
    _listenersAttached = true;

    final cubit = context.read<ArOverlayFormCubit>();
    _idCtrl.addListener(() => cubit.syncField(id: _idCtrl.text));
    _labelCtrl.addListener(() => cubit.syncField(label: _labelCtrl.text));
    _sortOrderCtrl.addListener(
      () => cubit.syncField(sortOrderText: _sortOrderCtrl.text),
    );
    _lottieUrlCtrl.addListener(
      () => cubit.syncField(lottieUrl: _lottieUrlCtrl.text),
    );
    _emojiCtrl.addListener(() => cubit.syncField(emoji: _emojiCtrl.text));
    _thumbnailUrlCtrl.addListener(
      () => cubit.syncField(thumbnailUrl: _thumbnailUrlCtrl.text),
    );
    _previewColorCtrl.addListener(
      () => cubit.syncField(previewColorHex: _previewColorCtrl.text),
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _labelCtrl.dispose();
    _sortOrderCtrl.dispose();
    _lottieUrlCtrl.dispose();
    _emojiCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _previewColorCtrl.dispose();
    super.dispose();
  }

  Color _parseColorHex(String input) {
    var clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(val) : const Color(0xFF1E88E5);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<ArOverlayFormCubit>();
    cubit.syncField(
      id: _idCtrl.text,
      label: _labelCtrl.text,
      sortOrderText: _sortOrderCtrl.text,
      lottieUrl: _lottieUrlCtrl.text,
      emoji: _emojiCtrl.text,
      thumbnailUrl: _thumbnailUrlCtrl.text,
      previewColorHex: _previewColorCtrl.text,
    );
    await cubit.submit();
  }

  Future<void> _openOverlayPreview(BuildContext context) async {
    final state = context.read<ArOverlayFormCubit>().state;
    if (!state.canPreviewOverlay) return;
    await openArOverlayPreviewDialog(
      context,
      overlay: state.draftOverlay,
      lottieBytes: state.lottieBytes,
      lottieFilename: state.lottieFilename,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return BlocListener<ArOverlayFormCubit, ArOverlayFormState>(
      listenWhen: (previous, current) =>
          previous.lottieUrl != current.lottieUrl ||
          previous.thumbnailUrl != current.thumbnailUrl ||
          previous.thumbnailSnackError != current.thumbnailSnackError ||
          previous.submitResult != current.submitResult,
      listener: (context, state) {
        if (_lottieUrlCtrl.text != state.lottieUrl) {
          _lottieUrlCtrl.text = state.lottieUrl;
        }
        if (_thumbnailUrlCtrl.text != state.thumbnailUrl) {
          _thumbnailUrlCtrl.text = state.thumbnailUrl;
        }

        if (state.thumbnailSnackError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.thumbnailSnackError!)),
          );
          context.read<ArOverlayFormCubit>().clearThumbnailSnackError();
        }

        if (state.submitResult != null) {
          Navigator.of(context).pop(state.submitResult);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 960 : 540,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isEdit
                            ? Icons.edit_rounded
                            : Icons.layers_outlined,
                        color: scheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit
                                ? l10n.tOr('editArOverlay', 'Edit AR Overlay')
                                : l10n.tOr(
                                    'createArOverlay',
                                    'Create AR Overlay',
                                  ),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.isEdit
                                ? l10n.tOr(
                                    'editArOverlaySub',
                                    'Modify AR overlay configuration',
                                  )
                                : l10n.tOr(
                                    'createArOverlaySub',
                                    'Add a new camera studio screen overlay',
                                  ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.t('cancel'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildFormFields(context),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildLivePreview(context),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLivePreview(context),
                              const SizedBox(height: 20),
                              _buildFormFields(context),
                            ],
                          ),
                  ),
                ),
              ),

              const Divider(height: 1),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.t('cancel')),
                    ),
                    const SizedBox(width: 12),
                    BlocSelector<ArOverlayFormCubit, ArOverlayFormState, bool>(
                      selector: (state) => state.isBusy,
                      builder: (context, isBusy) {
                        return FilledButton.icon(
                          onPressed: isBusy ? null : _onSubmit,
                          icon: Icon(
                            widget.isEdit
                                ? Icons.save_rounded
                                : Icons.check_rounded,
                            size: 18,
                          ),
                          label: Text(
                            widget.isEdit ? l10n.t('save') : l10n.t('create'),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocSelector<ArOverlayFormCubit, ArOverlayFormState, String?>(
          selector: (state) => state.businessRuleError,
          builder: (context, businessRuleError) {
            if (businessRuleError == null) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          businessRuleError,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Label & Sort Order
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _labelCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.tOr("label", "Label")} *',
                  hintText: 'e.g. Neon Frame',
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Label is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _sortOrderCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.tOr('sortOrder', 'Sort Order'),
                  hintText: '0',
                  prefixIcon: const Icon(Icons.sort_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final num = int.tryParse(val.trim());
                  if (num == null || num < 0) return 'Must be >= 0';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lottie URL & Attach JSON File
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _lottieUrlCtrl,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.tOr("lottieUrl", "Animation URL / File")} *',
                  hintText: 'https://... or attach .json / .mp4',
                  prefixIcon: const Icon(Icons.animation_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Animation URL or attached JSON/MP4 is required';
                  }
                  if (!ArOverlayFormCubit.isRemoteAssetUrl(val)) {
                    return 'Must be an uploaded http(s) or /uploads URL';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            BlocSelector<ArOverlayFormCubit, ArOverlayFormState, bool>(
              selector: (state) => state.isUploadingLottie,
              builder: (context, isUploadingLottie) {
                return ElevatedButton.icon(
                  onPressed: isUploadingLottie
                      ? null
                      : context.read<ArOverlayFormCubit>().attachOverlayAsset,
                  icon: isUploadingLottie
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_rounded, size: 18),
                  label: Text(
                    isUploadingLottie
                        ? 'Uploading...'
                        : l10n.tOr('attachJsonMp4', 'Attach JSON / MP4'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Emoji & Thumbnail URL & Attach Image
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _emojiCtrl,
                decoration: InputDecoration(
                  labelText: l10n.tOr('emoji', 'Emoji'),
                  hintText: '✨',
                  prefixIcon: const Icon(
                    Icons.emoji_emotions_outlined,
                    size: 20,
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _thumbnailUrlCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.tOr(
                          'thumbnailUrl',
                          'Thumbnail URL / Image',
                        ),
                        hintText: 'https://... or attach image',
                        prefixIcon: const Icon(Icons.image_outlined, size: 20),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        if (!ArOverlayFormCubit.isRemoteAssetUrl(trimmed)) {
                          return 'Must be an uploaded http(s) or /uploads URL';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocSelector<ArOverlayFormCubit, ArOverlayFormState, bool>(
                    selector: (state) => state.isUploadingThumbnail,
                    builder: (context, isUploadingThumbnail) {
                      return OutlinedButton.icon(
                        onPressed: isUploadingThumbnail
                            ? null
                            : context
                                  .read<ArOverlayFormCubit>()
                                  .attachThumbnailImage,
                        icon: isUploadingThumbnail
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.image_search_rounded, size: 18),
                        label: Text(
                          isUploadingThumbnail
                              ? 'Uploading...'
                              : l10n.tOr('attachImage', 'Attach Image'),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview Color Hex
        TextFormField(
          controller: _previewColorCtrl,
          decoration: InputDecoration(
            labelText: l10n.tOr('previewColorHex', 'Preview Color (#RRGGBB)'),
            hintText: '#1E88E5',
            prefixIcon: BlocSelector<ArOverlayFormCubit, ArOverlayFormState,
                String>(
              selector: (state) => state.previewColorHex,
              builder: (context, previewColorHex) {
                return Container(
                  margin: const EdgeInsets.all(12),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _parseColorHex(previewColorHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                );
              },
            ),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return null;
            final clean = val.trim().replaceAll('#', '');
            if (clean.length != 6 || int.tryParse(clean, radix: 16) == null) {
              return 'Must match #RRGGBB format';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLivePreview(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<
      ArOverlayFormCubit,
      ArOverlayFormState,
      ({
        String id,
        String label,
        String emoji,
        String thumbnailUrl,
        String previewColorHex,
        bool canPreviewOverlay,
      })
    >(
      selector: (state) {
        final id = state.id.trim().isEmpty ? 'overlay_id' : state.id.trim();
        final label = state.label.trim().isEmpty
            ? 'Overlay Name'
            : state.label.trim();
        return (
          id: id,
          label: label,
          emoji: state.emoji.trim(),
          thumbnailUrl: state.thumbnailUrl.trim(),
          previewColorHex: state.previewColorHex,
          canPreviewOverlay: state.canPreviewOverlay,
        );
      },
      builder: (context, preview) {
        final color = _parseColorHex(preview.previewColorHex);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live Preview',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card Preview
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thumbnail area
                    Container(
                      height: 130,
                      color: color.withValues(alpha: 0.85),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildThumbnailImage(
                            preview.thumbnailUrl,
                            preview.emoji,
                            color,
                          ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.animation_rounded,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LOTTIE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Info Area
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview.label,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${preview.id}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: preview.canPreviewOverlay
                    ? () => _openOverlayPreview(context)
                    : null,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: Text(
                  l10n.tOr('previewOverlay', 'Preview overlay'),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackPreviewContent(String emoji, Color color) {
    if (emoji.isNotEmpty) {
      return Text(emoji, style: const TextStyle(fontSize: 42));
    }
    return Icon(
      Icons.layers_outlined,
      size: 40,
      color: Colors.white.withValues(alpha: 0.9),
    );
  }

  Widget _buildThumbnailImage(String url, String emoji, Color color) {
    if (url.isEmpty) return _fallbackPreviewContent(emoji, color);
    if (url.startsWith('data:')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _fallbackPreviewContent(emoji, color),
        );
      } catch (_) {
        return _fallbackPreviewContent(emoji, color);
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, __, ___) => _fallbackPreviewContent(emoji, color),
    );
  }
}
