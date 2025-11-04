import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:huystore/core/layouts/main_layout.dart';
import 'package:huystore/core/utils/format_utils.dart';
import 'package:huystore/core/utils/helper.dart';
import 'package:huystore/features/orders/data/models/order_model.dart';
import 'package:huystore/features/orders/data/services/order_service.dart';
import 'package:huystore/features/orders/presentation/widgets/order_update_screen.dart';
import 'package:huystore/features/orders/presentation/pages/order_detail.dart';

class OrderListScreen extends StatefulWidget {
  final List<int>? statusIds;
  final String title;
  final String? searchQuery;

  const OrderListScreen({
    Key? key,
    this.statusIds,
    required this.title,
    this.searchQuery,
  }) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _orderService = OrderService();
  static const int _pageSize = 10;
  static const int _deliveryStatusId = 12;

  bool _loading = false;
  bool _isFetchingMore = false;
  String? _error;
  List<OrderModel> _orders = [];
  int _skip = 0;
  int _totalRows = 0; // tổng record từ API

  // Bluetooth state local
  bool _btConnected = false;
  BluetoothDevice? _btDevice;
  StreamSubscription<List<BluetoothDevice>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _fetchOrders(isFirstLoad: true);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool statusIdsChanged =
        (oldWidget.statusIds?.length != widget.statusIds?.length) ||
        (oldWidget.statusIds != null &&
            widget.statusIds != null &&
            !_listEquals(oldWidget.statusIds!, widget.statusIds!));

    bool searchQueryChanged = oldWidget.searchQuery != widget.searchQuery;

    if (statusIdsChanged || searchQueryChanged) {
      _fetchOrders(isFirstLoad: true);
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
      if (widget.searchQuery != null &&
          widget.searchQuery.toString().length > 0) {
        final OrderListResponse resp = await _orderService.searchOrders(
          searchQuery: widget.searchQuery.toString()??"test",
          skip: skip,
          take: _pageSize,
        );

        final List<OrderModel> newOrders = resp.data;
        setState(() {
          _orders.addAll(newOrders);
          _skip += newOrders.length;
          _totalRows = resp.totalRows;
        });
      } else {
        final OrderListResponse resp = await _orderService.getOrders(
          statusIds: widget.statusIds ?? [],
          skip: skip,
          take: _pageSize,
        );

        final List<OrderModel> newOrders = resp.data;
        setState(() {
          _orders.addAll(newOrders);
          _skip += newOrders.length;
          _totalRows = resp.totalRows;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _isFetchingMore = false;
      });
    }
  }

