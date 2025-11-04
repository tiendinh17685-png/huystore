import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Thêm import này
// import 'package:firebase_auth/firebase_auth.dart'; 
// import 'package:huystore/core/services/token_storage.dart'; 
import 'package:huystore/features/orders/data/services/order_service.dart';
import 'package:huystore/features/orders/presentation/pages/order_list_guest_page.dart';
import 'package:huystore/features/orders/presentation/widgets/qr_scan_screen_guest.dart';
import 'dart:async';
// import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // <-- LOẠI BỎ

class HomeGuestPage extends StatefulWidget {
  const HomeGuestPage({super.key});

  @override
  State<HomeGuestPage> createState() => _HomeGuestPageState();
}

class _HomeGuestPageState extends State<HomeGuestPage> {
  final TextEditingController _searchController = TextEditingController();
  final OrderService _orderService = OrderService();
  
  bool _isSearching = false;
  String? _errorMessage;

  // LOẠI BỎ MaskTextInputFormatter
  // final _phoneFormatter = MaskTextInputFormatter(
  //   mask: '##########', 
  //   filter: {"#": RegExp(r'[0-9]')},
  //   type: MaskAutoCompletionType.lazy,
  // );


  // =========================================================
  // HÀM CHÍNH: TRA CỨU NGAY LẬP TỨC BẰNG SĐT
  // =========================================================
  void _startLookupDirectly() async {
    final rawPhoneNumber = _searchController.text.trim();

    // Kiểm tra định dạng: BẮT BUỘC 10 SỐ VÀ BẮT ĐẦU BẰNG '0'
    if (rawPhoneNumber.length != 10) {
      setState(() => _errorMessage = "Vui lòng nhập chính xác 10 số.");
      return;
    }
    
    // Kiểm tra số đầu tiên (đảm bảo không bị lỗi nhập thành 00)
    if (!rawPhoneNumber.startsWith('0')) {
        setState(() => _errorMessage = "Số điện thoại phải bắt đầu bằng 0.");
        return;
    }
    
    final phoneNumberForLookup = rawPhoneNumber;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Giả lập độ trễ

      _navigateToOrderList(phoneNumberForLookup);

    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = "Lỗi tra cứu: ${e.toString()}";
      });
    }
  }

  // =========================================================
  // LOGIC CHUYỂN HƯỚNG
  // =========================================================
  void _navigateToOrderList(String phoneNumber) {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _errorMessage = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderListGuestScreen(
          title: 'Đơn hàng của $phoneNumber',
          phoneNumber: phoneNumber,
        ),
      ),
    );
  }

  // =========================================================
  // CÁC HÀM TIỆN ÍCH VÀ WIDGETS
  // =========================================================
  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScanScreenGuest()),
    );
    if (result != null && result is String) {
      _navigateToOrderDetail(result);
    }
  }

  void _navigateToOrderDetail(String orderCode) {
    _showMessage(
      "Chuyển đến chi tiết đơn hàng (Mã: $orderCode)",
      isError: false,
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
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
              size: 150,
              color: Colors.blue,
            ),
            onPressed: _scanQRCode,
          ),
          const SizedBox(height: 10),
          const Text(
            "Quét QR để xem chi tiết đơn hàng",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      children: [
        // SỬ DỤNG FilteringTextInputFormatter ĐỂ CHỈ CHO PHÉP SỐ
        TextField(
          controller: _searchController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly // <-- Chỉ cho phép nhập số
          ], 
          maxLength: 10, // Giới hạn cứng 10 ký tự
          decoration: const InputDecoration(
            labelText: 'Nhập Số Điện Thoại (10 số, bắt đầu bằng 0)',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            counterText: "", // Bỏ bộ đếm ký tự
          ),
        ),
        
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _isSearching ? null : _startLookupDirectly,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Tra Cứu Đơn Hàng',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra Cứu Đơn Hàng'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQRCodeSection(),
              const SizedBox(height: 32),
              const Text(
                "HOẶC TRA CỨU BẰNG SỐ ĐIỆN THOẠI",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildInputForm(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}