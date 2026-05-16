import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants.dart';
import '../../../data/models/location_point.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../services/background_service.dart';
import '../../../services/location_service.dart';
import '../../../services/permission_service.dart';

// singletons supplied at the composition root. throwing here gives a clear
// failure mode if a wiring step is forgotten.

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final backgroundServiceProvider = Provider<BackgroundTrackingService>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// permission state. refreshed manually after requests and on app resume;
/// not polled, no point checking when nothing changed.
class PermissionStatusNotifier extends Notifier<LocationPermissionStatus> {
  @override
  LocationPermissionStatus build() => LocationPermissionStatus.denied;

  Future<void> refresh() async {
    state = await ref.read(permissionServiceProvider).currentStatus();
  }

  Future<void> request() async {
    state = await ref
        .read(permissionServiceProvider)
        .ensureLocationPermission();
  }
}

final permissionStatusProvider =
    NotifierProvider<PermissionStatusNotifier, LocationPermissionStatus>(
      PermissionStatusNotifier.new,
    );

/// persisted toggle. survives restarts so we can resume tracking even if
/// the OS killed the service while the app was closed.
class TrackingEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final box = Hive.box(AppConstants.settingsBoxName);
    return box.get(AppConstants.trackingEnabledKey, defaultValue: false)
        as bool;
  }

  Future<void> set(bool value) async {
    state = value;
    await Hive.box(
      AppConstants.settingsBoxName,
    ).put(AppConstants.trackingEnabledKey, value);

    final service = ref.read(backgroundServiceProvider);
    if (value) {
      await service.start();
    } else {
      service.stop();
    }
  }
}

final trackingEnabledProvider =
    NotifierProvider<TrackingEnabledNotifier, bool>(
      TrackingEnabledNotifier.new,
    );

/// latest known location. three sources feed it:
///   1. hive — last persisted point (seeds UI on cold start).
///   2. IPC events from background isolate — authoritative when tracking is
///      on, including after UI relaunch.
///   3. foreground stream — see [foregroundLocationStreamProvider].
final latestLocationProvider = StreamProvider<LocationPoint?>((ref) async* {
  final repo = ref.watch(locationRepositoryProvider);
  final bg = ref.watch(backgroundServiceProvider);

  yield repo.latest;

  final bgSub = bg.locationUpdates().listen((point) async {
    await repo.save(point);
  });
  ref.onDispose(bgSub.cancel);

  await for (final point in repo.watch()) {
    yield point;
  }
});

/// foreground stream. runs whenever this provider is being watched (i.e.
/// while the screen is mounted), regardless of whether background tracking
/// is also on. the duplicate subscription was an optimisation that turned
/// out to be the wrong tradeoff: with bg on, the UI was stuck at the 30s
/// background cadence instead of the 5s the user expects while looking at
/// the screen. battery cost is negligible while the display is awake.
final foregroundLocationStreamProvider = StreamProvider<LocationPoint>((ref) {
  final loc = ref.watch(locationServiceProvider);
  final repo = ref.watch(locationRepositoryProvider);
  return loc.positionStream().asyncMap((p) async {
    await repo.save(p);
    return p;
  });
});
