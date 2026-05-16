import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/permission_service.dart';
import '../providers/tracking_providers.dart';

/// surfaces both an in-app request and a settings shortcut. settings route
/// is the only reliable path on Android 11+ (where background requests are
/// routed to settings rather than a dialog).
class PermissionBanner extends ConsumerWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(permissionStatusProvider);
    final copy = _copyFor(status);
    if (copy == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(copy.$1)),
            if (copy.$2)
              TextButton(
                onPressed: () =>
                    ref.read(permissionStatusProvider.notifier).request(),
                child: const Text('REQUEST'),
              ),
            TextButton(
              onPressed: () =>
                  ref.read(permissionServiceProvider).openSystemSettings(),
              child: const Text('SETTINGS'),
            ),
          ],
        ),
      ),
    );
  }

  /// (message, showRequestButton) — null means no banner.
  (String, bool)? _copyFor(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return null;
      case LocationPermissionStatus.whileInUse:
        return ('Background tracking needs "Always" location access.', true);
      case LocationPermissionStatus.denied:
        return ('Location permission is required.', true);
      case LocationPermissionStatus.deniedForever:
        return ('Permission permanently denied. Enable it in Settings.', false);
      case LocationPermissionStatus.serviceDisabled:
        return ('Location services are off on this device.', false);
    }
  }
}
