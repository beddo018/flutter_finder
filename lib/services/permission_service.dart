import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// plugin permission enums collapsed into a single shape so the UI doesn't
/// need to know which package surfaced each state.
enum LocationPermissionStatus {
  granted,
  whileInUse,
  denied,
  deniedForever,
  serviceDisabled,
}

class PermissionService {
  /// two-step flow required by both Android 10+ and iOS: foreground first,
  /// then upgrade to background. requesting background directly is silently
  /// denied by both platforms.
  Future<LocationPermissionStatus> ensureLocationPermission() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return LocationPermissionStatus.serviceDisabled;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }
    if (perm == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }

    // on Android 11+ this navigates to system settings rather than showing a
    // dialog; the banner offers a Settings shortcut for that path.
    if (perm == LocationPermission.whileInUse) {
      final bg = await ph.Permission.locationAlways.request();
      if (bg.isGranted) return LocationPermissionStatus.granted;
      return LocationPermissionStatus.whileInUse;
    }

    return LocationPermissionStatus.granted;
  }

  Future<LocationPermissionStatus> currentStatus() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return LocationPermissionStatus.serviceDisabled;
    final perm = await Geolocator.checkPermission();
    switch (perm) {
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  Future<void> openSystemSettings() => ph.openAppSettings();
}
