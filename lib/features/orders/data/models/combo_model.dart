class ComboModel {
  final int id;
  final String code;
  final String name;

  ComboModel({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ComboModel.fromJson(Map<String, dynamic> json) {
    return ComboModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
