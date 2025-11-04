import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:huystore/features/home/presentation/pages/home_page.dart';
import 'package:huystore/features/orders/presentation/pages/order_list_page.dart'; 
 
  
class NotificationRouter {
static final Map<String, Widget Function(Map<String, dynamic>)> _routes = {
  'order_list': (data) { 
    final dynamic statusData = data['statusId']; 
    List<int> statusIds; 
    if (statusData is List) {
      statusIds = statusData.map<int>((id) => int.tryParse(id.toString()) ?? -1).toList();
      
    } else if (statusData != null) {
      final int? statusId = int.tryParse(statusData.toString());
      if (statusId != null) {
        statusIds = [statusId];
      } else {
        statusIds = [];
      }
    } else {
      statusIds = [];
    }

    return OrderListScreen(
      statusIds: statusIds,
      title: data['title'] ?? 'Danh sách đơn',
    );
  },
  'home': (_) => const HomeScreen(),
};

  static Future<void> init(BuildContext context) async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(context, message.data);
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(context, initialMessage.data);
    }
  }

  static void _handleMessage(BuildContext context, Map<String, dynamic> data) {
    final screen = data['screen'];
    final builder = _routes[screen];

    if (builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder(data)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }
}
