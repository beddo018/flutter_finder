import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/permission_service.dart';
import '../providers/tracking_providers.dart';

class TrackingToggle extends ConsumerWidget {
  const TrackingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(trackingEnabledProvider);
    final permission = ref.watch(permissionStatusProvider);
    final canEnable = permission == LocationPermissionStatus.granted;

    return Card(
      child: SwitchListTile(
        title: const Text('Background tracking'),
        subtitle: Text(
          enabled
              ? 'On — your location is being recorded.'
              : canEnable
                  ? 'Off — turn on to begin recording.'
                  : 'Grant "Always" permission to enable.',
        ),
        value: enabled,
        onChanged: canEnable
            ? (v) => ref.read(trackingEnabledProvider.notifier).set(v)
            : null,
      ),
    );
  }
}
