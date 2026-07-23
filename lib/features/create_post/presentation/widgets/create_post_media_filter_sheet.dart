import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../../filters_effects/domain/entities/filters_effects_entities.dart';
import '../../../filters_effects/domain/usecases/filters_effects_usecases.dart';
import '../../../filters_effects/presentation/utils/fe_preview_color_utils.dart';
import '../../domain/entities/create_post_media_filter_entity.dart';
import '../../domain/entities/local_media_file.dart';
import '../../domain/services/create_post_media_filter_service.dart';
import '../bloc/create_post_bloc.dart';

Future<void> showCreatePostMediaFilterSheet({
  required BuildContext context,
  required LocalMediaFile file,
}) {
  final bloc = context.read<CreatePostBloc>();
  final width = MediaQuery.sizeOf(context).width;
  final isWide = width >= 720;

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 680),
            child: _CreatePostMediaFilterSheet(file: file),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (_, scrollController) => _CreatePostMediaFilterSheet(
            file: file,
            scrollController: scrollController,
          ),
        ),
      ),
    ),
  );
}

enum _CreatePostFilterPanel { library, custom }

class _CreatePostMediaFilterSheet extends StatefulWidget {
  const _CreatePostMediaFilterSheet({
    required this.file,
    this.scrollController,
  });

  final LocalMediaFile file;
  final ScrollController? scrollController;

  @override
  State<_CreatePostMediaFilterSheet> createState() =>
      _CreatePostMediaFilterSheetState();
}

class _CreatePostMediaFilterSheetState extends State<_CreatePostMediaFilterSheet> {
  static const _filterService = CreatePostMediaFilterService();

  late _CreatePostFilterPanel _panel;
  late CreatePostMediaFilterEntity _libraryFilter;
  late CreatePostMediaFilterEntity _customFilter;

  List<CameraFilterEntity> _catalogFilters = const [];
  bool _catalogLoading = true;
  String? _catalogError;

  CreatePostMediaFilterEntity get _activeFilter =>
      _panel == _CreatePostFilterPanel.library ? _libraryFilter : _customFilter;

  @override
  void initState() {
    super.initState();
    final existing = widget.file.filter;
    _libraryFilter = existing.usesCatalogFilter
        ? CreatePostMediaFilterEntity(
            catalogFilterId: existing.catalogFilterId,
            catalogFilterLabel: existing.catalogFilterLabel,
            catalogColorMatrix: existing.catalogColorMatrix,
          )
        : CreatePostMediaFilterEntity.neutral;
    _customFilter = existing.hasCustomAdjustments
        ? CreatePostMediaFilterEntity(
            brightness: existing.brightness,
            contrast: existing.contrast,
            saturation: existing.saturation,
            warmth: existing.warmth,
            exposure: existing.exposure,
            sharpen: existing.sharpen,
            blur: existing.blur,
          )
        : CreatePostMediaFilterEntity.neutral;
    _panel = existing.usesCatalogFilter
        ? _CreatePostFilterPanel.library
        : _CreatePostFilterPanel.custom;
    _loadCatalogFilters();
  }

  Future<void> _loadCatalogFilters() async {
    try {
      final page = await di.sl<GetCameraFiltersUseCase>()(
        const FiltersEffectsListQuery(
          page: 1,
          pageSize: 100,
          status: FiltersEffectsStatusFilter.active,
        ),
      );
      if (!mounted) return;
      setState(() {
        _catalogFilters = page.data
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _catalogLoading = false;
        _catalogError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = e.toString();
      });
    }
  }

