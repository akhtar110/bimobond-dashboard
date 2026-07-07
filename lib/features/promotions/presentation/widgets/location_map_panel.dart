import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/promotion_entities.dart';
import '../utils/location_coordinate_utils.dart';
import '../utils/location_map_tiles.dart';

const _kBoundsPadding = 50.0;

/// A user pinned at a specific location on the overview map.
class LocationUserMapMarker {
  const LocationUserMapMarker({
    required this.user,
    required this.point,
    this.isLatest = false,
  });

  final UserEntity user;
  final LocationPointEntity point;
  final bool isLatest;
}

class LocationMapPanel extends StatefulWidget {
  const LocationMapPanel({
    super.key,
    required this.points,
    this.polylinePoints,
    this.height,
    this.showMovementPath = false,
    this.selectedUser,
    this.userMarkers,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage,
    this.minZoom = 3,
    this.showZoomControls = false,
  });

  final List<LocationPointEntity> points;
  final List<LocationPointEntity>? polylinePoints;
  final double? height;
  final bool showMovementPath;
  final UserEntity? selectedUser;
  final List<LocationUserMapMarker>? userMarkers;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? emptyMessage;
  final double minZoom;
  final bool showZoomControls;

  @override
  State<LocationMapPanel> createState() => _LocationMapPanelState();
}

