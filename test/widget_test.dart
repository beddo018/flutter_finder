// Scope of these tests:
//   - Pure-Dart roundtrip on LocationPoint, since that JSON shape is the IPC
//     contract between the background isolate and the UI.
//   - Widget tests on LocationCard, which is the only piece of UI with
//     non-trivial formatting logic.
//
// Anything that crosses a platform channel (geolocator, permission_handler,
// flutter_background_service, hive's path_provider) is deliberately out of
// scope: those need integration tests on a real device to be meaningful, and
// LocationRepository / BackgroundTrackingService are interfaces precisely so
// the rest of the app can be exercised without them. The Riverpod overrides
// in main.dart are what a future widget test of TrackingScreen would replace.

import 'package:flutter/material.dart';
import 'package:flutter_finder/data/models/location_point.dart';
import 'package:flutter_finder/features/tracking/widgets/location_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationPoint JSON roundtrip', () {
    test('preserves coordinates, accuracy, and timestamp', () {
      final original = LocationPoint(
        latitude: 35.6586,
        longitude: 139.7454,
        accuracy: 12.3,
        timestamp: DateTime.parse('2026-05-16T06:30:00.000Z'),
      );

      final restored = LocationPoint.fromJson(original.toJson());

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.timestamp.toUtc(), original.timestamp.toUtc());
    });

    test('accepts integer-valued numerics (e.g. lat: 0)', () {
      // Defensive: the IPC layer can legitimately serialise whole numbers as
      // ints, so fromJson has to widen num -> double rather than cast.
      final restored = LocationPoint.fromJson({
        'lat': 0,
        'lng': 0,
        'acc': 5,
        'ts': '2026-05-16T06:30:00.000Z',
      });

      expect(restored.latitude, 0.0);
      expect(restored.longitude, 0.0);
      expect(restored.accuracy, 5.0);
    });
  });

  group('LocationCard', () {
    testWidgets('renders waiting state when no point is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LocationCard(point: null))),
      );

      expect(find.text('Waiting for first fix…'), findsOneWidget);
      expect(find.byIcon(Icons.location_searching), findsOneWidget);
    });

    testWidgets('renders coordinates, accuracy, and relative time', (
      tester,
    ) async {
      final point = LocationPoint(
        latitude: 35.658600,
        longitude: 139.745400,
        accuracy: 8.4,
        timestamp: DateTime.now().subtract(const Duration(seconds: 12)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LocationCard(point: point)),
        ),
      );

      expect(find.text('Last known location'), findsOneWidget);
      expect(find.text('35.658600, 139.745400'), findsOneWidget);
      expect(find.textContaining('±8.4 m'), findsOneWidget);
      expect(find.textContaining('12s ago'), findsOneWidget);
    });

    testWidgets('relative time formats minutes when older than 60s', (
      tester,
    ) async {
      final point = LocationPoint(
        latitude: 0,
        longitude: 0,
        accuracy: 0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LocationCard(point: point)),
        ),
      );

      expect(find.textContaining('3m ago'), findsOneWidget);
    });
  });
}
