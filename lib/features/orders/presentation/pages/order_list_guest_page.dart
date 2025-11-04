import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart'; 
import 'package:huystore/core/utils/format_utils.dart';
import 'package:huystore/core/utils/helper.dart';
import 'package:huystore/features/orders/data/models/order_model.dart';
import 'package:huystore/features/orders/data/services/order_service.dart';
import 'package:huystore/features/orders/presentation/widgets/order_update_screen.dart';
import 'package:huystore/features/orders/presentation/pages/order_detail.dart';
import 'package:huystore/features/orders/presentation/widgets/order_view_guest_screen.dart';

class OrderListGuestScreen extends StatefulWidget { 
  final String title;
  final String? phoneNumber; 
  const OrderListGuestScreen({
    Key? key, 
    required this.title,
    required this.phoneNumber 
  }) : super(key: key);

  @override
  State<OrderListGuestScreen> createState() => _OrderListGuestScreenState();
}

class _OrderListGuestScreenState extends State<OrderListGuestScreen> {
  final OrderService _orderService = OrderService();
  static const int _pageSize = 10; 

  bool _loading = false;
  bool _isFetchingMore = false;
  String? _error;
  List<OrderModel> _orders = [];
  int _skip = 0;
  int _totalRows = 0; // tổng record từ API
  

  @override
  void initState() {
    super.initState();
    _fetchOrders(isFirstLoad: true); 
  }

  @override
  void dispose() { 
    super.dispose();
  }

  @override
  void didUpdateWidget(OrderListGuestScreen oldWidget) {
    super.didUpdateWidget(oldWidget); 
    bool searchQueryChanged = oldWidget.phoneNumber != widget.phoneNumber;

    if ( searchQueryChanged) {
      _fetchOrders(isFirstLoad: true);
    }
  }

  

  Future<void> _fetchOrders({bool isFirstLoad = false}) async {
    if (isFirstLoad) {
      setState(() {
        _loading = true;
        _error = null;
        _orders = [];
        _skip = 0;
        _totalRows = 0;
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      final skip = _skip; 
      final resp = await _orderService.searchOrdersByPhone( 
        phoneNumber:widget.phoneNumber.toString(),
        skip: skip,
        take: _pageSize,
      );

      final List<OrderModel> newOrders = resp.data;
      setState(() {
        _orders.addAll(newOrders);
        _skip += newOrders.length;
        _totalRows = resp.totalRows;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _isFetchingMore = false;
      });
    }
  }

  
  @override
  Widget build(BuildContext context) { 
    // Thay thế MainLayout bằng Scaffold cơ bản
    return Scaffold( 
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Lỗi: $_error"))
              : _orders.isEmpty
                  ? const Center(child: Text("Không có đơn hàng nào cho SĐT này."))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchOrders(isFirstLoad: true);
                      },
                      child: ListView.builder(
                        itemCount: _orders.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _orders.length) { 
                            if (_orders.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final bool showLoadMore = _skip < _totalRows;

                            if (!showLoadMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: Text("Đã hiển thị hết tất cả đơn hàng.")),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed:
                                        _isFetchingMore ? null : () => _fetchOrders(),
                                    child: _isFetchingMore
                                        ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                        : const Text("Xem thêm"),
                                  ),
                                ),
                              );
                            }
                          }

                          final order = _orders[index];
                          final isDeadlineSoon = Helper.isNearDeadline(order.desiredTime);  
                          final statusColor = Helper.getStatusColor(order.statusId ?? 0);

                          return ListTile(
                            leading: const Icon(Icons.receipt_long),
                            title: Text(order.code ?? ""),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Khách: ${order.customerName ?? ""}"),
                                Text("SĐT: ${order.phoneNumber ?? ""}"),
                                Text("Cửa hàng: ${order.shopName ?? ""}"), 
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order.statusName ?? "",
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isDeadlineSoon)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  FormatUtils.formatCurrency(order.totalPrice),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  order.desiredTime != null
                                      ? FormatUtils.formatDateTime(order.desiredTime)
                                      : "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDeadlineSoon ? Colors.red : Colors.grey[700],
                                    fontWeight:
                                        isDeadlineSoon ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () { 
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailViewScreen(
                                    orderId: order.id ?? 0,
                                    orderCode: order.code,
                                  ),
                                ),
                              ); 
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}