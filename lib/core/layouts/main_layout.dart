import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:huystore/core/data/notification_model.dart';
import 'package:huystore/core/layouts/search_bar_widget.dart';
import 'package:huystore/features/orders/presentation/widgets/order_update_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/update_info_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../global.dart';

const String shopName = 'Lalalab';
const String userName = 'Admin';
String _searchQuery = '';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final floatingActionButton;

  const MainLayout({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static bool _notificationsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifService = Provider.of<NotificationService>(context, listen: false);
      if (!_notificationsLoaded) {
        notifService.fetchNotifications(pageIndex: 1, pageSize: 50, clearExisting: true);
        _notificationsLoaded = true; // Đặt flag thành true sau khi gọi
      } else {
      }

      _listenToFCM();
    });
  }

  StreamSubscription? _fcmSubscription;
  void _performSearch(String query) {
    _searchQuery = query;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderListScreen(
          title: query.isNotEmpty
              ? 'Kết quả tìm kiếm cho "$query"'
              : 'Tổng số đơn',
          searchQuery: query.isNotEmpty ? query : null,
          statusIds: const <int>[],
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // --- HÀM XỬ LÝ MESSAGE FCM ---
  AppNotification _mapFCMMessageToAppNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Thông báo mới (FCM)';
    final messageBody = notification?.body ?? data['body'] ?? 'Bạn có một tin nhắn mới.';
    final String id = data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

    return AppNotification(
      id: id,
      title: title,
      message: messageBody,
      createdDate: DateTime.now(), // Thời gian nhận trên client
      payload: data,
      isRead: false,
    );
  }
  // --- HÀM LẮNG NGHE FCM ---
  void _listenToFCM() {
    final notifService = Provider.of<NotificationService>(context, listen: false);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.data}');
      final newNotif = _mapFCMMessageToAppNotification(message);
      notifService.addNotification(newNotif);
    });

    _fcmSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      final newNotif = _mapFCMMessageToAppNotification(message);
      notifService.addNotification(newNotif);
      if (message.data['orderId'] != null && mounted) {
        Navigator.push( 
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderUpdateScreen(orderId: int.parse(message.data['orderId']!)),
          ),
        );
      }
    });
  }

  // --- HÀM POPUP MENU GỐC ---
  void _handleMenuSelected(BuildContext context, int value) {
    switch (value) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpdateInfoPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
        );
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/login');
        break;
    }
  }

  final List<List<Map<String, dynamic>>> _orderMenuGroups = [
    [
      {
        'title': 'Đơn trễ',
        'icon': Icons.error,
        'color': Colors.red,
        'statusIds': const [8, 9],
      },
      {
        'title': 'Đang xử lý',
        'icon': Icons.sync,
        'color': Colors.deepOrangeAccent,
        'statusIds': const [9],
      },
      {
        'title': 'Chờ xử lý',
        'icon': Icons.hourglass_bottom,
        'color': Colors.orange,
        'statusIds': const [8],
      },
      {
        'title': 'Chờ xác nhận giá',
        'icon': Icons.pending_actions,
        'color': Colors.purple,
        'statusIds': const [1, 2, 3, 4, 5, 6],
      },
      {
        'title': 'Đang giao trả',
        'icon': Icons.delivery_dining,
        'color': Colors.teal,
        'statusIds': const [11, 12],
      },
    ],
    [
      {
        'title': 'Hoàn thành',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'statusIds': const [13],
      },
      {
        'title': 'Bị từ chối',
        'icon': Icons.cancel,
        'color': Colors.grey,
        'statusIds': const [14],
      },

      {
        'title': 'Tổng số đơn',
        'icon': Icons.assignment_turned_in,
        'color': Colors.indigo,
        'statusIds': null,
      },
      {
        'title': 'Đánh giá',
        'icon': Icons.star,
        'color': Colors.amber,
        'statusIds': const [],
      },
    ],
  ];

