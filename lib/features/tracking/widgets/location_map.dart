import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/location_point.dart';

/// renders the latest fix on an OpenStreetMap tile layer. flutter_map is
/// keyless; google_maps_flutter would need API keys and per-platform build
/// config we don't need here.
class LocationMap extends StatefulWidget {
  const LocationMap({super.key, required this.point});

  final LocationPoint? point;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  // initialCenter is consumed once on FlutterMap mount; subsequent point
  // changes need an imperative move via the controller, otherwise the camera
  // sticks to the first fix while the marker silently moves under it.
  final _controller = MapController();

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.point;
    final prev = oldWidget.point;
    if (p != null && prev != null && (p.latitude != prev.latitude || p.longitude != prev.longitude)) {
      _controller.move(LatLng(p.latitude, p.longitude), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.point;
    if (p == null) return _EmptyMapPlaceholder();

    final center = LatLng(p.latitude, p.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_finder',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text('No location yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Grant location permission, then tap the refresh button or '
                'enable background tracking.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
