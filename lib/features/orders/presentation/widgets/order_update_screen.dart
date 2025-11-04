import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import thư viện dotenv
import 'package:huystore/core/utils/enum_utils.dart'; // Đảm bảo đường dẫn này đúng
import 'package:huystore/core/utils/format_utils.dart';
import 'package:huystore/core/utils/helper.dart';
import 'package:huystore/features/orders/data/models/combo_model.dart';
import 'package:huystore/features/orders/presentation/widgets/meedia_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huystore/features/orders/data/models/order_model.dart'; // Đảm bảo đường dẫn này đúng
import 'package:huystore/features/orders/data/services/order_service.dart'; // Đảm bảo đường dẫn này đúng
import 'package:huystore/features/orders/data/models/bank_account_model.dart'; // mới: model tài khoản
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class OrderUpdateScreen extends StatefulWidget {
  final int orderId;
  final String? orderCode;
  const OrderUpdateScreen({Key? key, required this.orderId, this.orderCode})
    : super(key: key);
  @override
  State<OrderUpdateScreen> createState() => _OrderUpdateScreenState();
}

class _OrderUpdateScreenState extends State<OrderUpdateScreen> {
  final OrderService _orderService = OrderService();
  final ImagePicker _picker = ImagePicker();
  OrderModel? _order;
  bool _loading = false;
  bool _refreshing = false;
  late List<ComboModel> _orderStatuses = [];
  ComboModel? _selectedOrderStatus;
  final String _fileUrlBase = dotenv.env['FILE_URL'] ?? "";
  BankAccountModel? _bankInfo;
  bool _loadingBankInfo = false;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadOrder(initial: true);
    _fetchBankAccount();
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
      final OrderModel order = await _orderService.getOrderById(widget.orderId);
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

  // ========== BỔ SUNG: LẤY THÔNG TIN TÀI KHOẢN NGÂN HÀNG =============
  Future<void> _fetchBankAccount() async {
    setState(() => _loadingBankInfo = true);
    try {
      final BankAccountModel info = await _orderService.getBankAccountInfo();
      setState(() {
        _bankInfo = info;
      });
    } catch (e) {
      debugPrint("Failed to fetch bank account: $e");
    } finally {
      setState(() => _loadingBankInfo = false);
    }
  }

  // =========================
  // TOGGLE PAYMENT STATUS (gọi API) - sửa để chỉ set khi server OK
  // =========================
  Future<void> _togglePaymentStatus() async {
    if (_order == null) return;
    if (_refreshing) return;
    final int current = _order!.paymentStatus ?? 1;
    final int newStatus = current == 1 ? 2 : 1;
    final Map<String, dynamic> updateData = {
      'CreatedBy': _order!.createdBy,
      'StatusId': newStatus,
      'Code': _order!.code,
      'Id': _order!.id,
      'CustomerId': _order!.customerId,
    };
    try {
      setState(() => _refreshing = true);
      await _orderService.updateOrderPaymentStatus(_order!.id!, updateData);

      setState(() {
        _order!.paymentStatus = newStatus;
      });
      _showSnack("Cập nhật trạng thái thanh toán thành công");
    } catch (e) {
      _showSnack("Lỗi cập nhật thanh toán: $e");
    } finally {
      setState(() => _refreshing = false);
    }
  }