void _showNotificationModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer<NotificationService>(
        builder: (context, notifService, child) {
          final notis = notifService.notifications;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thông báo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: notifService.unreadCount == 0 ? null : () {
                              notifService.markAllAsRead(); // Gọi API/Local để đánh dấu tất cả
                            },
                            child: const Text('Đánh dấu tất cả đã đọc'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Xử lý trạng thái đang tải
                      if (notifService.isLoading && notis.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      // Xử lý trạng thái không có dữ liệu
                      if (notis.isEmpty) {
                        return const Center(child: Text("Chưa có thông báo nào."));
                      }

                      return ListView.builder(
                        itemCount: notis.length,
                        itemBuilder: (context, index) {
                          final n = notis[index];
                          return ListTile(
                            tileColor: n.isRead ? Colors.white : Colors.blue.shade50,
                            leading: Icon(
                              Icons.circle,
                              size: 10,
                              color: n.isRead ? Colors.transparent : Colors.red,
                            ),
                            title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n.message),
                            // Sử dụng DateFormat an toàn
                            trailing: Text(DateFormat('dd/MM HH:mm').format(n.createdDate)),
                            onTap: () {
                              if (!n.isRead) {
                                notifService.markAsRead(n.id); // Đánh dấu đã đọc
                              }
                              final orderId = n.payload['orderId'];
                              if (orderId != null && mounted) {
                                Navigator.pop(ctx);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (c) => OrderUpdateScreen(orderId: int.tryParse(orderId.toString()) ?? 0),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    List<Widget> combinedActions = widget.actions?.toList() ?? [];
    combinedActions.add(
      Consumer<NotificationService>(
        builder: (context, notifService, _) {
          final count = notifService.unreadCount;
          return IconButton(
            icon: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              badgeContent: Text(
                count > 9 ? "9+" : count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              showBadge: count > 0,
              child: const Icon(
                Icons.notifications,
                color: Colors.orange,
              ),
            ),
            onPressed: () {
              _showNotificationModal(context); // Gọi hàm hiển thị modal mới
            },
          );
        },
      ),
    );

    // Thêm PopupMenuButton gốc
    combinedActions.add(
      PopupMenuButton<int>(
        onSelected: (value) => _handleMenuSelected(context, value),
        offset: const Offset(0, kToolbarHeight),
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            enabled: false,
            child: ValueListenableBuilder<String?>(
              valueListenable: globalAvatarUrl,
              builder: (context, url, _) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (url != null && url.isNotEmpty)
                        ? NetworkImage(url)
                        : const AssetImage(
                            'assets/images/logo-store.png',
                          )
                              as ImageProvider,
                  ),
                  title: const Text(
                    shopName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(userName),
                );
              },
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<int>(
            value: 0,
            child: ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Cập nhật thông tin'),
            ),
          ),
          const PopupMenuItem<int>(
            value: 1,
            child: ListTile(
              leading: Icon(Icons.lock, color: Colors.green),
              title: Text('Đổi mật khẩu'),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<int>(
            value: 3,
            child: ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );


    return Builder(
      builder: (context) {
        return Scaffold(
          key: scaffoldKey,
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 0, 163, 139),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/logo-store.png'),
                  ),
                  accountName: Text(
                    "Lalalab",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    "Chuyên sửa giày & chăm sóc giày",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ..._buildMenuGroups(context), // Menu gốc của bạn
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Đăng xuất",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: SearchBarWidget( // Giữ nguyên SearchBar
              initialText: _searchQuery,
              onSearch: _performSearch,
              onClear: () {
                _performSearch('');
              },
            ),
            leading: (ModalRoute.of(context)?.isFirst ?? false)
                ? null  
                : const BackButton(),  
            actions: combinedActions,  
          ),
          floatingActionButton:
              widget.floatingActionButton ??
              FloatingActionButton(
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
                child: const Icon(Icons.menu),
              ),
          body: widget.child,
        );
      },
    );
  }

  List<Widget> _buildMenuGroups(BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < _orderMenuGroups.length; i++) {
      if (i > 0) {
        widgets.add(const Divider());
      }
      for (var item in _orderMenuGroups[i]) {
        widgets.add(
          ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: item['color'] as Color,
            ),
            title: Text(item['title'] as String),
            onTap: () {
              Navigator.pop(context);
              _searchQuery = '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderListScreen(
                    statusIds:
                        item['statusIds'] != null &&
                                item['statusIds'].length > 0
                            ? item['statusIds'] as List<int>
                            : null,
                    title: item['title'] as String,
                    searchQuery: null,
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return widgets;
  }
}