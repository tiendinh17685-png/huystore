class AccountModel {
  final int? id;
  final String? fullName;
  final String? phoneNumber;
  final String? email;

  AccountModel({
    this.id,
    this.fullName,
    this.phoneNumber,
    this.email,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int?,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
    );
  }
}