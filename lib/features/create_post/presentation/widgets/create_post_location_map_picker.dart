import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../promotions/presentation/utils/location_coordinate_utils.dart';
import '../../../promotions/presentation/utils/location_map_tiles.dart';
import '../utils/create_post_geolocation.dart';

class CreatePostLocationMapPicker extends StatefulWidget {
  const CreatePostLocationMapPicker({
    super.key,
    required this.selectedPoint,
    required this.onPointChanged,
    this.initialCenter,
    this.isLocating = false,
  });

  final LatLng? selectedPoint;
  final ValueChanged<LatLng> onPointChanged;
  final LatLng? initialCenter;
  final bool isLocating;

  @override
  State<CreatePostLocationMapPicker> createState() =>
      _CreatePostLocationMapPickerState();
}

class _CreatePostLocationMapPickerState extends State<CreatePostLocationMapPicker> {
  late final MapController _mapController;
  bool _mapReady = false;
  LatLng? _lastFocused;

  LatLng? get _focusPoint => widget.selectedPoint ?? widget.initialCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CreatePostLocationMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = _focusPoint;
    if (focus != null && !latLngsEqual(focus, _lastFocused)) {
      _centerOn(focus, zoom: widget.selectedPoint != null ? 15 : 14);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    final focus = _focusPoint;
    if (focus != null) {
      _centerOn(focus, zoom: widget.selectedPoint != null ? 15 : 14);
    }
  }

  void _centerOn(LatLng point, {required double zoom}) {
    _lastFocused = point;
    if (!_mapReady || !mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerOn(point, zoom: zoom);
      });
      return;
    }
    try {
      _mapController.move(point, zoom);
    } on Object {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerOn(point, zoom: zoom);
      });
    }
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(3.0, LocationMapTiles.maxZoom);
    _mapController.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final center = _focusPoint ?? LocationCoordinateHelper.defaultCenter;
    final tileUrl =
        LocationMapTiles.urlTemplateFor(Theme.of(context).brightness);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.selectedPoint != null ? 15 : 14,
              minZoom: 3,
              maxZoom: LocationMapTiles.maxZoom,
              onMapReady: _onMapReady,
              backgroundColor: scheme.surfaceContainerHighest,
              onTap: (_, point) => widget.onPointChanged(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                maxNativeZoom: LocationMapTiles.maxNativeZoom,
                maxZoom: LocationMapTiles.maxZoom,
                userAgentPackageName: LocationMapTiles.userAgentPackageName,
                retinaMode: false,
              ),
              if (widget.selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.selectedPoint!,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.location_pin,
                        color: scheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              SimpleAttributionWidget(
                alignment: Alignment.bottomRight,
                backgroundColor: scheme.surface.withValues(alpha: 0.88),
                source: Text(
                  LocationMapTiles.attributionLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 10,
            top: 10,
            child: _MapZoomControls(
              onZoomIn: () => _zoomBy(1),
              onZoomOut: () => _zoomBy(-1),
            ),
          ),
          if (widget.isLocating)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.35),
                  child: Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
          const Divider(height: 1),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
