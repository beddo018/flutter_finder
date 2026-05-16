# Flutter Finder

Single-device location tracker. Records foreground, background, and post-termination GPS fixes and shows the latest one in-app and in a persistent notification.

## Run

```
flutter pub get
flutter run
```

Tested on Flutter 3.41 / Dart 3.11. Min Android 24, iOS 13.

## Permissions

On first launch the app requests location while-in-use, then upgrades to "Always". On Android 13+ it also requests notification permission (needed for the foreground service notification). Toggle background tracking from the switch on the main screen.

## Testing on the iOS Simulator

The simulator does not have a GPS chip, so the location stream emits nothing until you set a simulated location: in the Simulator app menu, **Features → Location → Custom Location…** (or pick a preset such as "City Run" / "Freeway Drive"). After that the app should populate.

The "Always" permission upgrade dialog is also unreliable on the simulator — `Permission.locationAlways.request()` often silently no-ops. The banner exposes both REQUEST and SETTINGS routes; on the simulator, SETTINGS is the reliable path. The same workaround applies on Android 11+, where the OS deliberately routes background-location requests through Settings rather than a dialog.

## Architecture

```
lib/
  main.dart                       App entry. Initialises Hive, configures
                                  the background service, wires Riverpod
                                  overrides.
  app.dart                        MaterialApp + theme.
  core/constants.dart             Intervals, notification IDs, box names.
  data/
    models/location_point.dart    Plain model + Hive TypeAdapter.
    repositories/
      location_repository.dart    Abstract. Future remote impl drops in here.
      local_location_repository.dart   Hive impl.
  services/
    permission_service.dart       Two-step location permission flow.
    location_service.dart         Geolocator wrapper with 5s timer-based
                                  foreground stream.
    notification_service.dart     flutter_local_notifications (iOS).
    background_service.dart       flutter_background_service config and
                                  background isolate entry point.
  features/tracking/
    providers/tracking_providers.dart   Riverpod state + DI.
    tracking_screen.dart          Main screen.
    widgets/                      Map, location card, toggle, permission
                                  banner.
```

Two location streams run independently. The foreground stream lives in the UI isolate and ticks every 5 seconds while the screen is mounted. The background isolate (managed by `flutter_background_service`) runs `Timer.periodic` at 30 seconds and pushes each fix to the UI over the plugin's IPC channel; the UI persists everything to Hive, which `box.watch()` then surfaces back through Riverpod. On Android the foreground service shows the persistent notification and survives task removal; on iOS a regular notification fills the same role while the OS background-location indicator handles the user-facing signal.

## What would change for production

- Adaptive sampling (significant-change on iOS, activity recognition on Android) instead of a fixed interval — current implementation will burn battery on long stationary periods. The `distanceFilterMeters` constant is in place as the right knob.
- Swap `LocalLocationRepository` for a `RemoteLocationRepository` that batches points and POSTs to a backend. The interface is already in place.
- Add a token-based device pairing flow so a caregiver app can view this device's location.
- Wire up `RECEIVE_BOOT_COMPLETED` and an iOS region-monitoring trigger to resume tracking after a device reboot. Currently tracking resumes on next app launch.
- Crash + metrics (Sentry, Firebase Crashlytics).

## Plugins

| Plugin | Reason |
|---|---|
| `geolocator` | Cross-platform GPS + correct iOS background settings. |
| `permission_handler` | Background-location runtime permissions. |
| `flutter_background_service` | Android foreground service; iOS background entry point. |
| `flutter_local_notifications` | iOS notification (Android's is handled by the service). |
| `hive` / `hive_flutter` | Codegen-free local persistence with a streamable box. |
| `flutter_riverpod` | DI and reactive state. |
| `flutter_map` / `latlong2` | OpenStreetMap tiles — no API key required. |
