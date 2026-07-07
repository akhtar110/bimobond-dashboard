import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/utils/location_coordinate_utils.dart';
import '../../domain/entities/create_post_location_entity.dart';
import '../utils/create_post_geolocation.dart';
import 'create_post_location_map_picker.dart';

Future<void> showCreatePostLocationPicker({
  required BuildContext context,
  required CreatePostLocationEntity? initial,
  required ValueChanged<CreatePostLocationEntity> onSelect,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.88,
        child: _CreatePostLocationPickerSheet(
          initial: initial,
          onSelect: (location) {
            onSelect(location);
            Navigator.of(ctx).pop();
          },
          onClear: () {
            onClear();
            Navigator.of(ctx).pop();
          },
        ),
      ),
    ),
  );
}

class _CreatePostLocationPickerSheet extends StatefulWidget {
  const _CreatePostLocationPickerSheet({
    required this.onSelect,
    required this.onClear,
    this.initial,
  });

  final CreatePostLocationEntity? initial;
  final ValueChanged<CreatePostLocationEntity> onSelect;
  final VoidCallback onClear;

  @override
  State<_CreatePostLocationPickerSheet> createState() =>
      _CreatePostLocationPickerSheetState();
}

class _CreatePostLocationPickerSheetState
    extends State<_CreatePostLocationPickerSheet> {
  static const _geolocation = CreatePostGeolocation();

  late LatLng _mapCenter;
  LatLng? _selected;
  late final TextEditingController _nameController;
  late final bool _hasSavedInitial;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _hasSavedInitial = initial != null &&
        initial.isComplete &&
        (initial.latitude != 0 || initial.longitude != 0);

    if (_hasSavedInitial) {
      _selected = LatLng(initial!.latitude, initial.longitude);
      _mapCenter = _selected!;
      _nameController = TextEditingController(text: initial.name);
    } else {
      _mapCenter = LocationCoordinateHelper.defaultCenter;
      _nameController = TextEditingController();
      _locating = true;
      unawaited(_loadCurrentLocationAsPin());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocationAsPin() async {
    try {
      final result = await _geolocation
          .getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      final point = result.hasRealPosition
          ? result.point
          : LocationCoordinateHelper.defaultCenter;

      setState(() {
        _locating = false;
        _selected = point;
        _mapCenter = point;
        _syncNameFromPoint(point);
      });

      if (!result.hasRealPosition && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t(
                result.permissionDenied
                    ? 'createPostLocationPermissionDenied'
                    : result.serviceDisabled
                        ? 'createPostLocationServiceDisabled'
                        : 'createPostLocationGpsUnavailable',
              ),
            ),
          ),
        );
      }
    } on Object {
      if (!mounted) return;
      final fallback = LocationCoordinateHelper.defaultCenter;
      setState(() {
        _locating = false;
        _selected = fallback;
        _mapCenter = fallback;
        _syncNameFromPoint(fallback);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final result = await _geolocation
          .getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (!result.hasRealPosition) {
        setState(() => _locating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t(
                result.permissionDenied
                    ? 'createPostLocationPermissionDenied'
                    : 'createPostLocationServiceDisabled',
              ),
            ),
          ),
        );
        return;
      }

      setState(() {
        _locating = false;
        _selected = result.point;
        _mapCenter = result.point;
        _syncNameFromPoint(result.point);
      });
    } on Object {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _syncNameFromPoint(LatLng point) {
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = _defaultName(point);
    }
  }

  String _defaultName(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, '
        '${point.longitude.toStringAsFixed(5)}';
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selected = point;
      _mapCenter = point;
      _nameController.text = _defaultName(point);
    });
  }

  void _confirm() {
    final point = _selected;
    if (point == null) return;

    final name = _nameController.text.trim();
    final location = CreatePostLocationEntity(
      name: name.isEmpty ? _defaultName(point) : name,
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!location.isComplete) return;
    widget.onSelect(location);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canConfirm = _selected != null && !_locating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  l10n.t('createPostLocationPickerTitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.initial != null)
                TextButton(
                  onPressed: widget.onClear,
                  child: Text(l10n.t('remove')),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            l10n.t('createPostLocationMapHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CreatePostLocationMapPicker(
              selectedPoint: _selected,
              initialCenter: _mapCenter,
              isLocating: _locating,
              onPointChanged: _onMapTap,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.t('createPostLocationName'),
              hintText: l10n.t('createPostLocationNameHint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${_selected!.latitude.toStringAsFixed(5)}, '
              '${_selected!.longitude.toStringAsFixed(5)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(l10n.t('createPostLocationUseCurrent')),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(l10n.t('createPostLocationSave')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
