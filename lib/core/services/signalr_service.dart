import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _hubConnection;
   late final  String serverUrl = dotenv.env['API_URL'].toString()+'/hubs/notification' ?? '';

  Future<void> startConnection() async {
    _hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();
    _hubConnection!.onclose(({Exception? error}) {
      debugPrint("Kết nối SignalR đã đóng: $error");
    });

    try {
      await _hubConnection!.start();
      debugPrint("Kết nối SignalR đã được khởi động.");
    } catch (e) {
      debugPrint("Lỗi khi khởi động kết nối SignalR: $e");
    }
  }

  void listenForNewOrders(VoidCallback onNewOrder) {
    if (_hubConnection?.state == HubConnectionState.Connected) { 
      _hubConnection!.on("NewOrderCreated", (arguments) {
        debugPrint("Nhận được tín hiệu có đơn hàng mới.");
        onNewOrder();
      });
    } else {
      debugPrint("Không kết nối đến server SignalR.");
    }
  }
void listenForUpdateStatusOrders(VoidCallback onNewOrder) {
    if (_hubConnection?.state == HubConnectionState.Connected) { 
      _hubConnection!.on("UpdateStatusOrders", (arguments) {
        debugPrint("Nhận được tín hiệu thay đổi trạng thái đơn hàng.");
        onNewOrder();
      });
    } else {
      debugPrint("Không kết nối đến server SignalR.");
    }
  }
  Future<void> stopConnection() async {
    await _hubConnection?.stop();
    debugPrint("Kết nối SignalR đã dừng.");
  }
}