class _LocationMapPanelState extends State<LocationMapPanel> {
  late final MapController _mapController;
  bool _mapReady = false;
  List<Marker>? _cachedMarkers;
  Polyline? _cachedPolyline;
  String? _cachedMarkersInputKey;
  String? _cachedPolylinePointsKey;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (kDebugMode) {
      debugPrint('Map points count: ${widget.points.length}');
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapDataChanged(oldWidget)) return;
    if (kDebugMode) {
      debugPrint('Map points count: ${widget.points.length}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  bool _mapDataChanged(LocationMapPanel oldWidget) {
    return !_samePointIds(oldWidget.points, widget.points) ||
        !_samePointIds(
          oldWidget.polylinePoints ?? const [],
          widget.polylinePoints ?? const [],
        ) ||
        oldWidget.showMovementPath != widget.showMovementPath ||
        oldWidget.selectedUser?.id != widget.selectedUser?.id ||
        _userMarkersCacheKey(oldWidget.userMarkers) !=
            _userMarkersCacheKey(widget.userMarkers);
  }

  bool _samePointIds(
    List<LocationPointEntity> a,
    List<LocationPointEntity> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  List<LocationPointEntity> get _validPoints => widget.points
      .where(
        (p) => LocationCoordinateHelper.isPlottable(
          p,
          countryHint: widget.selectedUser?.country,
        ),
      )
      .toList();

  LatLng _toLatLng(LocationPointEntity point, {String? countryHint}) {
    final country = point.country ?? countryHint ?? widget.selectedUser?.country;
    final resolved = LocationCoordinateHelper.resolve(
      point.latitude,
      point.longitude,
      country,
    );
    if (kDebugMode &&
        (resolved.lat != point.latitude || resolved.lng != point.longitude)) {
      debugPrint(
        'Map coord normalized: '
        '(${point.latitude}, ${point.longitude}) -> '
        '(${resolved.lat}, ${resolved.lng}) '
        'country=${country ?? 'unknown'}',
      );
    }
    return LatLng(resolved.lat, resolved.lng);
  }

  bool _canControlMap() {
    if (!_mapReady || !mounted) return false;
    try {
      final _ = _mapController.camera.center;
      return true;
    } on Object {
      return false;
    }
  }

  List<LatLng> _fitLatLngs() {
    if (!widget.showMovementPath &&
        widget.userMarkers != null &&
        widget.userMarkers!.isNotEmpty) {
      return [
        for (final marker in widget.userMarkers!)
          if (LocationCoordinateHelper.isPlottable(
            marker.point,
            countryHint: marker.user.country,
          ))
            _toLatLng(marker.point, countryHint: marker.user.country),
      ];
    }
    return _validPoints.map(_toLatLng).toList();
  }

  void _fitCamera({int attempt = 0}) {
    if (!mounted || !_canControlMap()) {
      if (attempt < 8) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fitCamera(attempt: attempt + 1),
        );
      }
      return;
    }
    final latLngs = _fitLatLngs();
    if (latLngs.isEmpty) return;

    try {
      if (latLngs.length == 1) {
        _mapController.move(latLngs.first, 11);
        return;
      }

      final first = latLngs.first;
      final allSame = latLngs.every(
        (point) =>
            point.latitude == first.latitude && point.longitude == first.longitude,
      );
      if (allSame) {
        _mapController.move(first, 11);
        return;
      }

      final bounds = LatLngBounds.fromPoints(latLngs);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(_kBoundsPadding),
        ),
      );
    } on Object {
      if (attempt < 8) {
        final delayMs = 60 + (attempt * 40);
        Future<void>.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) _fitCamera(attempt: attempt + 1);
        });
      }
    }
  }

  void _onMapReady() {
    _mapReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _fitCamera();
    });
  }

  void _zoomBy(double delta) {
    if (!_canControlMap()) return;
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(
      widget.minZoom,
      LocationMapTiles.maxZoom,
    );
    _mapController.move(camera.center, nextZoom);
  }

  String _userMarkersCacheKey([List<LocationUserMapMarker>? markers]) {
    final source = markers ?? widget.userMarkers;
    if (source == null || source.isEmpty) return '';
    return source.map((m) => '${m.user.id}:${m.point.id}').join('|');
  }

  String _markersInputKey() {
    return [
      widget.showMovementPath,
      widget.selectedUser?.id ?? '',
      widget.points.map((p) => p.id).join('|'),
      (widget.polylinePoints ?? const <LocationPointEntity>[])
          .map((p) => p.id)
          .join('|'),
      _userMarkersCacheKey(),
    ].join('::');
  }

  List<Marker> _buildMarkers(ColorScheme scheme) {
    final inputKey = _markersInputKey();
    if (_cachedMarkersInputKey == inputKey && _cachedMarkers != null) {
      return _cachedMarkers!;
    }

    final valid = _validPoints;
    final hasOverviewMarkers = !widget.showMovementPath &&
        widget.userMarkers != null &&
        widget.userMarkers!.isNotEmpty;
    if (valid.isEmpty && !hasOverviewMarkers) {
      _cachedMarkersInputKey = inputKey;
      _cachedMarkers = const [];
      return _cachedMarkers!;
    }

    final user = widget.selectedUser;
    if (widget.showMovementPath && user != null) {
      _cachedMarkers = [
        for (var i = 0; i < valid.length; i++)
          _userLocationMarker(
            user: user,
            point: valid[i],
            index: i,
            total: valid.length,
            scheme: scheme,
          ),
      ];
    } else if (!widget.showMovementPath &&
        widget.userMarkers != null &&
        widget.userMarkers!.isNotEmpty) {
      _cachedMarkers = [
        for (final marker in widget.userMarkers!)
          if (LocationCoordinateHelper.isPlottable(
            marker.point,
            countryHint: marker.user.country,
          ))
            _overviewUserMarker(
              user: marker.user,
              point: marker.point,
              scheme: scheme,
              isLatest: marker.isLatest,
            ),
      ];
    } else if (widget.showMovementPath && valid.length > 1) {
      _cachedMarkers = [
        for (var i = 0; i < valid.length; i++)
          _movementMarker(
            point: valid[i],
            index: i,
            total: valid.length,
            scheme: scheme,
          ),
      ];
    } else {
      _cachedMarkers = valid
          .map(
            (point) => Marker(
              key: ValueKey('point-${point.id}'),
              point: _toLatLng(point),
              width: 44,
              height: 44,
              child: Tooltip(
                message: _markerLabel(point),
                child: Icon(
                  Icons.location_pin,
                  color: _sourceColor(point.source, scheme),
                  size: 32,
                ),
              ),
            ),
          )
          .toList();
    }

    _cachedMarkersInputKey = inputKey;
    return _cachedMarkers!;
  }

  Marker _overviewUserMarker({
    required UserEntity user,
    required LocationPointEntity point,
    required ColorScheme scheme,
    bool isLatest = false,
  }) {
    const size = 40.0;
    return Marker(
      key: ValueKey('user-${user.id}-${point.id}'),
      point: _toLatLng(point, countryHint: user.country),
      width: size + 8,
      height: size + 8,
      child: Tooltip(
        message: _userMarkerTooltip(user, point, isLatest: isLatest),
        child: KeyedSubtree(
          key: ValueKey('avatar-${user.id}-${point.id}'),
          child: _UserLocationMarkerAvatar(
            user: user,
            size: size,
            isLatest: isLatest,
            isOldest: false,
            scheme: scheme,
          ),
        ),
      ),
    );
  }

  Marker _userLocationMarker({
    required UserEntity user,
    required LocationPointEntity point,
    required int index,
    required int total,
    required ColorScheme scheme,
  }) {
    final isLatest = index == 0;
    final isOldest = index == total - 1;
    final size = isLatest ? 44.0 : (total > 20 ? 24.0 : 30.0);

    return Marker(
      key: ValueKey('trail-${user.id}-${point.id}'),
      point: _toLatLng(point, countryHint: user.country),
      width: size + 8,
      height: size + 8,
      child: Tooltip(
        message: _userMarkerTooltip(user, point, isLatest: isLatest),
        child: KeyedSubtree(
          key: ValueKey('avatar-${user.id}-${point.id}'),
          child: _UserLocationMarkerAvatar(
            user: user,
            size: size,
            isLatest: isLatest,
            isOldest: isOldest,
            scheme: scheme,
          ),
        ),
      ),
    );
  }

  String _userMarkerTooltip(
    UserEntity user,
    LocationPointEntity point, {
    required bool isLatest,
  }) {
    final location = _markerLabel(point);
    final name = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : '@${user.username}';
    if (isLatest) return '$name · Latest · $location';
    return '$name · $location';
  }

  Marker _movementMarker({
    required LocationPointEntity point,
    required int index,
    required int total,
    required ColorScheme scheme,
  }) {
    final isStart = index == 0;
    final isEnd = index == total - 1;
    final latLng = _toLatLng(point);

    if (isStart) {
      return Marker(
        key: ValueKey('movement-start-${point.id}'),
        point: latLng,
        width: 28,
        height: 28,
        child: Tooltip(
          message: _markerLabel(point),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      );
    }

    if (isEnd) {
      return Marker(
        key: ValueKey('movement-end-${point.id}'),
        point: latLng,
        width: 44,
        height: 44,
        child: Tooltip(
          message: _markerLabel(point),
          child: Icon(
            Icons.location_pin,
            color: scheme.error,
            size: 34,
          ),
        ),
      );
    }

    return Marker(
      key: ValueKey('movement-mid-${point.id}'),
      point: latLng,
      width: 16,
      height: 16,
      child: Tooltip(
        message: _markerLabel(point),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 1.5),
          ),
        ),
      ),
    );
  }

  Polyline? _buildPolyline(ColorScheme scheme) {
    if (!widget.showMovementPath) return null;

    final polylineKey = (widget.polylinePoints ?? widget.points)
        .map((p) => p.id)
        .join('|');
    if (_cachedPolylinePointsKey == polylineKey && _cachedPolyline != null) {
      return _cachedPolyline;
    }

    final pathPoints = (widget.polylinePoints ?? widget.points)
        .where(
          (p) => LocationCoordinateHelper.isPlottable(
            p,
            countryHint: widget.selectedUser?.country,
          ),
        )
        .toList();
    if (pathPoints.length < 2) {
      _cachedPolylinePointsKey = polylineKey;
      _cachedPolyline = null;
      return null;
    }

    _cachedPolylinePointsKey = polylineKey;
    _cachedPolyline = Polyline(
      points: pathPoints.map(_toLatLng).toList(),
      strokeWidth: 4,
      color: scheme.primary.withValues(alpha: 0.75),
    );
    return _cachedPolyline;
  }

  String _markerLabel(LocationPointEntity point) {
    final parts = <String>[
      if (point.city?.isNotEmpty == true) point.city!,
      if (point.country?.isNotEmpty == true) point.country!,
    ];
    if (parts.isEmpty) return 'Unknown';
    return parts.join(', ');
  }

  Color _sourceColor(String? source, ColorScheme scheme) {
    return switch (source) {
      'APP_OPEN' => scheme.primary,
      'FEED' => scheme.secondary,
      'MANUAL' => scheme.tertiary,
      'BACKGROUND' => scheme.error,
      _ => scheme.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final emptyMessage =
        widget.emptyMessage ?? l10n.t('promoNoLocationData');

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHeight = widget.height ??
            (constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 320.0);

        return SizedBox(
          height: resolvedHeight,
          width: constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildBody(context, scheme, emptyMessage),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme scheme,
    String emptyMessage,
  ) {
    if (widget.isLoading) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.errorMessage != null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: scheme.error,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: widget.onRetry,
                    child: Text(context.l10n.t('retry')),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final valid = _validPoints;
    final hasOverviewMarkers = !widget.showMovementPath &&
        widget.userMarkers != null &&
        widget.userMarkers!.isNotEmpty;
    if (valid.isEmpty && !hasOverviewMarkers) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final fitPoints = _fitLatLngs();
    final markers = _buildMarkers(scheme);
    final polyline = _buildPolyline(scheme);
    final initialCenter = fitPoints.isNotEmpty
        ? fitPoints.first
        : LocationCoordinateHelper.defaultCenter;
    final initialZoom = fitPoints.length == 1 ? 11.0 : 2.0;
    final tileUrl =
        LocationMapTiles.urlTemplateFor(Theme.of(context).brightness);

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: widget.minZoom,
            maxZoom: LocationMapTiles.maxZoom,
            onMapReady: _onMapReady,
            backgroundColor: scheme.surfaceContainerHighest,
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
              panBuffer: 2,
            ),
            if (polyline != null)
              PolylineLayer(polylines: [polyline]),
            MarkerLayer(markers: markers),
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
          right: 12,
          top: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '${fitPoints.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
        if (widget.showZoomControls)
          Positioned(
            right: 12,
            bottom: 12,
            child: _MapZoomControls(
              scheme: scheme,
              onZoomIn: () => _zoomBy(1),
              onZoomOut: () => _zoomBy(-1),
              onFitAll: _fitCamera,
            ),
          ),
        if (widget.showMovementPath && widget.selectedUser != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: _UserTrailLegend(
              user: widget.selectedUser!,
              scheme: scheme,
            ),
          )
        else if (widget.showMovementPath)
          Positioned(
            left: 12,
            bottom: 12,
            child: _MovementLegend(scheme: scheme),
          ),
      ],
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.scheme,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitAll,
  });

  final ColorScheme scheme;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Zoom out',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Fit all locations',
            visualDensity: VisualDensity.compact,
            onPressed: onFitAll,
            icon: const Icon(Icons.fit_screen_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _UserLocationMarkerAvatar extends StatelessWidget {
  const _UserLocationMarkerAvatar({
    required this.user,
    required this.size,
    required this.isLatest,
    required this.isOldest,
    required this.scheme,
  });

  final UserEntity user;
  final double size;
  final bool isLatest;
  final bool isOldest;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveMediaUrl(user.avatarUrl);
    final borderColor = isLatest
        ? scheme.primary
        : isOldest
            ? scheme.secondary
            : scheme.outlineVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isLatest ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => _initialsFallback(),
                errorWidget: (_, _, _) => _initialsFallback(),
              )
            : _initialsFallback(),
      ),
    );
  }

  Widget _initialsFallback() {
    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

class _UserTrailLegend extends StatelessWidget {
  const _UserTrailLegend({
    required this.user,
    required this.scheme,
  });

  final UserEntity user;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : '@${user.username}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserLocationMarkerAvatar(
              user: user,
              size: 28,
              isLatest: true,
              isOldest: false,
              scheme: scheme,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'Latest location',
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementLegend extends StatelessWidget {
  const _MovementLegend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendRow(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              label: 'Start',
            ),
            const SizedBox(height: 4),
            _legendRow(
              child: Icon(Icons.location_pin, size: 14, color: scheme.error),
              label: 'End',
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow({required Widget child, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
