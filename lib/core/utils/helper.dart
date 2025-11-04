import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/core/utils/enum_utils.dart';
import 'package:huystore/features/orders/data/models/combo_model.dart';
import 'package:huystore/features/orders/data/models/order_full_model.dart';
import 'package:huystore/features/orders/data/models/order_model.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

/// ===============================
/// Enum/Hằng số gợi ý (Giữ nguyên)
/// ===============================
class StepStatusId {
  static const int pending = 0;
  static const int doing = 1;
  static const int done = 2;
}
class DetailStatusText {
  static const String processing = "Processing";
  static const String completed = "Completed";
}

class Helper {
  // Helper kiểm tra step/detail
  static bool isStepFinished(dynamic step) {
    final int? statusId =
        step.statusId ?? (step.status is int ? step.status : null);
    return statusId == ProcessingStatus.Finished.value;
  }

  static bool isDetailFinished(dynamic detail) {
    final steps = detail.steps;
    if (steps != null && steps.isNotEmpty) {
      return steps.every(isStepFinished);
    }
    final int? statusId =
        detail.statusId ?? (detail.status is int ? detail.status : null);
    return statusId == ProcessingStatus.Finished.value;
  }

  // =========================
  // PAYMENT STATUS HELPERS
  // =========================
  static String paymentStatusText(int? status) {
    switch (status) {
      case 2:
        return "Đã thanh toán";
      case 1:
      default:
        return "Chờ thanh toán";
    }
  }

  static Color paymentStatusColor(int? status) {
    switch (status) {
      case 2:
        return Colors.green;
      case 1:
      default:
        return Colors.red;
    }
  }

  static int countTotalSteps(OrderModel order) {
    final details = order.details;
    if (details == null) return 0;
    int total = 0;
    for (final d in details) {
      final steps = d.steps;
      if (steps != null) total += steps.length;
    }
    return total;
  }

  static int countFinishedSteps(OrderModel order) {
    final details = order.details;
    if (details == null) return 0;
    int done = 0;
    for (final d in details) {
      final steps = d.steps;
      if (steps != null) {
        done += steps.where(Helper.isStepFinished).length;
      }
    }
    return done;
  }

  static double progress(OrderModel order) {
    final total = countTotalSteps(order);
    if (total == 0) return 0;
    final done = countFinishedSteps(order);
    return done / total;
  }

  // ======= Dùng logic ID chi tiết của người dùng cho CHIP (Base Color) ========
  static Color statusChipColor(ComboModel? status) {
    if (status == null) return Colors.red;
    return getStatusColor(status.id);
  }

  // ======= Dùng logic ID chi tiết của người dùng cho DROP DOWN (thêm opacity) ========
  static Color getStatusDropdownColor(ComboModel? status) {
    final Color baseColor = statusChipColor(status);

    // Áp dụng màu nền mờ dựa trên màu cơ bản của chip
    return baseColor.withOpacity(0.1);
  }

  // =========================
  // BỔ SUNG: build vietqr url (dùng img.vietqr.io service)
  // =========================
  static String buildVietQrUrl({
    required String bankId,
    required String accountNo,
    required String receiverName,
    required int amount,
    required String addInfo,
  }) {
    final rn = Uri.encodeComponent(receiverName);
    final ai = Uri.encodeComponent(addInfo);
    return "https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?accountName=$rn&amount=$amount&addInfo=$ai";
  }

  static final String _fileUrlBase = dotenv.env['FILE_URL'] ?? "";
  // Hàm helper để chuẩn hóa URL
  static String normalizeFileUrl(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return "";
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    return _fileUrlBase + "/" + fileUrl;
  }

  /**
 * 
 */
  static Color getStatusColor(int id) {
    switch (id) {
      case 13: // OrderCompletedDelivered (Hoàn thành - Đã giao)
        return Colors.green; // Xanh lá cây (Success)
      case 12: // OrderDelivering (Đang giao trả)
        return Colors.lightGreen; // Xanh lá nhạt (Sắp hoàn thành)

      // ID 8 và ID 11 là các KEY MILESTONE (Đã xác nhận / Đã làm xong)
      case 11: // OrderFixedWaitingDelivery (Đã sửa xong - Chờ giao)
      case 8: // OrderConfirmPrice (Khách đã xác nhận)
        return Colors.blue; // Xanh dương (Sẵn sàng/Key Milestone)

      case 9: // OrderEditing (Đang sửa chữa)
        return Colors.orange; // Cam (Đang trong quá trình)

      case 14: // OrderCustomerRefusedNotRepair (Khách từ chối sửa/Không sửa được)
        return Colors.grey; // Xám (Hủy/Từ chối)

      case 1: // OrderWaitingConfirm (Chờ xác nhận)
      case 2: // OrderGetting (Đang lấy giày)
      case 3: // OrderReceived (Đã nhận giày)
      case 4: // OrderChecking (Đang kiểm tra)
      case 5: // OrderQuotingPrice (Đang báo giá)
      case 6: // OrderWaitingConfirmPrice (Chờ khách xác nhận giá)
      default: // Còn lại (Cần lưu ý xử lý)
        return Colors.red; // Đỏ (Cần lưu ý xử lý)
    }
  }

  ///
  static bool isNearDeadline(DateTime? deadline) {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline.difference(now).inDays <= 1;
  }


  static int countGuestTotalSteps(OrderFullModel order) {
    final details = order.details;
    if (details == null) return 0;
    int total = 0;
    for (final d in details) {
      final steps = d.steps;
      if (steps != null) total += steps.length;
    }
    return total;
  }

  static int countGuestFinishedSteps(OrderFullModel order) {
    final details = order.details;
    if (details == null) return 0;
    int done = 0;
    for (final d in details) {
      final steps = d.steps;
      if (steps != null) {
        done += steps.where(Helper.isStepFinished).length;
      }
    }
    return done;
  }

  static double progressGuest(OrderFullModel order) {
    final total = countGuestTotalSteps(order);
    if (total == 0) return 0;
    final done = countGuestFinishedSteps(order);
    return done / total;
  }
}
