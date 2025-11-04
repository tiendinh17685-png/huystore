import 'package:intl/intl.dart';

class FormatUtils {
  static String formatCurrency(num? value) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value ?? 0)} đ";
  }

   static String formatNumber(num? value) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value ?? 0)}";
  }

  static String formatDate(DateTime? date) {
    if (date == null) return "";
    return DateFormat("dd/MM/yyyy").format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return "";
    return DateFormat("dd/MM/yyyy HH:mm").format(date);
  }
}
