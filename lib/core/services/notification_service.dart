import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:huystore/core/data/notification_model.dart';
import 'package:huystore/core/services/api_service.dart'; 
 

class NotificationService with ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Khởi tạo ApiService để sử dụng Dio
  final ApiService _apiService = ApiService(); 

  final List<AppNotification> _notifications = [];
  int _totalNotifications = 0;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length; 
  int get totalNotifications => _totalNotifications;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- 1. HÀM TẢI THÔNG BÁO PHÂN TRANG TỪ API (GET) ---
  Future<void> fetchNotifications({int pageIndex = 1, int pageSize = 50, bool clearExisting = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final Response response = await _apiService.get( 'notification/getlistpaging',
        query: {'pageIndex': pageIndex, 'pageSize': pageSize}
      );

      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
      if (responseData['isSuccessed'] == true) {
        final List<AppNotification> fetchedNotis = [];
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;

        for (var item in dataList) {
          fetchedNotis.add(_mapApiDataToAppNotification(item as Map<String, dynamic>));
        }

        if (clearExisting) {
          _notifications.clear();
        }

        _notifications.addAll(fetchedNotis);        
        _totalNotifications = responseData['totalRows'] ?? _notifications.length;
        
      } else {
        print('Lỗi khi tải thông báo: ${responseData['message']}');
      }

    } on DioException catch (e) {
      print('Lỗi Dio khi tải thông báo: ${e.message}');
    } catch (e) {
      print('Lỗi không xác định khi tải thông báo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _totalNotifications++;
    notifyListeners();
  }

 
  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) { 
      try {
        final Response response = await _apiService.put('notification/updateisread/$id');
        final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

        if (responseData['statusCode'] == 200) { 
          _notifications[index].isRead = true;
        } else {
          print('Server báo lỗi khi đánh dấu đã đọc $id: ${responseData['message']}');
        }
        
      } on DioException catch (e) {
        print('Lỗi Dio khi đánh dấu đã đọc $id: ${e.message}');
      } catch (e) {
        print('Lỗi không xác định khi đánh dấu đã đọc $id: $e');
      } 
      notifyListeners();
    }
  }

  // --- 4. HÀM ĐÁNH DẤU TẤT CẢ ĐÃ ĐỌC (POST) ---
  void markAllAsRead() async {
    if (unreadCount == 0) return; 
    try {
      // API này không cần data, chỉ cần gọi POST
      final Response response = await _apiService.post('notification/updateisreadall');
      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
      
      if (responseData['statusCode'] == 200) { 
        for (var n in _notifications) {
          n.isRead = true;
        }
      } else {
        print('Server báo lỗi khi đánh dấu tất cả đã đọc: ${responseData['message']}');
      }
      
    } on DioException catch (e) {
      print('Lỗi Dio khi đánh dấu tất cả đã đọc: ${e.message}');
    } catch (e) {
      print('Lỗi không xác định khi đánh dấu tất cả đã đọc: $e');
    }
    
    notifyListeners();
  }
  
  // --- HÀM HỖ TRỢ CHUYỂN ĐỔI DỮ LIỆU ---
  AppNotification _mapApiDataToAppNotification(Map<String, dynamic> dataMap) {
    // 1. Xử lý Payload (JSON string -> Map)
    final String payloadJson = dataMap['payload'] as String? ?? '{}';
    Map<String, dynamic> payloadData = {};
    try { 
      payloadData = json.decode(payloadJson) as Map<String, dynamic>;
      if (dataMap.containsKey('data') && dataMap['data'] is Map) {
          payloadData.addAll(dataMap['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('Lỗi phân tích JSON Payload: $e');
    } 
    final String notificationId = dataMap['id'] as String? ?? dataMap['externalId'].toString();

    return AppNotification(
      id: notificationId,
      title: dataMap['title'] as String? ?? 'Không tiêu đề',
      message: dataMap['message'] as String? ?? 'Không nội dung',
      isRead: dataMap['isRead'] as bool? ?? false,
      createdDate: DateTime.parse(dataMap['createdDate']),
      payload: payloadData,
    );
  }
}