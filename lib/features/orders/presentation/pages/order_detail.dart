import 'dart:io';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/core/layouts/searchable_dropdown.dart';
import 'package:huystore/core/services/token_storage.dart';
import 'package:huystore/core/utils/code_generate_utils.dart';
import 'package:huystore/core/utils/format_utils.dart';
import 'package:huystore/features/orders/data/models/account_model.dart';
import 'package:huystore/features/orders/data/models/combo_model.dart';
import 'package:huystore/features/orders/data/models/customer_model.dart';
import 'package:huystore/features/orders/data/models/service_model.dart';
import 'package:huystore/features/orders/data/services/order_service.dart';
import 'package:huystore/features/orders/presentation/widgets/quantity_input.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:huystore/features/orders/presentation/widgets/meedia_section.dart';
import 'package:huystore/features/orders/data/models/order_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:huystore/core/utils/helper.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

class CreateOrderScreen extends StatefulWidget {
  final int? orderId;
  const CreateOrderScreen({super.key, this.orderId});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final OrderService _orderService = OrderService();
  final ImagePicker _picker = ImagePicker();
  OrderModel? _order;
  bool _refreshing = false;
  late List<AccountModel> _staffs = [];
  late Future<void> _orderDetailFuture;
  late List<ComboModel> _shops = [];
  late List<ServiceModel> _allServices = [];
  late List<ComboModel> _orderStatuses = [];
  CustomerModel? _selectedCustomer;
  AccountModel? _selectedStaff;
  ComboModel? _selectedShop;
  final List<Map<String, dynamic>> _selectedServices = [];
  final _customerNameController = TextEditingController();
  final _orderCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _finishDateController = TextEditingController();
  final _shopController = TextEditingController();
  final _staffController = TextEditingController();
  // **FIX: Thiết lập giá trị ban đầu có ' đ'**
  final _extraCostController = TextEditingController(text: '0 đ');
  final TextEditingController _discountController = TextEditingController(
    text: '0 đ',
  );
  final _grandTotalController = TextEditingController();
  List<CustomerModel> _allCustomers = [];
  bool _isCustomerLoading = false;
  bool _isStaffLoading = false;
  bool _isShopLoading = false;
  bool _isServiceLoading = false;
  String _orderCode = "";
  String _customerCode = CodeGenerator.generateUniqueCode('KH');
  bool _isNewOrder = true;
  bool _isCreatingOrUpdating = false;
  ComboModel? _selectedOrderStatus;
  BluetoothDevice? _btDevice;
  bool _btConnected = false;
  StreamSubscription<List<BluetoothDevice>>? _scanSub;

  @override
  void initState() {
    super.initState();

    if (widget.orderId != null && widget.orderId! > 0) {
      _isNewOrder = false;
      _orderDetailFuture = _fetchOrderDetails(widget.orderId!);
    } else {
      _orderDetailFuture = _loadInitialData();
      _isNewOrder = true;
      _order = OrderModel(
        id: 0,
        medias: [],
        details: [],
        statusId: 0,
        customerId: 0,
      );
      // **FIX: Gọi _updateTotals() để grandTotalController có giá trị '0 đ' ban đầu**
      _updateTotals();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // **FIX LỖI FUTURE (await TokenStorage)**
      final shopCodeResult = await TokenStorage.getShopCode();
      String shopCode = shopCodeResult?.toString() ?? "HS";

      // **FIX: Cập nhật controller và code trong setState**
      setState(() {
        _orderCodeController.text = CodeGenerator.generateUniqueCode(
          shopCode + "DH",
        );
        _orderCode = _orderCodeController.text;
      });

      _shops = await _orderService.getCombo("Shops");
      _allServices = await _orderService.getServices();
      _orderStatuses = await _orderService.getCombo("OrdersStatus");
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      setState(() {
        _isShopLoading = false;
        _isServiceLoading = false;
      });
    }
  }

