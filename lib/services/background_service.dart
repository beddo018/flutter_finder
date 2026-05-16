import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../data/models/location_point.dart';
import 'notification_service.dart';

/// IPC event names shared by the UI and background isolates so a typo on
/// one side can't drift unnoticed.
class BgEvents {
  static const String locationUpdate = 'location_update';
  static const String stopService = 'stopService';
}

/// lifecycle wrapper around flutter_background_service. UI never calls the
/// plugin directly so platform-specific config stays in this file.
class BackgroundTrackingService {
  BackgroundTrackingService(this._service);

  final FlutterBackgroundService _service;

  static Future<BackgroundTrackingService> configure() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        // tracking starts only on explicit user toggle. auto-start on a
        // permission this sensitive would fail Play Store review.
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.notificationChannelId,
        initialNotificationTitle: 'Tracking location',
        initialNotificationContent: 'Acquiring first fix…',
        foregroundServiceNotificationId: AppConstants.notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    return BackgroundTrackingService(service);
  }

  Future<bool> start() => _service.startService();

  void stop() => _service.invoke(BgEvents.stopService);

  Future<bool> isRunning() => _service.isRunning();

  /// LocationPoints emitted from the background isolate, reconstructed from
  /// the JSON payload that crosses the IPC boundary.
  Stream<LocationPoint> locationUpdates() {
    return _service
        .on(BgEvents.locationUpdate)
        .where((e) => e != null)
        .map((e) => LocationPoint.fromJson(Map<String, dynamic>.from(e!)));
  }
}

// ---------------------------------------------------------------------------
// background isolate entry points. these run in a separate Dart isolate with
// their own memory; nothing held by the UI isolate is reachable here.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // continuous stream is driven by CLLocationManager via Geolocator;
  // returning true keeps the service alive for the OS-given window.
  return true;
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Android's persistent notification is owned by flutter_background_service
  // (see setForegroundNotificationInfo below). iOS needs its own.
  final notifications = NotificationService();
  if (Platform.isIOS) {
    await notifications.init();
  }

  // capture once immediately, then every backgroundInterval. timer-based so
  // emissions happen even when the device is stationary, per the spec.
  await _captureAndPublish(service, notifications);
  final timer = Timer.periodic(
    AppConstants.backgroundInterval,
    (_) => _captureAndPublish(service, notifications),
  );

  service.on(BgEvents.stopService).listen((_) async {
    timer.cancel();
    await notifications.cancel();
    await service.stopSelf();
  });
}

Future<void> _captureAndPublish(
  ServiceInstance service,
  NotificationService notifications,
) async {
  final Position pos;
  try {
    pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  } catch (_) {
    // permission/service errors surface through the dedicated permission
    // flow; swallow here to avoid duplicate user-facing messages.
    return;
  }

  final point = LocationPoint(
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracy: pos.accuracy,
    timestamp: pos.timestamp,
  );
  final summary =
      '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

  if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(
      title: 'Tracking location',
      content: summary,
    );
  } else {
    await notifications.showOrUpdate(
      title: 'Tracking location',
      body: summary,
    );
  }

  service.invoke(BgEvents.locationUpdate, point.toJson());
}
