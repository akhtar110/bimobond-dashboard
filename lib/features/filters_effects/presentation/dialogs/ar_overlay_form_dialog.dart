import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart';
import '../../data/models/ar_overlay_models.dart';
import '../../domain/entities/ar_overlay_entities.dart';
import '../utils/ar_overlay_picker.dart';

Future<dynamic> openArOverlayFormDialog(
  BuildContext context, {
  ArOverlayEntity? overlay,
}) {
  return showDialog<dynamic>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ArOverlayFormDialog(overlay: overlay),
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

  bool _isUploadingLottie = false;
  bool _isUploadingThumbnail = false;

  Uint8List? _lottieBytes;
  String? _lottieFilename;
  Uint8List? _thumbnailBytes;
  String? _thumbnailFilename;

  String? _businessRuleError;

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

    // Trigger state rebuild for live preview updates.
    _idCtrl.addListener(_updateState);
    _labelCtrl.addListener(_updateState);
    _sortOrderCtrl.addListener(_updateState);
    _lottieUrlCtrl.addListener(_updateState);
    _emojiCtrl.addListener(_updateState);
    _thumbnailUrlCtrl.addListener(_updateState);
    _previewColorCtrl.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) {
      setState(() => _businessRuleError = null);
    }
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

  /// True for any uploaded CDN/path URL (rejects embedded base64 / raw JSON).
  static bool _isRemoteAssetUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('data:')) return false;
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return false;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('/uploads/') ||
        lower.contains('/uploads/') ||
        lower.startsWith('uploads/');
  }

  static String _normalizeUploadFilename(String filename, {required bool json}) {
    final cleaned = filename.trim().isEmpty ? (json ? 'overlay.json' : 'file.bin') : filename.trim();
    if (json && !cleaned.toLowerCase().endsWith('.json')) {
      return '$cleaned.json';
    }
    return cleaned;
  }

  static String? _parseUploadUrlEntry(dynamic entry) {
    if (entry is String && entry.trim().isNotEmpty) {
      final value = entry.trim();
      if (value.startsWith('data:') ||
          value.startsWith('{') ||
          value.startsWith('[')) {
        return null;
      }
      return value;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      for (final key in ['url', 'path', 'location', 'fileUrl', 'src']) {
        final parsed = _parseUploadUrlEntry(map[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _extractUrlFromResponse(dynamic data) {
    if (data == null) return null;

    if (data is String && data.trim().isNotEmpty) {
      return _parseUploadUrlEntry(data);
    }

    if (data is List && data.isNotEmpty) {
      for (final item in data) {
        final parsed = _parseUploadUrlEntry(item);
        if (parsed != null) return parsed;
      }
      return null;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // Prefer urls[] (same contract as gifts / create-post upload).
      final topUrls = map['urls'];
      if (topUrls is List && topUrls.isNotEmpty) {
        for (final item in topUrls) {
          final parsed = _parseUploadUrlEntry(item);
          if (parsed != null) return parsed;
        }
      }

      final nested = map['data'];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final nestedUrls = nestedMap['urls'];
        if (nestedUrls is List && nestedUrls.isNotEmpty) {
          for (final item in nestedUrls) {
            final parsed = _parseUploadUrlEntry(item);
            if (parsed != null) return parsed;
          }
        }
        final nestedFiles = nestedMap['files'];
        if (nestedFiles is List && nestedFiles.isNotEmpty) {
          for (final item in nestedFiles) {
            final parsed = _parseUploadUrlEntry(item);
            if (parsed != null) return parsed;
          }
        }
        final fromNested = _extractUrlFromResponse(nestedMap);
        if (fromNested != null) return fromNested;
      } else if (nested is List && nested.isNotEmpty) {
        final fromNested = _extractUrlFromResponse(nested);
        if (fromNested != null) return fromNested;
      } else if (nested is String) {
        final parsed = _parseUploadUrlEntry(nested);
        if (parsed != null) return parsed;
      }

      final files = map['files'];
      if (files is List && files.isNotEmpty) {
        for (final item in files) {
          final parsed = _parseUploadUrlEntry(item);
          if (parsed != null) return parsed;
        }
      }

      return _parseUploadUrlEntry(
        map['url'] ?? map['path'] ?? map['location'] ?? map['fileUrl'],
      );
    }

    return null;
  }

  static bool _looksLikeJsonAsset(String filename, Uint8List bytes) {
    final lower = filename.trim().toLowerCase();
    if (lower.endsWith('.json') ||
        lower.endsWith('.lottie') ||
        lower.contains('.json')) {
      return true;
    }
    for (var i = 0; i < bytes.length && i < 64; i++) {
      final b = bytes[i];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) continue;
      return b == 0x7B || b == 0x5B;
    }
    return false;
  }

  /// Hosts a picked file on CDN via `POST /posts/upload`.
  ///
  /// Overlay create/update (`POST|PATCH /camera-studio/ar-overlays/admin`) only
  /// accepts a `lottieUrl` string — there is no overlay upload endpoint.
  /// `/posts/upload` rejects raw `.json`, so Lottie JSON is sent with a video
  /// MIME wrapper while the file body stays JSON.
  Future<String> _uploadFile(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw Exception('Selected file is empty');
    }

    final isJson = _looksLikeJsonAsset(filename, bytes);
    final originalName = _normalizeUploadFilename(filename, json: isJson);
    final uploadName = isJson
        ? _jsonUploadMediaFilename(originalName)
        : originalName;

    if (kDebugMode) {
      debugPrint(
        '[ArOverlayFormDialog] Uploading ${isJson ? 'Lottie JSON' : 'image'} '
        '$originalName as $uploadName (${bytes.length} bytes) → /posts/upload',
      );
    }

    final dio = sl<Dio>();
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'files',
        MultipartFile.fromBytes(
          bytes,
          filename: uploadName,
          contentType: isJson ? DioMediaType('video', 'mp4') : null,
        ),
      ),
    );

    final response = await dio.post<dynamic>(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    if (kDebugMode) {
      debugPrint('[ArOverlayFormDialog] Upload response: ${response.data}');
    }

    final extracted = _extractUrlFromResponse(response.data);
    if (extracted == null || extracted.isEmpty) {
      throw Exception(
        'Upload succeeded but no CDN URL was returned: ${response.data}',
      );
    }

    final resolved = resolveMediaUrl(extracted) ?? extracted;
    if (!_isRemoteAssetUrl(resolved)) {
      throw Exception('Upload returned an invalid URL: $resolved');
    }
    if (kDebugMode) {
      debugPrint('[ArOverlayFormDialog] CDN URL for payload: $resolved');
    }
    return resolved;
  }

  static String _jsonUploadMediaFilename(String originalName) {
    final base = originalName
        .trim()
        .replaceAll(RegExp(r'\.(json|lottie)$', caseSensitive: false), '');
    final safe = base.isEmpty
        ? 'overlay-lottie'
        : base.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return '$safe.mp4';
  }

  Future<void> _attachLottieJson() async {
    final res = await pickArOverlayJsonFile();
    if (res == null || !mounted) return;

    if (!_looksLikeJsonAsset(res.name, res.bytes)) {
      setState(() {
        _businessRuleError =
            'Only a Lottie JSON (.json) file is accepted for overlays.';
      });
      return;
    }

    setState(() {
      _isUploadingLottie = true;
      _businessRuleError = null;
      _lottieBytes = res.bytes;
      _lottieFilename = res.name;
    });

    try {
      final uploadedUrl = await _uploadFile(
        res.bytes,
        _normalizeUploadFilename(res.name, json: true),
      );
      if (!mounted) return;
      setState(() {
        _isUploadingLottie = false;
        _lottieUrlCtrl.text = uploadedUrl;
        // Bytes already on CDN — payload uses URL only.
        _lottieBytes = null;
        _lottieFilename = null;
        _businessRuleError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingLottie = false;
        _lottieBytes = null;
        _lottieFilename = null;
        _businessRuleError =
            'Failed to upload Lottie JSON: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _attachThumbnailImage() async {
    final res = await pickArOverlayImageFile();
    if (res == null || !mounted) return;

    setState(() {
      _isUploadingThumbnail = true;
      _businessRuleError = null;
      _thumbnailBytes = res.bytes;
      _thumbnailFilename = res.name;
    });

    try {
      final uploadedUrl = await _uploadFile(res.bytes, res.name);
      if (!mounted) return;
      setState(() {
        _isUploadingThumbnail = false;
        _thumbnailUrlCtrl.text = uploadedUrl;
        _thumbnailBytes = null;
        _thumbnailFilename = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingThumbnail = false;
        _thumbnailBytes = null;
        _thumbnailFilename = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload thumbnail: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _onSubmit() async {
    setState(() => _businessRuleError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingLottie || _isUploadingThumbnail) return;

    final label = _labelCtrl.text.trim();
    final generatedId = label.isNotEmpty
        ? label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        : 'overlay_${DateTime.now().millisecondsSinceEpoch}';
    final id = widget.isEdit
        ? widget.overlay!.id
        : (_idCtrl.text.trim().isNotEmpty ? _idCtrl.text.trim() : generatedId);
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
    var lottieUrl = _lottieUrlCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim();
    var thumbnailUrl = _thumbnailUrlCtrl.text.trim();
    final previewColorHex = _previewColorCtrl.text.trim();

    // Upload any pending local bytes so the payload only ever contains CDN URLs.
    try {
      if (!_isRemoteAssetUrl(lottieUrl)) {
        if (_lottieBytes == null || _lottieBytes!.isEmpty) {
          setState(() {
            _businessRuleError =
                'Lottie JSON must be uploaded to a CDN URL. Attach a .json file or paste an http(s) /uploads URL.';
          });
          return;
        }
        setState(() => _isUploadingLottie = true);
        final uploaded = await _uploadFile(
          _lottieBytes!,
          _lottieFilename ?? 'overlay.json',
        );
        if (!mounted) return;
        setState(() => _isUploadingLottie = false);
        lottieUrl = uploaded;
        _lottieUrlCtrl.text = uploaded;
        _lottieBytes = null;
      }

      if (thumbnailUrl.isNotEmpty && !_isRemoteAssetUrl(thumbnailUrl)) {
        if (_thumbnailBytes == null || _thumbnailBytes!.isEmpty) {
          setState(() {
            _businessRuleError =
                'Thumbnail must be a CDN URL. Attach an image or clear the field.';
          });
          return;
        }
        setState(() => _isUploadingThumbnail = true);
        final uploaded = await _uploadFile(
          _thumbnailBytes!,
          _thumbnailFilename ?? 'thumbnail.png',
        );
        if (!mounted) return;
        setState(() => _isUploadingThumbnail = false);
        thumbnailUrl = uploaded;
        _thumbnailUrlCtrl.text = uploaded;
        _thumbnailBytes = null;
      } else if (thumbnailUrl.isEmpty &&
          _thumbnailBytes != null &&
          _thumbnailBytes!.isNotEmpty) {
        setState(() => _isUploadingThumbnail = true);
        final uploaded = await _uploadFile(
          _thumbnailBytes!,
          _thumbnailFilename ?? 'thumbnail.png',
        );
        if (!mounted) return;
        setState(() => _isUploadingThumbnail = false);
        thumbnailUrl = uploaded;
        _thumbnailUrlCtrl.text = uploaded;
        _thumbnailBytes = null;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingLottie = false;
        _isUploadingThumbnail = false;
        _businessRuleError =
            e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    // Business Rule Validation:
    // Each overlay MUST have lottieUrl, and at least one of emoji or thumbnailUrl.
    if (emoji.isEmpty && thumbnailUrl.isEmpty) {
      setState(() {
        _businessRuleError =
            'Business Rule Error: At least one of Emoji or Thumbnail URL/Image must be provided.';
      });
      return;
    }

    if (widget.isEdit) {
      Navigator.of(context).pop(
        UpdateArOverlayData(
          label: label,
          sortOrder: sortOrder,
          lottieUrl: lottieUrl,
          emoji: emoji,
          thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
          previewColorHex: previewColorHex,
        ),
      );
    } else {
      Navigator.of(context).pop(
        CreateArOverlayData(
          id: id,
          label: label,
          sortOrder: sortOrder,
          lottieUrl: lottieUrl,
          emoji: emoji.isEmpty ? null : emoji,
          thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
          previewColorHex: previewColorHex.isEmpty ? null : previewColorHex,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Dialog(
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
                            Expanded(flex: 3, child: _buildFormFields(context)),
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
                  FilledButton.icon(
                    onPressed: (_isUploadingLottie || _isUploadingThumbnail)
                        ? null
                        : _onSubmit,
                    icon: Icon(
                      widget.isEdit ? Icons.save_rounded : Icons.check_rounded,
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
                  ),
                ],
              ),
            ),
          ],
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
        if (_businessRuleError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
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
                    _businessRuleError!,
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
                      '${l10n.tOr("lottieUrl", "Lottie URL / JSON File")} *',
                  hintText: 'https://... or attach .json file',
                  prefixIcon: const Icon(Icons.animation_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lottie URL or attached JSON is required';
                  }
                  if (!_isRemoteAssetUrl(val)) {
                    return 'Must be an uploaded http(s) or /uploads URL';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isUploadingLottie ? null : _attachLottieJson,
              icon: _isUploadingLottie
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.note_add_outlined, size: 18),
              label: Text(
                _isUploadingLottie
                    ? 'Uploading...'
                    : l10n.tOr('attachJson', 'Attach JSON'),
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
                        if (!_isRemoteAssetUrl(trimmed)) {
                          return 'Must be an uploaded http(s) or /uploads URL';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _isUploadingThumbnail ? null : _attachThumbnailImage,
                    icon: _isUploadingThumbnail
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_search_rounded, size: 18),
                    label: Text(
                      _isUploadingThumbnail
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
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _parseColorHex(_previewColorCtrl.text),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final id = _idCtrl.text.trim().isEmpty ? 'overlay_id' : _idCtrl.text.trim();
    final label = _labelCtrl.text.trim().isEmpty
        ? 'Overlay Name'
        : _labelCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim();
    final thumbnailUrl = _thumbnailUrlCtrl.text.trim();
    final color = _parseColorHex(_previewColorCtrl.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: scheme.primary),
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
                      _buildThumbnailImage(thumbnailUrl, emoji, color),

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
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $id',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
      ),
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
