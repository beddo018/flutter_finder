import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/location_point.dart';

/// the relative-time line ("Ns ago") needs to keep ticking between location
/// updates, otherwise it would freeze on "0s ago" for the full interval and
/// give the impression that nothing's moving. one-second timer rebuilds.
class LocationCard extends StatefulWidget {
  const LocationCard({super.key, required this.point});

  final LocationPoint? point;

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.point;

    if (p == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_searching),
              const SizedBox(width: 12),
              Text('Waiting for first fix…', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last known location', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '±${p.accuracy.toStringAsFixed(1)} m  ·  ${_relativeTime(p.timestamp)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
