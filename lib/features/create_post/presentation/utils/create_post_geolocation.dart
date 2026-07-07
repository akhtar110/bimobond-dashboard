import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../promotions/presentation/utils/location_coordinate_utils.dart';

class CreatePostGeolocationResult {
  const CreatePostGeolocationResult({
    required this.point,
    this.permissionDenied = false,
    this.serviceDisabled = false,
    this.usedFallback = false,
  });

  final LatLng point;
  final bool permissionDenied;
  final bool serviceDisabled;
  final bool usedFallback;

  bool get hasRealPosition => !permissionDenied && !serviceDisabled && !usedFallback;
}

/// Reads the device GPS position for create-post location picking.
class CreatePostGeolocation {
  const CreatePostGeolocation();

  Future<CreatePostGeolocationResult> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return CreatePostGeolocationResult(
        point: LocationCoordinateHelper.defaultCenter,
        serviceDisabled: true,
        usedFallback: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return CreatePostGeolocationResult(
        point: LocationCoordinateHelper.defaultCenter,
        permissionDenied: true,
        usedFallback: true,
      );
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return CreatePostGeolocationResult(
        point: LatLng(lastKnown.latitude, lastKnown.longitude),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return CreatePostGeolocationResult(
        point: LatLng(position.latitude, position.longitude),
      );
    } on Object {
      return CreatePostGeolocationResult(
        point: LocationCoordinateHelper.defaultCenter,
        usedFallback: true,
      );
    }
  }
}

bool latLngsEqual(LatLng? a, LatLng? b) {
  if (a == null || b == null) return a == b;
  return a.latitude == b.latitude && a.longitude == b.longitude;
}
