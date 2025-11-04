import 'package:flutter/material.dart';
import 'package:huystore/core/data/notification_model.dart';
import 'package:huystore/core/services/notification_service.dart';
import 'package:huystore/features/orders/presentation/widgets/order_update_screen.dart';
import 'package:provider/provider.dart'; 
import 'package:huystore/core/layouts/main_layout.dart';
import 'package:huystore/features/home/data/models/order_statistics.dart';
import 'package:huystore/features/orders/data/services/order_service.dart';
import 'package:huystore/features/orders/presentation/pages/order_detail.dart';
import 'package:huystore/features/orders/presentation/pages/order_list_page.dart'; 
import 'package:huystore/features/orders/presentation/widgets/qr_scan_screen.dart';
import 'package:huystore/core/services/signalr_service.dart';
import 'package:huystore/features/home/data/models/menu_item.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  final SignalRService _signalRService = SignalRService();
  late Future<OrderStatisticModel> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatistics();

    _signalRService.startConnection().then((_) {
      _signalRService.listenForNewOrders(() {
        _refreshStatistics();
      });
      _signalRService.listenForUpdateStatusOrders(() {
        _refreshStatistics();
      });
    }); 
  }

  void _loadStatistics() {
    _statisticsFuture = _orderService.getHomeOrderStatistics();
  }

  void _refreshStatistics() {
    setState(() {
      _statisticsFuture = _orderService.getHomeOrderStatistics();
    });
  }

  @override
  void dispose() {
    _signalRService.stopConnection();
    super.dispose();
  }

  Future<void> _navigateToOrderList(List<int> statusIds, String title) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderListScreen(statusIds: statusIds, title: title),
      ),
    );
    _refreshStatistics();
  }
  
  void _handleNotificationTap(AppNotification notification) {
    Provider.of<NotificationService>(context, listen: false).markAsRead(notification.id);

    final orderId = notification.payload['orderId'];
    if (orderId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => OrderUpdateScreen(orderId: int.tryParse(orderId.toString()) ?? 0),
        ),
      );
    }
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScanScreen()),
    );
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dữ liệu QR: $result")),
      );
      _refreshStatistics();
    }
  }

  Future<void> _createNewOrder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateOrderScreen(orderId: null), 
      ),
    );
    _refreshStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Trang chủ",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshStatistics();
            await _statisticsFuture;
          }, 
          child: SafeArea( 
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [ 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            size: 80,
                            color: Colors.blue,
                          ),
                          onPressed: _scanQRCode,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Quét QR để cập nhật tiến trình xử lý",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // >>> GIẢM KHOẢNG CÁCH <<<
                  const SizedBox(height: 12), 
                  _buildSectionHeader("Thống kê đơn hàng"),
                  FutureBuilder<OrderStatisticModel>(
                    future: _statisticsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Lỗi: ${snapshot.error}"));
                      } else if (snapshot.hasData) {
                        final stats = snapshot.data!;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: menuItems.length + 1,
                          itemBuilder: (context, index) {
                            if (index == menuItems.length) {
                              return _buildAddNewCard();
                            }
                            final item = menuItems[index];
                            int count = 0;

                            switch (item['column']) {
                              case 'totalOrders':
                                count = stats.totalOrders; 
                                break;
                              case 'delayedOrders':
                                count = stats.delayedOrders; 
                                break;
                              case 'currentlyProcessing':
                                count = stats.currentlyProcessing; 
                                break;
                              case 'processingNeeded':
                                count = stats.processingNeeded; 
                                break;
                              case 'waitingConfirmOrders':
                                count = stats.waitingConfirmOrders; 
                                break; 
                              case 'deliveringOrders':
                                count = stats.deliveringOrders; 
                                break;
                              case 'completedOrders':
                                count = stats.completedOrders; 
                                break;
                              case 'rejectedOrders':
                                count = stats.rejectedOrders; 
                                break;
                            }

                            return _buildStatusCard(
                              title: item['title'] as String,
                              count: count,
                              icon: item['icon'] as IconData,
                              color: item['color'],
                              onTap: () => _navigateToOrderList(
                                item['statusIds']!=null&&item['statusIds'].length>0? item['statusIds'] as List<int>:[],
                                item['title'] as String,
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text("Không có dữ liệu"));
                      }
                    },
                  ), 
                  const SizedBox(height: 12), 
                  _buildSectionHeader("Thông báo mới"),
                  Consumer<NotificationService>(
                    builder: (context, notifService, child) {
                      final List<AppNotification> recentNotifications = notifService.notifications.take(3).toList();
                      
                      if (notifService.isLoading && recentNotifications.isEmpty) {
                         return const Center(child: Padding(
                           padding: EdgeInsets.all(16.0),
                           child: CircularProgressIndicator(strokeWidth: 2),
                         ));
                      }

                      if (recentNotifications.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text("Không có thông báo mới nào."),
                            ),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: recentNotifications.map((n) {
                            return ListTile(
                              leading: Icon(
                                n.isRead ? Icons.notifications_none : Icons.notifications_active, 
                                color: n.isRead ? Colors.blueGrey : Colors.orange,
                              ),
                              title: Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  color: n.isRead ? Colors.black54 : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                n.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: n.isRead ? null : const Icon(Icons.circle, size: 8, color: Colors.red),
                              onTap: () => _handleNotificationTap(n),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  // >>> THÊM KHOẢNG TRỐNG NHỎ Ở DƯỚI ĐÁY NẾU CẦN THIẾT <<<
                  const SizedBox(height: 10), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HÀM HELPER ĐÃ CẬP NHẬT PADDING ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      // Đã giảm Padding
      padding: const EdgeInsets.only(top: 6, bottom: 4), 
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
  
  // Các widget helper còn lại (giữ nguyên)
  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCard() {
    return GestureDetector(
      onTap: _createNewOrder,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 40, color: Colors.green),
            SizedBox(height: 8),
            Text(
              "Thêm mới",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "đơn hàng",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}