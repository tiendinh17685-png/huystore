class OrderStatisticModel {
  final int totalOrders;
  final int delayedOrders;
  final int waitingConfirmOrders;
  final int processingNeeded;
  final int currentlyProcessing;
  final int completedOrders;
  final int deliveringOrders;
  final int totalRating;
  final int rejectedOrders;

  OrderStatisticModel({
    required this.totalOrders,
    required this.delayedOrders,
    required this.waitingConfirmOrders,
    required this.processingNeeded,
    required this.currentlyProcessing,
    required this.completedOrders,
    required this.deliveringOrders,
    required this.totalRating,
    required this.rejectedOrders, // Đã thêm vào constructor
  });

  factory OrderStatisticModel.fromJson(Map<String, dynamic> json) {
    return OrderStatisticModel(
      totalOrders: json['totalOrders'] ?? 0,
      delayedOrders: json['delayedOrders'] ?? 0,
      waitingConfirmOrders: json['waitingConfirmOrders'] ?? 0,
      processingNeeded: json['processingNeeded'] ?? 0,
      currentlyProcessing: json['currentlyProcessing'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      deliveringOrders: json['deliveringOrders'] ?? 0, 
      totalRating: json['totalRating'] ?? 0,
      rejectedOrders: json['rejectedOrders'] ?? 0,
    );
  }
} 