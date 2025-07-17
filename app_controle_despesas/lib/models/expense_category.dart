class ExpenseCategory {
  final String id; // ID fornecido pela chave do Firebase
  final String name;
  final bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map, String key) {
    return ExpenseCategory(
      id: key,
      name: map['name'],
      isDefault: map['isDefault'] ?? false, // Garante que é false se nulo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isDefault': isDefault,
    };
  }
}