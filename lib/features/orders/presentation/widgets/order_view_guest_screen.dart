import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import thư viện dotenv
import 'package:huystore/core/utils/enum_utils.dart'; // Đảm bảo đường dẫn này đúng
import 'package:huystore/core/utils/format_utils.dart';
import 'package:huystore/core/utils/helper.dart';
import 'package:huystore/features/orders/data/models/combo_model.dart';
import 'package:huystore/features/orders/data/models/order_full_model.dart';
import 'package:huystore/features/orders/presentation/widgets/meedia_section.dart';
import 'package:huystore/features/orders/presentation/widgets/meedia_section_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huystore/features/orders/data/models/order_model.dart' hide RepairMediaModel; // Đảm bảo đường dẫn này đúng
import 'package:huystore/features/orders/data/services/order_service.dart'; // Đảm bảo đường dẫn này đúng
import 'package:huystore/features/orders/data/models/bank_account_model.dart'; // mới: model tài khoản
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

 

class OrderDetailViewScreen extends StatefulWidget {
  final int orderId;
  final String? orderCode;
  const OrderDetailViewScreen({Key? key, required this.orderId, this.orderCode})
      : super(key: key);
  @override
  State<OrderDetailViewScreen> createState() => _OrderDetailViewScreenState();
}

class _OrderDetailViewScreenState extends State<OrderDetailViewScreen> {
  final OrderService _orderService = OrderService();

  OrderFullModel? _order;
  bool _loading = false;
  bool _refreshing = false;
  late List<ComboModel> _orderStatuses = [];
  ComboModel? _selectedOrderStatus;
  final String _fileUrlBase = dotenv.env['FILE_URL'] ?? "";
  ShopBankInfoModel? _bankInfo;
  bool _loadingBankInfo = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadOrder(initial: true);
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      _orderStatuses = await _orderService.getCombo("OrdersStatus");
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadOrder({bool initial = false}) async {
    if (initial) {
      setState(() => _loading = true);
    } else {
      setState(() => _refreshing = true);
    }
    try {
      final OrderFullModel order = await _orderService.getOrderDetail(
            widget.orderId,
            widget.orderCode!
          );

      order.medias = order.medias
          .map((m) => m.copyWith(fileUrl: Helper.normalizeFileUrl(m.fileUrl)))
          .toList();
      order.details.forEach((d) {
        d.medias = d.medias
            .map((m) => m.copyWith(fileUrl: Helper.normalizeFileUrl(m.fileUrl)))
            .toList();
        d.steps.forEach((s) {
          s.medias = s.medias
              .map(
                (m) => m.copyWith(fileUrl: Helper.normalizeFileUrl(m.fileUrl)),
              )
              .toList();
        });
      });
      if (order.paymentStatus == null) {
        order.paymentStatus = 1;
      }

      setState(() {
        _order = order;
        _selectedOrderStatus = _orderService.findById(
          "OrdersStatus",
          order.statusId!,
        );
        _bankInfo = order.shopBankInfo;
      });
    } catch (e) {
      _showSnack("Lỗi tải đơn: $e");
    } finally {
      if (initial) {
        setState(() => _loading = false);
      } else {
        setState(() => _refreshing = false);
      }
    }
  }
   
