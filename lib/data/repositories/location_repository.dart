import '../models/location_point.dart';

/// persistence boundary for location data; concrete implementations are
/// swapped at the composition root, so the rest of the app depends only on
/// this interface and a remote/network-backed variant can replace the local
/// store without touching the UI or service layers.
abstract class LocationRepository {
  Future<void> save(LocationPoint point);

  LocationPoint? get latest;

  /// emits whenever a new point is saved, regardless of source (foreground
  /// stream or background isolate).
  Stream<LocationPoint> watch();
}