  void _apply() {
    final bloc = context.read<CreatePostBloc>();
    final filter = _activeFilter;
    if (filter.isNeutral) {
      bloc.add(ResetMediaFilter(widget.file.id));
    } else {
      bloc.add(ApplyMediaFilter(mediaId: widget.file.id, filter: filter));
    }
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _libraryFilter = CreatePostMediaFilterEntity.neutral;
      _customFilter = CreatePostMediaFilterEntity.neutral;
    });
    context.read<CreatePostBloc>().add(ResetMediaFilter(widget.file.id));
    Navigator.of(context).pop();
  }

  void _selectCatalogFilter(CameraFilterEntity? filter) {
    setState(() {
      _panel = _CreatePostFilterPanel.library;
      if (filter == null || filter.isOriginal) {
        _libraryFilter = CreatePostMediaFilterEntity.neutral;
      } else {
        _libraryFilter = CreatePostMediaFilterEntity.neutral.withCatalogFilter(
          id: filter.id,
          label: filter.displayLabel,
          colorMatrix: CameraFilterRenderTypeApi.forAdminApi(filter.renderType) ==
                  CameraFilterRenderTypeApi.matrix
              ? filter.colorMatrix
              : null,
        );
      }
    });
  }

  Widget _buildMediaPreview({required bool compact}) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isImage = widget.file.mediaType == 'IMAGE';
    final bytes = widget.file.sourceBytes;

    Widget child;
    if (isImage) {
      child = Image.memory(bytes, fit: BoxFit.contain);
    } else {
      child = ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded, size: compact ? 40 : 56),
              const SizedBox(height: 8),
              Text(
                l10n.t('createPostMediaFilterVideoHint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    child = _filterService.buildFilteredPreview(
      child: child,
      filter: _activeFilter,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: compact
            ? AspectRatio(aspectRatio: 16 / 9, child: child)
            : child,
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: -1,
          max: 1,
          divisions: 40,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCustomControls() {
    final l10n = context.l10n;
    final isVideo = widget.file.mediaType == 'VIDEO';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _slider(
          label: l10n.t('createPostFilterBrightness'),
          value: _customFilter.brightness,
          onChanged: (v) =>
              setState(() => _customFilter = _customFilter.copyWith(brightness: v)),
        ),
        _slider(
          label: l10n.t('createPostFilterContrast'),
          value: _customFilter.contrast,
          onChanged: (v) =>
              setState(() => _customFilter = _customFilter.copyWith(contrast: v)),
        ),
        _slider(
          label: l10n.t('createPostFilterSaturation'),
          value: _customFilter.saturation,
          onChanged: (v) =>
              setState(() => _customFilter = _customFilter.copyWith(saturation: v)),
        ),
        _slider(
          label: l10n.t('createPostFilterWarmth'),
          value: _customFilter.warmth,
          onChanged: (v) =>
              setState(() => _customFilter = _customFilter.copyWith(warmth: v)),
        ),
        _slider(
          label: l10n.t('createPostFilterExposure'),
          value: _customFilter.exposure,
          onChanged: (v) =>
              setState(() => _customFilter = _customFilter.copyWith(exposure: v)),
        ),
        if (!isVideo) ...[
          _slider(
            label: l10n.t('createPostFilterSharpen'),
            value: _customFilter.sharpen,
            onChanged: (v) =>
                setState(() => _customFilter = _customFilter.copyWith(sharpen: v)),
          ),
          _slider(
            label: l10n.t('createPostFilterBlur'),
            value: _customFilter.blur,
            onChanged: (v) =>
                setState(() => _customFilter = _customFilter.copyWith(blur: v)),
          ),
        ],
      ],
    );
  }

  Widget _buildLibraryControls() {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (_catalogLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catalogError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t('createPostMediaFilterCatalogError'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _catalogLoading = true;
                  _catalogError = null;
                });
                _loadCatalogFilters();
              },
              child: Text(l10n.t('retry')),
            ),
          ],
        ),
      );
    }

    final bytes = widget.file.mediaType == 'IMAGE'
        ? widget.file.sourceBytes
        : null;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          l10n.t('createPostMediaFilterLibraryHint'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            _CatalogFilterChip(
              label: l10n.t('createPostMediaFilterNone'),
              selected: !_libraryFilter.usesCatalogFilter,
              previewBytes: bytes,
              onTap: () => _selectCatalogFilter(null),
            ),
            for (final filter in _catalogFilters)
              _CatalogFilterChip(
                label: filter.displayLabel,
                selected: _libraryFilter.catalogFilterId == filter.id,
                previewBytes: bytes,
                colorMatrix:
                    CameraFilterRenderTypeApi.forAdminApi(filter.renderType) ==
                            CameraFilterRenderTypeApi.matrix
                        ? filter.colorMatrix
                        : null,
                previewColorHex: filter.previewColorHex,
                onTap: () => _selectCatalogFilter(filter),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanelTabs() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SegmentedButton<_CreatePostFilterPanel>(
        segments: [
          ButtonSegment(
            value: _CreatePostFilterPanel.library,
            label: Text(l10n.t('createPostMediaFilterLibraryTab')),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          ),
          ButtonSegment(
            value: _CreatePostFilterPanel.custom,
            label: Text(l10n.t('createPostMediaFilterCustomTab')),
            icon: const Icon(Icons.tune_rounded, size: 18),
          ),
        ],
        selected: {_panel},
        onSelectionChanged: (selection) {
          setState(() => _panel = selection.first);
        },
      ),
    );
  }

  Widget _buildControlsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPanelTabs(),
        Expanded(
          child: _panel == _CreatePostFilterPanel.library
              ? _buildLibraryControls()
              : _buildCustomControls(),
        ),
      ],
    );
  }

  Widget _buildWideBody() {
    final l10n = context.l10n;
    final active = _activeFilter;

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.t('createPostMediaFilterControlsTitle'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(child: _buildControlsColumn()),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('createPostMediaFilterPreviewTitle'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildMediaPreview(compact: false)),
                  if (active.usesCatalogFilter &&
                      active.catalogFilterLabel != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      active.catalogFilterLabel!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowBody() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMediaPreview(compact: true),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildControlsColumn()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Text(
                l10n.t('createPostMediaFilterTitle'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        if (isWide) _buildWideBody() else _buildNarrowBody(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(l10n.t('createPostMediaFilterReset')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(l10n.t('createPostMediaFilterApply')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogFilterChip extends StatelessWidget {
  const _CatalogFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.previewBytes,
    this.colorMatrix,
    this.previewColorHex,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Uint8List? previewBytes;
  final List<double>? colorMatrix;
  final String? previewColorHex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const thumbSize = 72.0;

    Widget thumb;
    if (previewBytes != null) {
      thumb = Image.memory(previewBytes!, fit: BoxFit.cover);
      if (colorMatrix != null && colorMatrix!.length >= 20) {
        thumb = ColorFiltered(
          colorFilter: ColorFilter.matrix(colorMatrix!.take(20).toList()),
          child: thumb,
        );
      }
    } else {
      final gradient = previewGradientForHex(previewColorHex);
      thumb = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: const SizedBox.expand(),
      );
      if (colorMatrix != null && colorMatrix!.length >= 20) {
        thumb = ColorFiltered(
          colorFilter: ColorFilter.matrix(colorMatrix!.take(20).toList()),
          child: thumb,
        );
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: thumbSize,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: thumb,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to wrap filtered image bytes preview in list tiles.
Widget buildFilteredImagePreview({
  required Uint8List bytes,
  required CreatePostMediaFilterEntity filter,
  required BoxFit fit,
}) {
  const service = CreatePostMediaFilterService();
  return service.buildFilteredPreview(
    child: Image.memory(bytes, fit: fit),
    filter: filter,
  );
}
