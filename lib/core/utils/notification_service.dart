import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/product/domain/entities/product.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _hasCheckedExpiry = false;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> checkAndShowExpiryNotifications(List<Product> products) async {
    if (_hasCheckedExpiry) return;
    _hasCheckedExpiry = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool shouldShowNotification = false;
    int expiringCount = 0;
    int expiredCount = 0;

    for (var product in products) {
      if (product.expiryDate != null) {
        final expiryDate = DateTime(product.expiryDate!.year,
            product.expiryDate!.month, product.expiryDate!.day);
        
        final difference = expiryDate.difference(today).inDays;

        if (difference < 0) {
          expiredCount++;
          shouldShowNotification = true;
        } else if (difference <= 7) {
          expiringCount++;
          shouldShowNotification = true;
        }
      }
    }

    if (shouldShowNotification) {
      String title = 'Product Expiry Alert ⚠️';
      String body = '';

      if (expiredCount > 0 && expiringCount > 0) {
        body = '$expiredCount products have expired and $expiringCount are expiring soon. Please check your inventory!';
      } else if (expiredCount > 0) {
        body = '$expiredCount products have expired. Please check your inventory!';
      } else if (expiringCount > 0) {
        body = '$expiringCount products are expiring soon. Please check your inventory!';
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('expiry_channel_id', 'Product Expiry',
              channelDescription: 'Notifications for product expiration',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true);

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: title,
          body: body,
          notificationDetails: platformChannelSpecifics,
          payload: 'expiry_payload');
    }
  }
}
