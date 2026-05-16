import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants.dart';

/// persistent notification used while tracking is on. required on Android
/// for the foreground service to keep running; on iOS it's secondary to the
/// always-on location indicator.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _createChannel();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Shows your last known location while tracking is on.',
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> showOrUpdate({required String title, required String body}) {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      ongoing: true,
      autoCancel: false,
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBanner: false,
      presentSound: false,
    );
    return _plugin.show(
      id: AppConstants.notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  Future<void> cancel() => _plugin.cancel(id: AppConstants.notificationId);
}
