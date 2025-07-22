class Expense {
  final String id; // ID fornecido pela chave do Firebase
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final String tag;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.tag,
  });

  // Converte um objeto JSON do Firebase para uma instância de Expense
  // O 'key' é o ID (a chave) do nó no Firebase
  factory Expense.fromMap(Map<String, dynamic> map, String key) {
    return Expense(
      id: key, // O ID é a chave do Firebase
      amount: (map['amount'] as num).toDouble(), // Firebase armazena números como num, converter para double
      categoryId: map['categoryId'],
      note: map['note'],
      date: DateTime.parse(map['date']),
      tag: map['tag'],
    );
  }

  // Converte uma instância de Expense para um objeto JSON para o Firebase
  Map<String, dynamic> toMap() {
    return {
      // 'id' não é salvo no mapa, pois ele será a chave do nó no Firebase
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': date.toIso8601String(), // Salva como string ISO 8601
      'tag': tag,
    };
  }
}