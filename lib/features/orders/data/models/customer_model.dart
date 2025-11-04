class CustomerModel {
  final int? id;
  final String? code;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? address;

  CustomerModel({
    this.id,
    this.code,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int?,
      code: json['code'] as String?,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );
  }
}