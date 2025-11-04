// huystore/features/services/data/models/service_model.dart

class ServiceModel {
  final int serviceId;
  final String code;
  final String name;
  final num   basePrice;
  final num   totalAmount;
  final num   vatRate;
  final num   vatRateAmount;

  ServiceModel({
    required this.serviceId,
    required this.code,
    required this.name,
    required this.basePrice,
    required this.totalAmount,
    required this.vatRate,
    required this.vatRateAmount,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      basePrice: json['basePrice'] as num ,
      totalAmount: json['totalAmount'] as num ,
      vatRate: json['vatRate'] as num ,
      vatRateAmount: json['vatRateAmount'] as num ,
    );
  }
}