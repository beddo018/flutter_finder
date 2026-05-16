import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../data/models/location_point.dart';

/// wraps Geolocator so callers depend on LocationPoint instead of the
/// plugin's Position type.
class LocationService {
  /// emits a fix every [AppConstants.foregroundInterval] regardless of
  /// movement. brief asks for regular intervals; production would prefer
  /// distance-filtered emissions for battery.
  Stream<LocationPoint> positionStream() async* {
    while (true) {
      final p = await currentPosition();
      if (p != null) yield p;
      await Future.delayed(AppConstants.foregroundInterval);
    }
  }

  Future<LocationPoint?> currentPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _map(p);
    } catch (_) {
      return null;
    }
  }

  LocationPoint _map(Position p) => LocationPoint(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracy: p.accuracy,
    timestamp: p.timestamp,
  );
}