  Future<void> _fetchOrderDetails(int orderId) async {
    try {
      final order = await _orderService.getOrderById(orderId);
      if (order != null) {
        // Vẫn cần load các combo ban đầu
        await _loadInitialData();

        order.medias = order.medias
            .map((m) => m.copyWith(fileUrl: Helper.normalizeFileUrl(m.fileUrl)))
            .toList();

        setState(() {
          _order = order;
          _orderCode = order.code ?? '';
          _orderCodeController.text = _orderCode;

          _customerNameController.text = order.customerName ?? '';
          _customerCode = order.customerCode ?? '';
          _phoneNumberController.text = order.phoneNumber ?? '';
          _addressController.text = order.customerAddress ?? '';
          _descriptionController.text = order.description ?? '';
          _extraCostController.text =
              FormatUtils.formatNumber(order.extraFee ?? 0).toString() + ' đ';
          _discountController.text =
              FormatUtils.formatNumber(order.discountAmout ?? 0).toString() +
              ' đ';

          _finishDateController.text = order.desiredTime != null
              ? FormatUtils.formatDateTime(order.desiredTime)
              : "";
          _selectedOrderStatus = _orderStatuses.firstWhere(
            (status) => status.id == order.statusId,
            orElse: () => _orderStatuses.first,
          );
        });

        if (order.shopId != null) {
          _selectedShop = _shops.firstWhere(
            (s) => s.id == order.shopId,
            orElse: () =>
                ComboModel(id: order.shopId!, name: 'N/A', code: 'N/A'),
          );
          _shopController.text =
              "${_selectedShop?.code} - ${_selectedShop?.name}";
        }

        if (order.accountId != null && _selectedShop != null) {
          _staffs = await _orderService.getStaffs(_selectedShop!.id);
          if (mounted) {
            _selectedStaff = _staffs.firstWhere(
              (s) => s.id == order.accountId,
              orElse: () => AccountModel(id: order.accountId, fullName: 'N/A'),
            );
            _staffController.text = _selectedStaff?.fullName ?? '';
          }
        }
        if (order.customerId != null) {
          if (_allCustomers != null && _allCustomers.length > 0) {
            _selectedCustomer = _allCustomers.firstWhere(
              (s) => s.id == order.accountId,
              orElse: () =>
                  CustomerModel(id: order.customerId, fullName: 'N/A'),
            );
          }
          else{
            _selectedCustomer = new CustomerModel(id:order.customerId,fullName:order.customerName,address: order.customerAddress,code: order.customerCode);
          }
        }
        if (order.details != null) {
          _selectedServices.clear();
          for (var service in order.details!) {
            _selectedServices.add({
              'id': service.id,
              'serviceId': service.serviceId,
              'serviceName': service.serviceName,
              'unitPrice': service.unitPrice,
              'quantity': service.quantity,
              'description': service.description ?? '',
              'vatRate': service.vatRate,
            });
          }
        }
        // Bắt buộc gọi _updateTotals() sau khi load xong chi tiết dịch vụ
        _updateTotals();
      }
    } catch (e) {
      debugPrint("Error fetching order details: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _orderCodeController.dispose(); // Giữ controller này
    _phoneNumberController.dispose();
    _grandTotalController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _finishDateController.dispose();
    _shopController.dispose();
    _staffController.dispose();
    _extraCostController.dispose();
    _discountController.dispose();
    _scanSub?.cancel();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showMediaViewer(
    BuildContext context,
    List<RepairMediaModel> medias,
    int initialIndex,
  ) {
    if (medias.isEmpty) return;

    final controller = PageController(initialPage: initialIndex);
    int currentPage = initialIndex;

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
                    itemCount: medias.length,
                    onPageChanged: (index) {
                      setStateModal(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = medias[index];
                      final isImage = media.fileType == 'image';
                      final mediaUrl = media.fileUrl;

                      if (mediaUrl == null || mediaUrl.isEmpty) {
                        return const Center(
                          child: Text(
                            "Không tìm thấy đường dẫn media.",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      if (isImage) {
                        return InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: mediaUrl,
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
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text("Mở Video"),
                                  onPressed: () async {
                                    final uri = Uri.tryParse(mediaUrl);
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
                          "${currentPage + 1}/${medias.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

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

  void _handleMediaTap(
    BuildContext context,
    List<RepairMediaModel> medias,
    int initialIndex,
  ) {
    _showMediaViewer(context, medias, initialIndex);
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
    if (_order == null || _order!.id == 0) {
      _showSnack("Vui lòng tạo/cập nhật đơn hàng trước khi tải ảnh/video.");
      return;
    }
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

  // ============== END LOGIC MEDIA ==============
  Future<List<CustomerModel>> _loadCustomers(String pattern) async {
    if (_isCustomerLoading) return [];

    setState(() {
      _isCustomerLoading = true;
    });

    try {
      _allCustomers = await _orderService.getCustomers(
        skip: 0,
        take: 1000,
        searchTerm: "",
      );
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      setState(() {
        _isCustomerLoading = false;
      });
    }
    return _allCustomers;
  }

  Future<List<ServiceModel>> _loadServices(String pattern) async {
    return _allServices
        .where((s) => s.name!.toLowerCase().contains(pattern.toLowerCase()))
        .toList();
  }

  Future<List<AccountModel>> _loadStaffs(String pattern) async {
    if (_selectedShop == null) return [];
    if (_isStaffLoading) return [];

    setState(() {
      _isStaffLoading = true;
    });

    try {
      _staffs = await _orderService.getStaffs(_selectedShop!.id);
      return _staffs;
    } catch (e) {
      debugPrint('Error loading staffs: $e');
      return [];
    } finally {
      setState(() {
        _isStaffLoading = false;
      });
    }
  }

  Future<List<ComboModel>> _loadShops(String pattern) async {
    return _shops;
  }

  void _addService(ServiceModel service) {
    setState(() {
      final existingServiceIndex = _selectedServices.indexWhere(
        (item) => item['serviceId'] == service.serviceId,
      );

      if (existingServiceIndex != -1) {
        _selectedServices[existingServiceIndex]['quantity']++;
      } else {
        _selectedServices.add({
          'id': 0,
          'serviceId': service.serviceId,
          'serviceName': service.name,
          'unitPrice': service.basePrice,
          'quantity': 1,
          'description': '',
          'vatRate': service.vatRate,
        });
      }
      _updateTotals();
    });
  }

  void _removeService(int index) {
    setState(() {
      _selectedServices.removeAt(index);
      _updateTotals();
    });
  }

  void _updateServiceDetails(int index, String key, dynamic value) {
    setState(() {
      if (key == 'quantity') {
        int newQuantity = value as int;
        if (newQuantity < 1) {
          newQuantity = 1;
        }
        _selectedServices[index]['quantity'] = newQuantity;
      } else if (key == 'description') {
        _selectedServices[index]['description'] = value;
      }
      _updateTotals();
    });
  }

  // **FIX: Logic tính toán và thêm " đ"**
  void _updateTotals() {
    num serviceTotal = 0;
    for (var item in _selectedServices) {
      final unitPrice = item['unitPrice'] as num;
      final qty = item['quantity'] as int;
      final vat = item['vatRate'] as num;
      final itemTotal = (unitPrice * qty) + (unitPrice * qty * vat / 100);
      serviceTotal += itemTotal;
    }

    // **FIX: Làm sạch chuỗi (bỏ dấu chấm, phẩy và chữ " đ")**
    final extraCostString = _extraCostController.text.replaceAll(
      RegExp(r'[., đ]'),
      '',
    );
    final discountString = _discountController.text.replaceAll(
      RegExp(r'[., đ]'),
      '',
    );

    final extraCost = int.tryParse(extraCostString) ?? 0;
    final discount = int.tryParse(discountString) ?? 0;

    final grandTotal = serviceTotal + extraCost - discount;

    // **FIX: Đảm bảo controller được cập nhật trong setState và thêm ' đ'**
    setState(() {
      final formattedExtraCost = FormatUtils.formatNumber(extraCost) + ' đ';
      final formattedDiscount = FormatUtils.formatNumber(discount) + ' đ';
      final formattedGrandTotal = FormatUtils.formatNumber(grandTotal) + ' đ';

      // Cập nhật giá trị Controller (Phải làm thủ công vì không gọi setState)
      // Dùng value để không làm mất vị trí con trỏ (chỉ cập nhật nội dung)
      _extraCostController.value = _extraCostController.value.copyWith(
        text: formattedExtraCost,
        selection: TextSelection.collapsed(
          offset: formattedExtraCost.length - 2,
        ),
      );
      _discountController.value = _discountController.value.copyWith(
        text: formattedDiscount,
        selection: TextSelection.collapsed(
          offset: formattedDiscount.length - 2,
        ),
      );

      _grandTotalController.value = _grandTotalController.value.copyWith(
        text: formattedGrandTotal,
        selection: TextSelection.collapsed(
          offset: formattedGrandTotal.length,
        ), // Giữ con trỏ ở cuối
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _finishDateController.text = DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(finalDateTime);
        });
      }
    }
  }

  // HÀM HIỂN THỊ CHỌN MÁY IN
  Future<BluetoothDevice?> _showDevicePickDialog(
    List<BluetoothDevice> devices,
  ) async {
    return showDialog<BluetoothDevice?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn Máy In Bluetooth'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: devices.map((device) {
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.address),
                  onTap: () => Navigator.of(context).pop(device),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  /// IN MÃ QR CODE (ĐÃ SỬA DỤNG write(bytes))
  Future<void> _printQrCode(GlobalKey qrKey) async {
    if (_isCreatingOrUpdating || _refreshing || widget.orderId == null) return;

    setState(() => _refreshing = true);

    try {
      // 1) Chụp ảnh mã QR và lấy PNG bytes
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 4));
      List<BluetoothDevice> devices = [];
      _scanSub?.cancel();
      _scanSub = BluetoothPrintPlus.scanResults.listen((list) {
        devices = list;
      });

      await Future.delayed(const Duration(seconds: 4));
      await _scanSub?.cancel();
      _scanSub = null;

      if (devices.isEmpty) {
        _showSnack('Không tìm thấy máy in Bluetooth');
        return;
      }

      final BluetoothDevice? picked = await _showDevicePickDialog(devices);
      if (picked == null) {
        return;
      }

      await BluetoothPrintPlus.connect(picked);
      _btDevice = picked;
      _btConnected = true; 
      final StringBuffer sb = StringBuffer();
      sb.writeln('Mã Đơn Hàng: $_orderCode');
      sb.writeln('Quét QR để xem chi tiết:');
      sb.writeln('--------------------------------');

      // Gửi Text Header
      await BluetoothPrintPlus.write(
        Uint8List.fromList(utf8.encode(sb.toString())),
      );

      // Gửi raw PNG bytes (LƯU Ý: Cách này có thể không hoạt động trên tất cả các máy in nhiệt.
      // Để in hình ảnh đúng chuẩn ESC/POS, cần chuyển PNG sang lệnh ESC/POS.)
      await BluetoothPrintPlus.write(pngBytes);

      // Thêm dòng trống để đẩy giấy lên
      await BluetoothPrintPlus.write(Uint8List.fromList(utf8.encode('\n\n\n')));

      _showSnack('Đã gửi mã QR tới máy in');
    } catch (e, st) {
      debugPrint('Print QR error: $e\n$st');
      _showSnack('Lỗi khi in mã QR: ${e.toString()}');
    } finally {
      try {
        if (_btConnected) {
          await BluetoothPrintPlus.disconnect();
        }
      } catch (_) {}
      _btConnected = false;
      _btDevice = null;
      setState(() => _refreshing = false);
    }
  }

  // =========================================================================
  void _showQrCodeDialog() {
    if (widget.orderId == null || _orderCode.isEmpty) {
      _showSnack("Vui lòng tạo đơn hàng trước khi xem QR code.");
      return;
    }
    final GlobalKey _qrKey = GlobalKey();
    final String webUrl = dotenv.env['WebRunUrl'] ?? '';
    final String qrData =
        '$webUrl/orders/view-full-order/${widget.orderId}/$_orderCode';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mã QR Đơn hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quét mã QR để xem chi tiết đơn hàng:'),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _qrKey,
                child: SizedBox(
                  width: 200.0,
                  height: 200.0,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mã đơn hàng: $_orderCode',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            // NÚT IN MÃ QR CODE
            TextButton(
              onPressed: _refreshing
                  ? null
                  : () async {
                      Navigator.of(context).pop(); // Đóng dialog
                      await _printQrCode(_qrKey); // Gọi hàm in QR mới
                    },
              child: const Text('In mã QR'),
            ),
            // HÀM TẢI ẢNH QR (GIỮ NGUYÊN)
            TextButton(
              onPressed: () async {
                try {
                  RenderRepaintBoundary boundary =
                      _qrKey.currentContext!.findRenderObject()
                          as RenderRepaintBoundary;
                  var image = await boundary.toImage(pixelRatio: 3.0);
                  ByteData? byteData = await image.toByteData(
                    format: ImageByteFormat.png,
                  );
                  Uint8List pngBytes = byteData!.buffer.asUint8List();

                  // Lưu trực tiếp vào thư viện ảnh
                  final result = await ImageGallerySaverPlus.saveImage(
                    Uint8List.fromList(pngBytes),
                    name: 'QR_${_orderCode}',
                    isReturnImagePathOfIOS: true,
                  );

                  if (result['isSuccess'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu mã QR vào thư viện ảnh!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể lưu ảnh vào thư viện.'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi lưu ảnh: $e')),
                  );
                }
              },
              child: const Text('Tải ảnh QR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  bool _validateFields() {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng.')),
      );
      return false;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một dịch vụ.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _createOrUpdateOrder() async {
    if (!_validateFields()) {
      return;
    }

    if (_isNewOrder && _selectedOrderStatus == null) {
      final defaultStatus = _orderStatuses.firstWhere(
        (s) => s.id == 1,
        orElse: () => _orderStatuses.isNotEmpty
            ? _orderStatuses.first
            : ComboModel(id: 0, name: 'Lỗi', code: 'Lỗi'),
      );
      _selectedOrderStatus = defaultStatus;
      if (_selectedOrderStatus?.id == 0 && _orderStatuses.isNotEmpty) {
        _showSnack("Lỗi: Không tìm thấy trạng thái đơn hàng mặc định.");
        return;
      }
    }
    final extraFeeValue =
        int.tryParse(
          _extraCostController.text.replaceAll(RegExp(r'[., đ]'), ''),
        ) ??
        0;
    final discountFeeValue =
        int.tryParse(
          _discountController.text.replaceAll(RegExp(r'[., đ]'), ''),
        ) ??
        0;
    final grandTotalValue =
        int.tryParse(
          _grandTotalController.text.replaceAll(RegExp(r'[., đ]'), ''),
        ) ??
        0;

    final orderData = {
      "id": _isNewOrder ? 0 : widget.orderId,
      "createdAt": DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      ).format(DateTime.now()),
      "createdBy": 0,
      "code": _orderCode,
      "customerId": _selectedCustomer?.id ?? 0,
      "customerName": _customerNameController.text,
      "customerCode": _customerCode,
      "phoneNumber": _phoneNumberController.text,
      "customerAddress": _addressController.text,
      "shopId": _selectedShop?.id ?? 0,
      "accountId": _selectedStaff?.id ?? 0,
      "description": _descriptionController.text,
      "desiredTime": _finishDateController.text.isNotEmpty
          ? DateFormat(
              "dd/MM/yyyy' 'HH:mm",
            ).parse(_finishDateController.text).toUtc().toIso8601String()
          : null,
      "totalPrice": grandTotalValue, // Dùng giá trị đã được làm sạch
      "extraFee": extraFeeValue.toDouble(),
      "DiscountAmout": discountFeeValue.toDouble(),
      "details": _selectedServices,
      "statusId": _selectedOrderStatus?.id,
    };

    setState(() {
      _isCreatingOrUpdating = true;
    });

    try {
      final response = _isNewOrder
          ? await _orderService.createOrder(orderData)
          : await _orderService.updateOrder(widget.orderId ?? 0, orderData);

      if (response.statusCode == 200 && response.data['statusCode'] == 200) {
        final newOrderId = response.data['data']['id'] ?? widget.orderId;
        final newOrderCode = response.data['data']['code'] ?? _orderCode;

        if (_isNewOrder) {
          setState(() {
            _isNewOrder = false;
            _order = _order!.copyWith(id: newOrderId, code: newOrderCode);
          });
        }

        _showSnack(
          _isNewOrder
              ? 'Đơn hàng $newOrderCode đã được tạo thành công!'
              : 'Đơn hàng $newOrderCode đã được cập nhật thành công!',
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showSnack(
          response.data['message'] ??
              (_isNewOrder
                  ? 'Có lỗi xảy ra khi tạo đơn hàng.'
                  : 'Có lỗi xảy ra khi cập nhật đơn hàng.'),
        );
      }
    } catch (e) {
      _showSnack('Lỗi khi xử lý đơn hàng: $e');
    } finally {
      setState(() {
        _isCreatingOrUpdating = false;
      });
    }
  }

  Widget _buildFooter() {
    final bool canSave =
        _order != null && !_isCreatingOrUpdating && !_refreshing;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Trạng thái đơn",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ComboModel>(
                    isExpanded: true,
                    value: _selectedOrderStatus,
                    hint: const Text("Chọn trạng thái đơn hàng"),
                    items: _orderStatuses.map((status) {
                      return DropdownMenuItem<ComboModel>(
                        value: status,
                        child: Text(status.name),
                      );
                    }).toList(),
                    onChanged: canSave
                        ? (v) => setState(() {
                            _selectedOrderStatus = v;
                          })
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (_isCreatingOrUpdating || _refreshing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: canSave ? _createOrUpdateOrder : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(48, 48),
                      backgroundColor: canSave ? Colors.blue : Colors.grey,
                    ),
                    child: Icon(Icons.save, size: 24, color: Colors.white),
                  ),

                  if (!_isNewOrder && canSave)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        onPressed: _showQrCodeDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.qr_code, size: 24),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============== Upload video/image ==============
  Widget _buildMediaSection() {
    // SỬA LỖI ẨN MEDIA SECTION KHI TẠO MỚI (ID <= 0)
    if (_order == null || _order!.id! <= 0) {
      return const SizedBox.shrink();
    }

    final List<RepairMediaModel> currentMedias = _order?.medias ?? [];
    final bool canUpload =
        _order?.id != null && _order!.id! > 0; // Luôn là true ở đây

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: MediaSection(
          medias: currentMedias,
          // Khi đã qua kiểm tra if, canUpload luôn là true, nên ta gọi hàm upload trực tiếp
          onUploadImage: () =>
              _uploadMediaForOrder(detailId: 0, stepId: 0, type: "image"),
          onUploadVideo: () =>
              _uploadMediaForOrder(detailId: 0, stepId: 0, type: "video"),
          onMediaTap: _handleMediaTap,
          axisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _orderCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã đơn hàng',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      isDense: true,
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SearchableDropdown<CustomerModel>(
                    labelText: 'Tìm kiếm khách hàng',
                    controller: _customerNameController,
                    suggestionsCallback: _loadCustomers,
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.fullName ?? 'Không có tên'),
                        subtitle: Text(suggestion.phoneNumber ?? ''),
                      );
                    },
                    onSelected: (suggestion) {
                      setState(() {
                        _selectedCustomer = suggestion;
                        _customerNameController.text =
                            suggestion.fullName ?? '';
                        _phoneNumberController.text =
                            suggestion.phoneNumber ?? '';
                        _addressController.text = suggestion.address ?? '';
                        _customerCode = suggestion.code ?? '';
                      });
                    },
                    loading: _isCustomerLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên khách hàng',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _finishDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày muốn hoàn thành',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      isDense: true,
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInputAndList() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thêm dịch vụ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SearchableDropdown<ServiceModel>(
              labelText: 'Tìm kiếm & Chọn dịch vụ',
              suggestionsCallback: _loadServices,
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion.name ?? ''),
                  subtitle: Text(
                    'Giá: ${FormatUtils.formatNumber(suggestion.basePrice)} đ (VAT: ${suggestion.vatRate}%)',
                  ),
                );
              },
              onSelected: (service) => _addService(service),
              loading: _isServiceLoading,
              controller: TextEditingController(),
            ),

            // Hiển thị danh sách dịch vụ đã chọn
            _buildServiceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    if (_selectedServices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 15),
        child: Text(
          'Chưa có dịch vụ nào được chọn.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 15),
        const Text(
          'Dịch vụ đã chọn:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // --- Danh sách dịch vụ ---
        ..._selectedServices.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> service = entry.value;
          num unitPrice = service['unitPrice'] as num;
          int quantity = service['quantity'] as int;
          num vatRate = service['vatRate'] as num;
          num subtotal = unitPrice * quantity;
          num vat = subtotal * vatRate / 100;
          num total = subtotal + vat;

          return Card(
            color: Colors.grey[50],
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['serviceName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _removeService(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Giá và Số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đơn giá: ${FormatUtils.formatNumber(unitPrice)} đ'),
                      QuantityInput(
                        initialQuantity: quantity,
                        onChanged: (newQty) =>
                            _updateServiceDetails(index, 'quantity', newQty),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // VAT và Tổng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VAT (${vatRate.toStringAsFixed(0)}%): ${FormatUtils.formatNumber(vat)} đ',
                      ),
                      Text(
                        'Tổng: ${FormatUtils.formatNumber(total)} đ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Mô tả chi tiết
                  TextFormField(
                    initialValue: service['description'],
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết dịch vụ',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        _updateServiceDetails(index, 'description', value),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // **FIX: Thêm đơn vị 'đ' và sửa logic giữ con trỏ**
  Widget _buildFinancialSummary() {
    // Hàm này xử lý định dạng tiền tệ VÀ gọi _updateTotals() thông qua setState
    void _handleCurrencyInput(TextEditingController controller, String value) {
      final currentText = controller.text;
      // FIX: Làm sạch chuỗi triệt để (bỏ cả dấu chấm, phẩy và chữ " đ")
      final cleanValue = value.replaceAll(RegExp(r'[., đ]'), '');

      // 1. Xử lý giá trị rỗng/bằng 0
      if (cleanValue.isEmpty) {
        setState(() {
          controller.value = TextEditingValue(
            text: '0 đ',
            selection: TextSelection.collapsed(offset: 1),
          );
          _updateTotals(); // Kích hoạt tính toán
        });
        return;
      }

      // 2. Định dạng lại và thêm ' đ'
      final num numericValue = int.tryParse(cleanValue) ?? 0;
      final String newFormattedText =
          FormatUtils.formatNumber(numericValue) + ' đ';

      // 3. Logic giữ vị trí con trỏ (Điều chỉnh để loại bỏ " đ" ở cuối)
      final offsetMinusCurrency = 2; // Khoảng cách của " đ"
      final oldSelection = controller.selection.start.clamp(
        0,
        currentText.length - offsetMinusCurrency,
      );

      int newSelection;
      int cleanCursorPosition =
          oldSelection -
          currentText
              .substring(0, oldSelection)
              .replaceAll(RegExp(r'[0-9]'), '')
              .length;
      newSelection = cleanCursorPosition;

      int newDots = newFormattedText.replaceAll(RegExp(r'[0-9 đ]'), '').length;
      for (int i = 0; i < newDots; i++) {
        if (newFormattedText.length > newSelection &&
            newFormattedText.substring(0, newSelection + 1).endsWith('.')) {
          newSelection++;
        }
      }

      // Vị trí cuối cùng là (độ dài chuỗi - 2) để con trỏ đứng trước chữ ' đ'
      final finalSelection = (newSelection).clamp(
        0,
        newFormattedText.length - offsetMinusCurrency,
      );

      // 4. Cập nhật trong setState
      setState(() {
        controller.value = TextEditingValue(
          text: newFormattedText,
          selection: TextSelection.collapsed(offset: finalSelection),
        );
        _updateTotals(); // GỌI TÍNH LẠI TỔNG TIỀN
      });
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _extraCostController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) =>
                        _handleCurrencyInput(_extraCostController, value),
                    decoration: const InputDecoration(
                      labelText: 'Phát sinh thêm',
                      border: OutlineInputBorder(),
                      isDense: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      // XÓA suffixText
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) =>
                        _handleCurrencyInput(_discountController, value),
                    decoration: const InputDecoration(
                      labelText: 'Chiết khấu',
                      border: OutlineInputBorder(),
                      isDense: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      // XÓA suffixText
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _grandTotalController,
              decoration: InputDecoration(
                labelText: 'TỔNG TIỀN THANH TOÁN',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green[700]!),
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green[700],
                ),
                filled: true,
                fillColor: Colors.green.withOpacity(0.05),
                isDense: true,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                // XÓA suffixText
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.green[800],
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết lỗi/Yêu cầu dịch vụ',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNewOrder ? 'Thêm mới đơn hàng' : 'Cập nhật đơn hàng',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _orderDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: Không thể tải chi tiết đơn hàng: ${snapshot.error}',
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // MEDIA SECTION
                      _buildMediaSection(),

                      // THÔNG TIN KHÁCH HÀNG & ĐƠN HÀNG
                      _buildCustomerInfo(),

                      // DỊCH VỤ CHI TIẾT
                      _buildServiceInputAndList(),

                      // TÀI CHÍNH (ĐÃ FIX LỖI UPDATE TOTALS)
                      _buildFinancialSummary(),

                      // MÔ TẢ CHI TIẾT
                      _buildDescriptionSection(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }
}
