import 'package:flutter/material.dart';

/// Danh sách menu trạng thái đơn hàng dùng chung
const List<Map<String, dynamic>> menuItems = [
  {
    'title': 'Đơn trễ',
    'color': Colors.red,
    'icon': Icons.error,
    'statusIds': [8, 9],
    'column': 'delayedOrders',
  },
  {
    'title': 'Đang xử lý',
    'color': Colors.deepOrangeAccent,
    'icon': Icons.sync,
    'statusIds': [9],
    'column': 'currentlyProcessing',
  },
  {
    'title': 'Chờ xử lý',
    'icon': Icons.sync,
    'color': Colors.orange,
    'statusIds': [8],
    'column': 'processingNeeded',
  },
  {
    'title': 'Chờ xác nhận giá',
    'icon': Icons.pending_actions,
    'color': Colors.purple,
    'statusIds': [1, 2, 3, 4, 5, 6],
    'column': 'waitingConfirmOrders',
  },
  {
    'title': 'Đang giao trả',
    'icon': Icons.delivery_dining,
    'statusIds': [11, 12],
    'color': Colors.teal,
    'column': 'deliveringOrders',
  },
  {
    'title': 'Hoàn thành',
    'color': Colors.green,
    'icon': Icons.check_circle,
    'statusIds': [13],
    'column': 'completedOrders',
  },

  {
    'title': 'Bị từ chối',
    'color': Colors.grey,
    'icon': Icons.cancel,
    'statusIds': [14],
    'column': 'rejectedOrders',
  },
  {
    'title': 'Tổng số đơn',
    'icon': Icons.assignment_turned_in,
    'statusIds': [],
    'color': Colors.indigo,
    'column': 'totalOrders',
  },
];
