import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'order_update_screen.dart';

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

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
              final id = int.parse(segments[2]); // "4"
              final code = segments[3]; // "HS-DH-258-8422-254"
              if (id > 0 && code.isNotEmpty) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderUpdateScreen(orderId: id, orderCode: code),
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
