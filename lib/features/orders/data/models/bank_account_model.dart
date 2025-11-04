class BankAccountModel {
  final int id;
  final int shopId;
  final String bankId;
  final String bankName;
  final String accountNo;
  final String receiverName;
  final bool isDefault;
  final bool isActive;
  final int? createdBy;
  final DateTime? createdAt;

  BankAccountModel({
    required this.id,
    required this.shopId,
    required this.bankId,
    required this.bankName,
    required this.accountNo,
    required this.receiverName,
    required this.isDefault,
    required this.isActive,
    this.createdBy,
    this.createdAt,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as int,
      shopId: json['shopId'] as int,
      bankId: json['bankId'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNo: json['accountNo'] ?? '',
      receiverName: json['receiverName'] ?? '',
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? false,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'bankId': bankId,
      'bankName': bankName,
      'accountNo': accountNo,
      'receiverName': receiverName,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
