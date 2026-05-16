import 'dart:async';

import 'package:hive/hive.dart';

import '../../core/constants.dart';
import '../models/location_point.dart';
import 'location_repository.dart';

/// hive-backed store; box.watch() provides a stream of changes for free, so
/// the UI can react to writes without a custom event bus.
class LocalLocationRepository implements LocationRepository {
  LocalLocationRepository(this._box);

  final Box<LocationPoint> _box;

  @override
  Future<void> save(LocationPoint point) => _box.add(point).then((_) {});

  @override
  LocationPoint? get latest {
    if (_box.isEmpty) return null;
    return _box.getAt(_box.length - 1);
  }

  @override
  Stream<LocationPoint> watch() => _box
      .watch()
      .where((e) => e.value is LocationPoint)
      .map((e) => e.value as LocationPoint);

  static Future<LocalLocationRepository> open() async {
    final box = await Hive.openBox<LocationPoint>(AppConstants.locationBoxName);
    return LocalLocationRepository(box);
  }
}
