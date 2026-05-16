import 'package:flutter/material.dart';

import 'features/tracking/tracking_screen.dart';

class FlutterFinderApp extends StatelessWidget {
  const FlutterFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TrackingScreen(),
    );
  }
}
