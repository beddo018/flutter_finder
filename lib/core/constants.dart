class AppConstants {
  AppConstants._();

  static const Duration foregroundInterval = Duration(seconds: 5);
  static const Duration backgroundInterval = Duration(seconds: 30);

  /// kept for the talking point: in production i'd prioritize refresh based
  /// on distance moved to spare battery on stationary users. spec here asks
  /// for fixed-interval updates so this currently isn't applied.
  static const int distanceFilterMeters = 10;

  static const String locationBoxName = 'location_points';
  static const String settingsBoxName = 'settings';
  static const String trackingEnabledKey = 'tracking_enabled';

  static const String notificationChannelId = 'tracking_channel';
  static const String notificationChannelName = 'Location tracking';
  static const int notificationId = 888;
}
