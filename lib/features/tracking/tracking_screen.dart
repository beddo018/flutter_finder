import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/tracking_providers.dart';
import 'widgets/location_card.dart';
import 'widgets/location_map.dart';
import 'widgets/permission_banner.dart';
import 'widgets/tracking_toggle.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionStatusProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // permissions can change in OS settings while we're backgrounded; resync
    // on resume so the banner reflects reality.
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionStatusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // watching the foreground stream here keeps it subscribed for the
    // lifetime of the screen.
    ref.watch(foregroundLocationStreamProvider);
    final latest = ref.watch(latestLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Finder')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PermissionBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LocationCard(point: latest.value),
                  const SizedBox(height: 12),
                  LocationMap(point: latest.value),
                  const SizedBox(height: 12),
                  const TrackingToggle(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
