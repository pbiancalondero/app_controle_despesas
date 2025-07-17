import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/tag.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante adicionar este import!

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  List<Tag> _tags = [];

  // Mantenha como 'late', mas não inicialize aqui ainda.
  late DatabaseReference _dbRef;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  List<Tag> get tags => _tags;

  // Modifique o construtor para receber uma flag de inicialização
  ExpenseProvider() {
    _initializeDbRef(); // Chame um método de inicialização
    _initListeners();
  }

  // Novo método para inicializar _dbRef
  void _initializeDbRef() {
    // É crucial que Firebase.initializeApp() já tenha sido chamado no main.dart
    // antes que este provider seja criado.

    // A URL que você confirmou no console:
    const String firebaseDbUrl = "https://controledespesas-85d96-default-rtdb.firebaseio.com/";

    // Use o SDK do Firebase Core para obter a instância, o que é mais robusto
    // do que apenas refFromURL em alguns casos.
    // Primeiro, verifique se há um app Firebase default.
    try {
      // Se Firebase.initializeApp() já foi chamado no main, ele deve estar disponível
      FirebaseApp defaultApp = Firebase.app();
      _dbRef = FirebaseDatabase.instanceFor(app: defaultApp, databaseURL: firebaseDbUrl).ref();
      print("FirebaseDatabase.instanceFor inicializado com URL: $firebaseDbUrl");
    } catch (e) {
      // Se não houver app default, ou algum outro erro, podemos tentar a abordagem direta
      print("Erro ao tentar inicializar com Firebase.app(): $e. Tentando refFromURL diretamente.");
      _dbRef = FirebaseDatabase.instance.refFromURL(firebaseDbUrl);
    }
  }


  void _initListeners() {
    // ... (Seu código _initListeners permanece o mesmo)
    // Escutando as despesas do usuário
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _dbRef.child('users/${user.uid}/expenses').onValue.listen((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            _expenses = data.entries.map((entry) => Expense.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
          } else {
            _expenses = [];
          }
          notifyListeners();
        });

        _dbRef.child('users/${user.uid}/categories').onValue.listen((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            _categories = data.entries.map((entry) => ExpenseCategory.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
          } else {
            _categories = _getDefaultCategories();
          }
          notifyListeners();
        });

        _dbRef.child('users/${user.uid}/tags').onValue.listen((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            _tags = data.entries.map((entry) => Tag.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
          } else {
            _tags = _getDefaultTags();
          }
          notifyListeners();
        });
      } else {
        _expenses = [];
        _categories = _getDefaultCategories();
        _tags = _getDefaultTags();
        notifyListeners();
      }
    });
  }

  List<ExpenseCategory> _getDefaultCategories() {
    return [
      ExpenseCategory(id: '1', name: 'Alimentação', isDefault: true),
      ExpenseCategory(id: '2', name: 'Transporte', isDefault: true),
      ExpenseCategory(id: '3', name: 'Entretenimento', isDefault: true),
      ExpenseCategory(id: '4', name: 'Saúde', isDefault: true),
      ExpenseCategory(id: '5', name: 'Telefonia', isDefault: true),
    ];
  }

  List<Tag> _getDefaultTags() {
    return [
      Tag(id: '1', name: 'Ônibus'),
      Tag(id: '2', name: 'Restaurante'),
      Tag(id: '3', name: 'Mercado'),
      Tag(id: '4', name: 'Uber'),
      Tag(id: '5', name: 'Férias'),
      Tag(id: '6', name: 'Aniversário'),
      Tag(id: '7', name: 'Dieta'),
      Tag(id: '8', name: 'Autocuidado'),
    ];
  }

  // --- MÉTODOS CRUD PARA O FIREBASE ---

  String? get _currentUserId => _auth.currentUser?.uid;

  // Add an expense
  Future<void> addExpense(Expense expense) async {
    if (_currentUserId == null) return; // Garante que há um usuário logado

    // O Firebase gera o ID automaticamente com push()
    final newExpenseRef = _dbRef.child('users/${_currentUserId!}/expenses').push();
    final String newId = newExpenseRef.key!; // O ID gerado pelo Firebase

    // Cria uma nova instância de Expense com o ID gerado pelo Firebase
    final Expense expenseWithId = Expense(
      id: newId,
      amount: expense.amount,
      categoryId: expense.categoryId,
      note: expense.note,
      date: expense.date,
      tag: expense.tag,
    );

    await newExpenseRef.set(expenseWithId.toMap());
    // Não precisa de notifyListeners() aqui se a stream já estiver ativa
    // _expenses.add(expenseWithId); // REMOVER: A lista será atualizada pela stream
  }

  Future<void> addOrUpdateExpense(Expense expense) async {
    if (_currentUserId == null) return;

    if (expense.id.isEmpty) { // Se o ID estiver vazio, é uma nova despesa
      await addExpense(expense); // Usa o método de adicionar para gerar ID
    } else { // Se o ID existir, é uma atualização
      await _dbRef.child('users/${_currentUserId!}/expenses/${expense.id}').update(expense.toMap());
    }
    // Não precisa de notifyListeners()
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/expenses/$id').remove();
    // Não precisa de notifyListeners()
  }

  // Add a category
  Future<void> addCategory(ExpenseCategory category) async {
    if (_currentUserId == null) return;

    // Verifique se a categoria já existe localmente (evitar duplicatas antes de enviar ao Firebase)
    if (_categories.any((cat) => cat.name == category.name && cat.isDefault == category.isDefault)) {
      return; // Categoria já existe, não adiciona
    }

    final newCategoryRef = _dbRef.child('users/${_currentUserId!}/categories').push();
    final String newId = newCategoryRef.key!;

    final ExpenseCategory categoryWithId = ExpenseCategory(
      id: newId,
      name: category.name,
      isDefault: category.isDefault,
    );
    await newCategoryRef.set(categoryWithId.toMap());
    // Não precisa de notifyListeners()
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/categories/$id').remove();
    // Não precisa de notifyListeners()
  }

  // Add a tag
  Future<void> addTag(Tag tag) async {
    if (_currentUserId == null) return;

    // Verifique se a tag já existe localmente
    if (_tags.any((t) => t.name == tag.name)) {
      return;
    }

    final newTagRef = _dbRef.child('users/${_currentUserId!}/tags').push();
    final String newId = newTagRef.key!;

    final Tag tagWithId = Tag(
      id: newId,
      name: tag.name,
    );
    await newTagRef.set(tagWithId.toMap());
    // Não precisa de notifyListeners()
  }

  // Delete a tag
  Future<void> deleteTag(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/tags/$id').remove();
    // Não precisa de notifyListeners()
  }

  // Método de dispose para cancelar as subscriptions das streams do Firebase
  @override
  void dispose() {
    // Você precisará armazenar as StreamSubscriptions em variáveis e cancelá-las aqui.
    // Exemplo: _expenseSubscription?.cancel();
    super.dispose();
  }
}