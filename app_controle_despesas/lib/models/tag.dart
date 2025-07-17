class Tag {
  final String id; // ID fornecido pela chave do Firebase
  final String name;

  Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromMap(Map<String, dynamic> map, String key) {
    return Tag(
      id: key,
      name: map['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}