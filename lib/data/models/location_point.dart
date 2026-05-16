import 'package:hive/hive.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// IPC across isolates only accepts primitives, hence JSON instead of the
  /// hive adapter for transport.
  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'acc': accuracy,
    'ts': timestamp.toIso8601String(),
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    accuracy: (json['acc'] as num).toDouble(),
    timestamp: DateTime.parse(json['ts'] as String),
  );
}

/// Handwritten adapter to avoid build_runner.
class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 1;

  @override
  LocationPoint read(BinaryReader reader) {
    final lat = reader.readDouble();
    final lng = reader.readDouble();
    final acc = reader.readDouble();
    final ts = reader.readInt();
    return LocationPoint(
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeDouble(obj.accuracy);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
