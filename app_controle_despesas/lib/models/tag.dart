class Tag {
  final String id; // ID fornecido pela chave do Firebase
  final String name;
  final bool isDefault;

  Tag({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  factory Tag.fromMap(Map<String, dynamic> map, String key) {
    return Tag(
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