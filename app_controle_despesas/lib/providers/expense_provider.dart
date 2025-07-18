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

  late DatabaseReference _dbRef;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // StreamSubscriptions para gerenciar os listeners e poder cancelá-los no dispose
  // É crucial para evitar vazamento de memória e garantir que os listeners sejam re-registrados corretamente
  // ao trocar de usuário, por exemplo.
  // Mudei para Nullable para que possam ser inicializadas como nulas e depois atribuídas.
  DatabaseReference? _expensesRef;
  DatabaseReference? _categoriesRef;
  DatabaseReference? _tagsRef;

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  List<Tag> get tags => _tags;

  ExpenseProvider() {
    _initializeDbRef();
    // A inicialização dos listeners será feita no _onAuthStateChanged
    // para garantir que o UID do usuário esteja disponível.
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _initializeDbRef() {
    const String firebaseDbUrl = "https://controledespesas-85d96-default-rtdb.firebaseio.com/";
    try {
      FirebaseApp defaultApp = Firebase.app();
      _dbRef = FirebaseDatabase.instanceFor(app: defaultApp, databaseURL: firebaseDbUrl).ref();
      print("FirebaseDatabase.instanceFor inicializado com URL: $firebaseDbUrl");
    } catch (e) {
      print("Erro ao tentar inicializar com Firebase.app(): $e. Tentando refFromURL diretamente.");
      _dbRef = FirebaseDatabase.instance.refFromURL(firebaseDbUrl);
    }
  }

  // Método para lidar com mudanças no estado de autenticação
  void _onAuthStateChanged(User? user) async {
    // Cancelar listeners antigos antes de configurar novos
    _categoriesRef?.onValue.drain(); // Drena os eventos restantes
    _tagsRef?.onValue.drain();
    _expensesRef?.onValue.drain();

    if (user != null) {
      _expensesRef = _dbRef.child('users/${user.uid}/expenses');
      _categoriesRef = _dbRef.child('users/${user.uid}/categories');
      _tagsRef = _dbRef.child('users/${user.uid}/tags');

      // Escutar despesas
      _expensesRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _expenses = data.entries.map((entry) => Expense.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _expenses = [];
        }
        notifyListeners();
      });

      // Escutar categorias
      _categoriesRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _categories = data.entries.map((entry) => ExpenseCategory.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _categories = []; // Se não houver dados, a lista local fica vazia
          // Só adiciona categorias padrão se o nó estiver realmente vazio no Firebase
          _checkAndAddDefaultCategories(user.uid);
        }
        notifyListeners();
      });

      // Escutar tags
      _tagsRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _tags = data.entries.map((entry) => Tag.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _tags = []; // Se não houver dados, a lista local fica vazia
          // Só adiciona tags padrão se o nó estiver realmente vazio no Firebase
          _checkAndAddDefaultTags(user.uid);
        }
        notifyListeners();
      });
    } else {
      // Limpar listas quando o usuário desloga
      _expenses = [];
      _categories = [];
      _tags = [];
      notifyListeners();
    }
  }

  // Novo método para adicionar categorias padrão apenas se elas não existirem no Firebase
  Future<void> _checkAndAddDefaultCategories(String userId) async {
    final snapshot = await _dbRef.child('users/$userId/categories').once();
    if (snapshot.snapshot.value == null || (snapshot.snapshot.value as Map).isEmpty) {
      // Se não houver categorias no Firebase para este usuário, adicione as padrão
      for (var category in _getDefaultCategories()) {
        final newCategoryRef = _dbRef.child('users/$userId/categories').push();
        final String newId = newCategoryRef.key!;
        final ExpenseCategory categoryWithId = ExpenseCategory(
          id: newId,
          name: category.name,
          isDefault: category.isDefault,
        );
        await newCategoryRef.set(categoryWithId.toMap());
      }
    }
  }

  // Novo método para adicionar tags padrão apenas se elas não existirem no Firebase
  Future<void> _checkAndAddDefaultTags(String userId) async {
    final snapshot = await _dbRef.child('users/$userId/tags').once();
    if (snapshot.snapshot.value == null || (snapshot.snapshot.value as Map).isEmpty) {
      // Se não houver tags no Firebase para este usuário, adicione as padrão
      for (var tag in _getDefaultTags()) {
        final newTagRef = _dbRef.child('users/$userId/tags').push();
        final String newId = newTagRef.key!;
        final Tag tagWithId = Tag(
          id: newId,
          name: tag.name,
          isDefault: tag.isDefault, // Certifique-se que o modelo Tag tem 'isDefault'
        );
        await newTagRef.set(tagWithId.toMap());
      }
    }
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
      Tag(id: '1', name: 'Ônibus', isDefault: true), // Adicione isDefault aqui para consistência
      Tag(id: '2', name: 'Restaurante', isDefault: true),
      Tag(id: '3', name: 'Mercado', isDefault: true),
      Tag(id: '4', name: 'Uber', isDefault: true),
      Tag(id: '5', name: 'Férias', isDefault: true),
      Tag(id: '6', name: 'Aniversário', isDefault: true),
      Tag(id: '7', name: 'Dieta', isDefault: true),
      Tag(id: '8', name: 'Autocuidado', isDefault: true),
    ];
  }

  // --- MÉTODOS CRUD PARA O FIREBASE ---

  String? get _currentUserId => _auth.currentUser?.uid;

  // Add an expense
  Future<void> addExpense(Expense expense) async {
    if (_currentUserId == null) return;

    final newExpenseRef = _dbRef.child('users/${_currentUserId!}/expenses').push();
    final String newId = newExpenseRef.key!;

    final Expense expenseWithId = Expense(
      id: newId,
      amount: expense.amount,
      categoryId: expense.categoryId,
      note: expense.note,
      date: expense.date,
      tag: expense.tag,
    );

    await newExpenseRef.set(expenseWithId.toMap());
  }

  Future<void> addOrUpdateExpense(Expense expense) async {
    if (_currentUserId == null) return;

    if (expense.id.isEmpty) {
      await addExpense(expense);
    } else {
      await _dbRef.child('users/${_currentUserId!}/expenses/${expense.id}').update(expense.toMap());
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/expenses/$id').remove();
  }

  // Add a category
  Future<void> addCategory(ExpenseCategory category) async {
    if (_currentUserId == null) return;

    // Verifique se a categoria JÁ EXISTE no Firebase antes de adicionar
    // Você precisa de uma forma de consultar o Firebase pelo nome para evitar duplicação
    // ou depender da verificação no listener para filtrar duplicatas se elas fossem adicionadas.
    // O mais robusto é consultar o Firebase antes de um "push".
    final Query existingCategoryQuery = _dbRef.child('users/${_currentUserId!}/categories')
        .orderByChild('name')
        .equalTo(category.name);

    final DataSnapshot snapshot = await existingCategoryQuery.get();

    if (snapshot.exists) {
      // Categoria com o mesmo nome já existe no Firebase. Não adicione.
      print('Categoria "${category.name}" já existe. Não adicionando duplicata.');
      return;
    }

    final newCategoryRef = _dbRef.child('users/${_currentUserId!}/categories').push();
    final String newId = newCategoryRef.key!;

    final ExpenseCategory categoryWithId = ExpenseCategory(
      id: newId,
      name: category.name,
      isDefault: category.isDefault,
    );
    await newCategoryRef.set(categoryWithId.toMap());
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/categories/$id').remove();
  }

  // Add a tag
  Future<void> addTag(Tag tag) async {
    if (_currentUserId == null) return;

    // Verifique se a tag JÁ EXISTE no Firebase antes de adicionar
    final Query existingTagQuery = _dbRef.child('users/${_currentUserId!}/tags')
        .orderByChild('name')
        .equalTo(tag.name);

    final DataSnapshot snapshot = await existingTagQuery.get();

    if (snapshot.exists) {
      // Tag com o mesmo nome já existe no Firebase. Não adicione.
      print('Tag "${tag.name}" já existe. Não adicionando duplicata.');
      return;
    }

    final newTagRef = _dbRef.child('users/${_currentUserId!}/tags').push();
    final String newId = newTagRef.key!;

    final Tag tagWithId = Tag(
      id: newId,
      name: tag.name,
      isDefault: tag.isDefault, // Certifique-se que o modelo Tag tem 'isDefault'
    );
    await newTagRef.set(tagWithId.toMap());
  }

  // Delete a tag
  Future<void> deleteTag(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/tags/$id').remove();
  }

  @override
  void dispose() {
    // Cancelar listeners ao fazer dispose do provider
    _auth.authStateChanges().listen((event) {}).cancel(); // Cancelar o listener do authStateChanges
    _expensesRef?.onValue.drain();
    _categoriesRef?.onValue.drain();
    _tagsRef?.onValue.drain();
    super.dispose();
  }
}