  // Show QR Modal
  Future<void> _showPaymentQrModal() async {
    if (_bankInfo == null || _order == null) {
      _showSnack("Không có thông tin tài khoản ngân hàng hoặc đơn hàng");
      return;
    }

    final int amount = (_order!.totalPrice ?? 0).toInt();
    final String addInfo = "Thanh toan don hang: ${_order!.code ?? _order!.id}";
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
                              // share link ảnh QR
                              await Share.share(
                                qrUrl,
                                subject: "QR Thanh toán đơn: ${_order!.id}",
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              child: const Text(
                                "Đã chuyển - Xác nhận thanh toán",
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await _confirmPaidByUser();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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

  // Khi user click "Đã chuyển - Xác nhận thanh toán" => gọi API xác nhận (update trạng thái)
  Future<void> _confirmPaidByUser() async {
    if (_order == null) return;
    if (_refreshing) return;

    try {
      setState(() => _refreshing = true);
      // gọi API mark paid: orderService cần có method updateOrderPaymentStatus(orderId, payload)
      await _orderService.updateOrderPaymentStatus(_order!.id!, {
        'paymentStatus': 2,
      });
      setState(() {
        _order!.paymentStatus = 2;
      });
      _showSnack("Xác nhận thanh toán thành công");
    } catch (e) {
      _showSnack("Xác nhận thanh toán thất bại: $e");
    } finally {
      setState(() => _refreshing = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<File?> _pickImage({bool fromCamera = false}) async {
    final XFile? x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    return x != null ? File(x.path) : null;
  }

  Future<File?> _pickVideo({bool fromCamera = false}) async {
    final XFile? x = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    return x != null ? File(x.path) : null;
  }

  Future<void> _uploadMediaForOrder({
    required int detailId,
    required int stepId,
    required String type,
  }) async {
    if (_order == null) return;
    File? f;
    if (type == "image") {
      f = await _pickImage(fromCamera: true);
      f ??= await _pickImage(fromCamera: false);
    } else {
      f = await _pickVideo(fromCamera: true);
      f ??= await _pickVideo(fromCamera: false);
    }
    if (f == null) return;

    try {
      setState(() => _refreshing = true);

      final apiResponseR = await _orderService.uploadOrderMedia(
        orderId: _order!.id!,
        orderDetailId: detailId,
        orderStepId: stepId,
        file: f,
        fileType: type,
        description: type == "image" ? "Ảnh minh chứng" : "Video minh chứng",
      );
      final apiResponse = apiResponseR.data;
      if (apiResponse['statusCode'] == 200) {
        final dynamic rawMediaData = apiResponse['data'];

        RepairMediaModel? newMedia;
        if (rawMediaData != null && rawMediaData is Map<String, dynamic>) {
          try {
            newMedia = RepairMediaModel.fromJson(rawMediaData);
          } catch (e) {
            print("Lỗi khi parse RepairMediaModel từ dữ liệu API: $e");
            _showSnack("Lỗi xử lý dữ liệu ảnh/video từ máy chủ.");
            newMedia = null;
          }
        } else {
          print("Dữ liệu media từ API không hợp lệ hoặc null.");
          _showSnack("Dữ liệu ảnh/video trả về không hợp lệ.");
        }

        if (newMedia != null) {
          setState(() {
            final String finalFileUrl = Helper.normalizeFileUrl(
              newMedia!.fileUrl,
            );
            final RepairMediaModel fullUrlMedia = newMedia!.copyWith(
              fileUrl: finalFileUrl,
            );

            if (detailId == 0 && stepId == 0) {
              _order!.medias.add(fullUrlMedia);
            } else {
              final detail = _order!.details.firstWhereOrNull(
                (d) => d.id == detailId,
              );

              if (detail != null && stepId == 0) {
                detail.medias.add(fullUrlMedia);
              } else if (detail != null && stepId != 0) {
                final step = detail.steps.firstWhereOrNull(
                  (s) => s.id == stepId,
                );
                if (step != null) {
                  step.medias.add(fullUrlMedia);
                }
              }
            }
          });
          _showSnack("Upload $type thành công");
        }
      } else {
        _showSnack(
          "Upload thất bại: ${apiResponse['message'] ?? 'Lỗi không xác định'}",
        );
      }
    } catch (e) {
      _showSnack("Upload thất bại: $e");
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _toggleStep({
    required int detailIndex,
    required int stepIndex,
    required bool checked,
  }) async {
    if (_order == null) return;
    final detail = _order!.details[detailIndex];
    final step = detail.steps[stepIndex];

    final newStatus = checked
        ? ProcessingStatus.Finished.value
        : ProcessingStatus.Unfinished.value;

    try {
      setState(() => _refreshing = true);

      await _orderService.updateOrderStepStatus(step.id!, newStatus);

      setState(() {
        step.statusId = newStatus;
      });

      final bool detailNowCompleted = detail.steps.every(Helper.isStepFinished);
      if (detailNowCompleted &&
          (detail.statusId != ProcessingStatus.Finished.value)) {
        await _orderService.updateOrderDetailStatus(
          detail.id!,
          ProcessingStatus.Finished.value,
        );
        setState(() {
          detail.statusId = ProcessingStatus.Finished.value;
        });
        _showSnack("Chi tiết #${detail.id} đã hoàn thành");
      }
    } catch (e) {
      _showSnack("Cập nhật step lỗi: $e");
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _completeOrder() async {
    if (_order == null) return;
    try {
      setState(() => _refreshing = true);
      await _orderService.updateOrderStatus(
        _order!.id!,
        OrderStatusId.completedDelivered.id,
        _order!.code ?? "",
        _order!.customerId ?? 0,
      );
      setState(() {
        _order!.statusId = OrderStatusId.completedDelivered.id;
        _selectedOrderStatus = _orderService.findById(
          "OrdersStatus",
          OrderStatusId.completedDelivered.id,
        );
      });
      _showSnack("Đơn đã được cập nhật trạng thái hoàn tất");
    } catch (e) {
      _showSnack("Cập nhật đơn lỗi: $e");
    } finally {
      setState(() => _refreshing = false);
    }
  }

  /**
 * 
 */
  Future<void> _saveOrderStatus() async {
    if (_order == null || _selectedOrderStatus == null) return;
    try {
      setState(() => _refreshing = true);
      await _orderService.updateOrderStatus(
        _order!.id!,
        _selectedOrderStatus!.id,
        _order!.code ?? "",
        _order!.customerId ?? 0,
      );
      setState(() {
        _order!.statusId = _selectedOrderStatus!.id;
      });
      _showSnack("Cập nhật trạng thái đơn thành công");
    } catch (e) {
      _showSnack("Cập nhật trạng thái lỗi: $e");
    } finally {
      setState(() => _refreshing = false);
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
    // Kiểm tra xem có nên hiển thị nút QR không
    final bool showQrButton =
        (_bankInfo != null && (order?.paymentStatus ?? 1) == 1);

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
            onPressed: _refreshing ? null : () => _loadOrder(),
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
                                  onPressed: _refreshing
                                      ? null
                                      : _togglePaymentStatus,
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
                          const SizedBox(height: 3),
                          const Divider(),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                MediaSection(
                                  medias: order.medias,
                                  onUploadImage: () => _uploadMediaForOrder(
                                    detailId: 0,
                                    stepId: 0,
                                    type: "image",
                                  ),
                                  onUploadVideo: () => _uploadMediaForOrder(
                                    detailId: 0,
                                    stepId: 0,
                                    type: "video",
                                  ),
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
                      final p = Helper.progress(order);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tiến độ xử lý: ${(Helper.countFinishedSteps(order))}/${Helper.countTotalSteps(order)} bước",
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
                            padding: const EdgeInsets.all(8),
                            child: MediaSection(
                              medias: detail.medias,
                              onUploadImage: () => _uploadMediaForOrder(
                                detailId: detail.id!,
                                stepId: 0,
                                type: "image",
                              ),
                              onUploadVideo: () => _uploadMediaForOrder(
                                detailId: detail.id!,
                                stepId: 0,
                                type: "video",
                              ),
                              onMediaTap: _showMediaViewer,
                            ),
                          ),
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
                                      // Loại bỏ viền mặc định của Step
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
                                        CheckboxListTile(
                                          contentPadding: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          title: const Text("Đã hoàn thành"),
                                          value: isStepFinished,
                                          onChanged: (val) {
                                            if (val == null) return;
                                            _toggleStep(
                                              detailIndex: detailIndex,
                                              stepIndex: stepIndex,
                                              checked: val,
                                            );
                                          },
                                        ),
                                        MediaSection(
                                          medias: step.medias,
                                          onUploadImage: () =>
                                              _uploadMediaForOrder(
                                                detailId: detail.id!,
                                                stepId: step.id!,
                                                type: "image",
                                              ),
                                          onUploadVideo: () =>
                                              _uploadMediaForOrder(
                                                detailId: detail.id!,
                                                stepId: step.id!,
                                                type: "video",
                                              ),
                                          onMediaTap: _showMediaViewer,
                                        ),
                                        const SizedBox(height: 8),
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

      // =========== BOTTOM NAVIGATION BAR ===========
      // ... (các phần trên của build method)
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
                      child: Builder(
                        builder: (context) {
                          final bool isReadOnly = order!.statusId == 13;
                          final Color backgroundColor =
                              Helper.getStatusDropdownColor(
                                _selectedOrderStatus,
                              );
                          final Color borderColor = Helper.statusChipColor(
                            _selectedOrderStatus,
                          ).withOpacity(0.8);
                          final Color textColor = Helper.statusChipColor(
                            _selectedOrderStatus,
                          );

                          if (isReadOnly) {
                            return Container(
                              height: 52, 
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ), // Giảm vertical padding
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color:
                                    backgroundColor, // MÀU NỀN THEO TRẠNG THÁI
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _selectedOrderStatus?.name ??
                                    "Trạng thái đơn hàng",
                                style: TextStyle(
                                  color: textColor, // MÀU CHỮ THEO TRẠNG THÁI
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          } else { 
                            return Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ComboModel>(
                                  isExpanded: true,
                                  value: _selectedOrderStatus,
                                  hint: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Trạng thái đơn hàng",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: _orderStatuses.map((status) {
                                    return DropdownMenuItem<ComboModel>(
                                      value: status,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Text(status.name),
                                      ),
                                    );
                                  }).toList(), 
                                  onChanged: (v) => setState(() {
                                    _selectedOrderStatus = v;
                                  }),
                                  icon: const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.arrow_drop_down),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ), 
                    // CÁC NÚT HÀNH ĐỘNG
                    const SizedBox(width: 8), 
                    if (order!.statusId != 13) // Ẩn nếu là trạng thái Hoàn thành
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                        ),
                        onPressed: _refreshing ? null : _saveOrderStatus,
                        child: _refreshing
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 34),
                      ),

                    if (order!.statusId != 13)  
                      const SizedBox(width: 8), 
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            order.statusId !=
                                OrderStatusId.completedDelivered.id
                            ? Colors.green
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero, // Để nút vừa với icon,
                      ),
                      onPressed:
                          !_refreshing &&
                              order.statusId !=
                                  OrderStatusId.completedDelivered.id
                          ? _completeOrder
                          : null,
                      child: const Icon(Icons.check_circle, size: 34),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
