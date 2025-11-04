import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:huystore/core/data/notification_model.dart';
import 'notification_service.dart';

class FirebaseNotificationHandler {
  static void initFCMListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final messageText = data['message'] ;
      final title= message.notification?.title ?? 'Thông báo mới';

      NotificationService().addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: messageText,
          title:title,
          createdDate: DateTime.now()
        ),
      );
    });
  }
}