  // Show dialog to pick device from the scanned list
  Future<BluetoothDevice?> _showDevicePickDialog(
    List<BluetoothDevice> devices,
  ) async {
    return showDialog<BluetoothDevice>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Chọn máy in Bluetooth'),
          content: SizedBox(
            width: double.maxFinite,
            child: devices.isEmpty
                ? const Text('Không tìm thấy thiết bị')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final d = devices[i];
                      return ListTile(
                        title: Text(d.name ?? 'Không tên'),
                        subtitle: Text(d.address ?? ''),
                        onTap: () => Navigator.of(ctx).pop(d),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Huỷ'),
            ),
          ],
        );
      },
    );
  }

  /// =====================
  /// PRINT: scan -> pick -> connect -> write -> disconnect
  /// =====================
  Future<void> _printOrderList() async {
    if (_orders.isEmpty || _loading) return;
    setState(() => _loading = true);

    try {
      // 1) Start scan
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 4));

      // collect scan results for given timeout
      List<BluetoothDevice> devices = [];
      _scanSub?.cancel();
      final completer = Completer<List<BluetoothDevice>>();
      _scanSub = BluetoothPrintPlus.scanResults.listen((list) {
        devices = list;
      });

      // wait the scan duration (startScan already has timeout, but we also wait here)
      await Future.delayed(const Duration(seconds: 4));
      await _scanSub?.cancel();
      _scanSub = null;

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy máy in Bluetooth')),
        );
        return;
      }

      // 2) show picker (user can choose) - if user cancels, return
      final BluetoothDevice? picked = await _showDevicePickDialog(devices);
      if (picked == null) {
        return;
      }

      // 3) Connect (static API)
      await BluetoothPrintPlus.connect(picked);
      _btDevice = picked;
      _btConnected = true;
      setState(() {});

      // 4) Build receipt text (plain text). You can customize as needed.
      final StringBuffer sb = StringBuffer();
      sb.writeln('DANH SÁCH ĐƠN HÀNG');
      sb.writeln('-------------------------------');

      for (int i = 0; i < _orders.length; i++) {
        final o = _orders[i];
        sb.writeln('${i + 1}. Mã: ${o.code ?? ""}');
        sb.writeln('Khách: ${o.customerName ?? ""}');
        if (o.phoneNumber != null && o.phoneNumber!.isNotEmpty) {
          sb.writeln('SĐT: ${o.phoneNumber!}');
        }
        if (o.customerAddress != null && o.customerAddress!.isNotEmpty) {
          sb.writeln('Địa chỉ: ${o.customerAddress!}');
        }
        sb.writeln('Tổng: ${FormatUtils.formatCurrency(o.totalPrice)}');
        sb.writeln(''); // blank line
        sb.writeln('-------------------------------');
      }

      sb.writeln('');
      sb.writeln('Tổng đơn: ${_orders.length}');
      sb.writeln('In lúc: ${FormatUtils.formatDateTime(DateTime.now())}');
      sb.writeln('Cảm ơn!');
      final Uint8List bytes = Uint8List.fromList(
        utf8.encode(sb.toString() + '\n\n\n'),
      );

      await BluetoothPrintPlus.write(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi ${_orders.length} đơn hàng tới máy in')),
      );
    } catch (e, st) {
      debugPrint('Print error: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi in: ${e.toString()}')));
    } finally {
      // disconnect if connected
      try {
        if (_btConnected) {
          await BluetoothPrintPlus.disconnect();
        }
      } catch (_) {}
      _btConnected = false;
      _btDevice = null;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeliveryPage =
        widget.statusIds != null &&
        widget.statusIds!.contains(_deliveryStatusId);

    return MainLayout(
      title: widget.title,
      actions: isDeliveryPage
          ? [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _orders.isEmpty || _loading ? null : _printOrderList,
                tooltip: 'In toàn bộ danh sách giao hàng',
              ),
            ]
          : null,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Lỗi: $_error"))
          : _orders.isEmpty
          ? const Center(child: Text("Không có đơn hàng"))
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchOrders(isFirstLoad: true);
              },
              child: ListView.builder(
                itemCount: _orders.length + 1,
                itemBuilder: (context, index) {
                  if (index == _orders.length) {
                    // item cuối: hiển thị nút Xem thêm hoặc Hết dữ liệu
                    if (_orders.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final bool showLoadMore = _skip < _totalRows;

                    if (!showLoadMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text("")),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _isFetchingMore
                                ? null
                                : () => _fetchOrders(),
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
                  final isDeadlineSoon = Helper.isNearDeadline(
                    order.desiredTime,
                  );
                  // Kiểm tra đơn hàng có phải trạng thái Đang Giao Trả (12) không
                  final bool isDeliveryStatus =
                      order.statusId == _deliveryStatusId;
                  // Lấy màu sắc cho CHIP TRẠNG THÁI ĐƠN HÀNG (SỬ DỤNG HELPER)
                  final statusColor = Helper.getStatusColor(
                    order.statusId ?? 0,
                  );

                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(order.code ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Khách: ${order.customerName ?? ""}"),
                        Text("SĐT: ${order.phoneNumber ?? ""}"),
                        Text("Cửa hàng: ${order.shopName ?? ""}"),
                        if (isDeliveryStatus &&
                            order.customerAddress != null &&
                            order.customerAddress!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Địa chỉ: ${order.customerAddress!}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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
                            color: isDeadlineSoon
                                ? Colors.red
                                : Colors.grey[700],
                            fontWeight: isDeadlineSoon
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (order.statusId != null && order.statusId! < 8) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateOrderScreen(orderId: order.id),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderUpdateScreen(
                              orderId: order.id ?? 0,
                              orderCode: "",
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
