class Operator {
  final int id;
  final String name;
  final String category;
  final bool isDefault;

  Operator({
    required this.id,
    required this.name,
    required this.category,
    this.isDefault = false,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      isDefault: json['is_default'] ?? false,
    );
  }
}
