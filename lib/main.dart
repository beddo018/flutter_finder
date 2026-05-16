import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants.dart';
import 'data/models/location_point.dart';
import 'data/repositories/local_location_repository.dart';
import 'features/tracking/providers/tracking_providers.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LocationPointAdapter());
  await Hive.openBox(AppConstants.settingsBoxName);
  final repo = await LocalLocationRepository.open();

  await NotificationService().init();

  // background isolate has its own copy of plugin state; configure must run
  // in the UI isolate at startup so the entry-point symbol is registered.
  final bg = await BackgroundTrackingService.configure();

  // resume tracking if it was on at last close. service usually survives
  // task removal; this covers process death from low-memory kills.
  final settings = Hive.box(AppConstants.settingsBoxName);
  final wantsTracking =
      settings.get(AppConstants.trackingEnabledKey, defaultValue: false)
          as bool;
  if (wantsTracking && !(await bg.isRunning())) {
    await bg.start();
  }

  runApp(
    ProviderScope(
      overrides: [
        locationRepositoryProvider.overrideWithValue(repo),
        backgroundServiceProvider.overrideWithValue(bg),
      ],
      child: const FlutterFinderApp(),
    ),
  );
}
