import 'package:flutter/material.dart';
import 'package:huystore/features/orders/presentation/widgets/order_view_guest_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'order_update_screen.dart';

class QRScanScreenGuest extends StatelessWidget {
  const QRScanScreenGuest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quét mã đơn hàng")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final rawValue = barcode.rawValue;

          if (rawValue != null) {
            Uri uri = Uri.parse(rawValue);
            // link dạng: /orders/view-full-order/{id}/{code}
            final segments = uri.pathSegments;
            if (segments.length >= 4) {
              final id = int.parse(segments[segments.length-2]); // "3"
              final code = segments[segments.length-1]; // "HS-DH-258-8422-254" 4
              if (id > 0 && code.isNotEmpty) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderDetailViewScreen(orderId: id, orderCode: code),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}