  // Show QR Modal (GIỮ NGUYÊN)
  Future<void> _showPaymentQrModal() async {
    if (_bankInfo == null || _order == null) {
      _showSnack("Không có thông tin tài khoản ngân hàng hoặc đơn hàng");
      return;
    }

    final int amount = (_order!.totalPrice ?? 0).toInt();
    final String addInfo = "Thanh toán đơn hàng: ${_order!.code ?? _order!.id}";
    final String qrUrl = Helper.buildVietQrUrl(
      bankId: _bankInfo!.bankId,
      accountNo: _bankInfo!.accountNo,
      receiverName: _bankInfo!.receiverName,
      amount: amount,
      addInfo: addInfo,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setStateModal) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Quét QR để thanh toán",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Show bank info
                      ListTile(
                        leading: const Icon(Icons.account_balance),
                        title: Text(
                          "${_bankInfo!.bankName} • ${_bankInfo!.accountNo}",
                        ),
                        subtitle: Text(
                          "Người nhận: ${_bankInfo!.receiverName}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _bankInfo!.accountNo),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Số tài khoản đã copy"),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // QR image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          qrUrl,
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Container(
                            width: 260,
                            height: 260,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error_outline),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Số tiền: ${FormatUtils.formatCurrency(amount)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text("Nội dung: $addInfo"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text("Mở (quét/ứng dụng)"),
                              onPressed: () async {
                                final uri = Uri.tryParse(qrUrl);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Không thể mở link QR"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text("Chia sẻ"),
                            onPressed: () async {
                              await Share.share(
                                qrUrl,
                                subject: "QR Thanh toán đơn: ${_order!.id}",
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
// ============== MỚI: Trình xem Media sang PageView (Vuốt ngang) có Counter 1/N ==============
  void _showMediaViewer(
    BuildContext _,
    List<RepairMediaModel> medias,
    int initialIndex,
  ) {
    // 1. Lọc chỉ lấy các media có URL hợp lệ để đưa vào trình xem
    final viewableMedias = medias
        .where((m) => m.fileUrl != null && m.fileUrl!.isNotEmpty)
        .toList();

    if (viewableMedias.isEmpty) return;

    // 2. Tìm index của item đầu tiên trong danh sách viewable
    final int initialPage = viewableMedias.indexWhere(
      (m) => m.id == medias[initialIndex].id,
    );

    final controller = PageController(
      initialPage: initialPage >= 0 ? initialPage : 0,
    );

    // Biến local theo dõi index hiện tại, được cập nhật qua setStateModal
    int currentPage = initialPage >= 0 ? initialPage : 0;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: viewableMedias.length,
                    // Sử dụng onPageChanged để cập nhật index và kích hoạt rebuild
                    onPageChanged: (index) {
                      setStateModal(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = viewableMedias[index];
                      final isImage = media.fileType == 'image';

                      if (isImage) {
                        // Trình xem ảnh có thể phóng to (zoom)
                        return InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: media.fileUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Trình xem Video: Hiển thị Placeholder và nút Mở Video
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  color: Colors.white70,
                                  size: 100,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Tệp Video không thể phát nhúng",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Vui lòng mở bằng ứng dụng bên ngoài",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text("Mở Video"),
                                  onPressed: () async {
                                    final uri = Uri.tryParse(media.fileUrl!);
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Không thể mở video URL",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  // ====== HIỂN THỊ SỐ THỨ TỰ (1/N) ======
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          // Số hiện tại là currentPage + 1
                          "${currentPage + 1}/${viewableMedias.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nút đóng (X)
                  Positioned(
                    top: 30,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
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
  // ============== Hết phần Trình xem Media ==============

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = _order;
    final bool showQrButton =
        (!_loadingBankInfo &&
        _bankInfo != null &&
        (order?.paymentStatus ?? 1) == 1);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn #${order?.code ?? widget.orderId}"),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
                : const Icon(Icons.refresh),
            onPressed: () => _loadOrder(),
            tooltip: "Tải lại",
          ),
        ],
      ),
      body: order == null
          ? const Center(child: Text("Không có dữ liệu đơn"))
          : RefreshIndicator(
              onRefresh: () => _loadOrder(),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // CARD 1: Thông tin chung đơn hàng + Nút thanh toán
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.receipt_long, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customerName ?? '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Ngày tạo: ${FormatUtils.formatDateTime(order.createdAt)}",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                ActionChip(
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 3,
                                  ),
                                  label: Text(
                                    Helper.paymentStatusText(
                                      order.paymentStatus,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  backgroundColor: Helper.paymentStatusColor(
                                    order.paymentStatus,
                                  ),
                                  // GIỮ MÀU: Đặt hàm không null.
                                  onPressed:
                                      () async {}, // Vẫn null nếu đang refresh
                                ),
                                if (showQrButton)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: _showPaymentQrModal,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Thanh toán",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ), 
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Tệp tin chung (Sau Thanh toán):",
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                         const SizedBox(height: 3),
                          const Divider(),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                MediaViewSection(
                                  medias: order.medias, 
                                  onMediaTap: _showMediaViewer,
                                  axisAlignment: MainAxisAlignment.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Builder(
                    builder: (_) {
                      final p = Helper.progressGuest(order);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tiến độ xử lý: ${(Helper.countGuestFinishedSteps(order))}/${Helper.countGuestTotalSteps(order)} bước",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(value: p),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    "Chi tiết đơn",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(order.details.length, (detailIndex) {
                    final detail = order.details[detailIndex];
                    final bool isFinished = Helper.isDetailFinished(detail);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                detail.serviceName ??
                                    detail.description ??
                                    "Chi tiết #${detailIndex + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Chip(
                              padding: const EdgeInsets.fromLTRB(2, 5, 2, 5),
                              label: Text(
                                isFinished ? "✅ Hoàn thành" : "⏳ Chưa xong",
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: isFinished
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ],
                        ),
                        children: [ 
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Tệp tin Chi tiết Sản phẩm/Dịch vụ:",
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                MediaViewSection(
                                  medias: detail.medias, 
                                  onMediaTap:_showMediaViewer
                                ),
                              ],
                            ),
                          ),
                          // =======================================================

                          if (detail.steps != null && detail.steps!.isNotEmpty)
                            ...List.generate(detail.steps!.length, (stepIndex) {
                              final step = detail.steps![stepIndex];
                              final isStepFinished = Helper.isStepFinished(
                                step,
                              );

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    indent: 16,
                                    endIndent: 16,
                                    color: Colors.black12,
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      4,
                                      4,
                                      4,
                                    ),
                                    child: ExpansionTile(
                                      shape: const Border(),
                                      collapsedShape: const Border(),

                                      tilePadding: const EdgeInsets.only(
                                        left: 8,
                                      ),
                                      title: Text(
                                        step.name ?? "Bước ${stepIndex + 1}",
                                      ),
                                      subtitle: step.description != null
                                          ? Text(step.description!)
                                          : null,
                                      children: [ 
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Tệp tin Bước thực hiện:",
                                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              MediaViewSection(
                                                medias: step.medias, 
                                                onMediaTap: _showMediaViewer,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // =======================================================
                                        CheckboxListTile(
                                          contentPadding: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          title: const Text("Đã hoàn thành"),
                                          value: isStepFinished,
                                          onChanged: (val) {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
      bottomNavigationBar: order == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, -2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0, // Thay đổi padding để khớp chiều cao
                        ),
                        decoration: BoxDecoration(
                          color: Helper.getStatusDropdownColor(
                            _selectedOrderStatus,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Helper.statusChipColor(
                              _selectedOrderStatus,
                            ).withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.statusName??"",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Helper.statusChipColor(
                              _selectedOrderStatus,
                            ),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}