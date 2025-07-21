import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/tag.dart';
import 'package:firebase_core/firebase_core.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  List<Tag> _tags = [];

  late DatabaseReference _dbRef;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference? _expensesRef;
  DatabaseReference? _categoriesRef;
  DatabaseReference? _tagsRef;

  // NOVO: Conjuntos para rastrear categorias/tags em processo de adição
  final Set<String> _addingCategories = {};
  final Set<String> _addingTags = {};

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  List<Tag> get tags => _tags;

  ExpenseProvider() {
    _initializeDbRef();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _initializeDbRef() {
    const String firebaseDbUrl = "https://controledespesas-85d96-default-rtdb.firebaseio.com/";
    FirebaseApp defaultApp = Firebase.app();
    _dbRef = FirebaseDatabase.instanceFor(app: defaultApp, databaseURL: firebaseDbUrl).ref();
    print("FirebaseDatabase.instanceFor inicializado com URL: $firebaseDbUrl");
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      _expensesRef = _dbRef.child('users/${user.uid}/expenses');
      _categoriesRef = _dbRef.child('users/${user.uid}/categories');
      _tagsRef = _dbRef.child('users/${user.uid}/tags');

      _expensesRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _expenses = data.entries.map((entry) => Expense.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _expenses = [];
        }
        notifyListeners();
      });

      _categoriesRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _categories = data.entries.map((entry) => ExpenseCategory.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _categories = [];
          _checkAndAddDefaultCategories(user.uid);
        }
        notifyListeners();
      });

      _tagsRef!.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          _tags = data.entries.map((entry) => Tag.fromMap(Map<String, dynamic>.from(entry.value), entry.key)).toList();
        } else {
          _tags = [];
          _checkAndAddDefaultTags(user.uid);
        }
        notifyListeners();
      });
    } else {
      _expenses = [];
      _categories = [];
      _tags = [];
      notifyListeners();
    }
  }

  Future<void> _checkAndAddDefaultCategories(String userId) async {
    final snapshot = await _dbRef.child('users/$userId/categories').once();
    if (snapshot.snapshot.value == null) {
      print('Adicionando categorias padrão para novo usuário ou nó vazio.');
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

  Future<void> _checkAndAddDefaultTags(String userId) async {
    final snapshot = await _dbRef.child('users/$userId/tags').once();
    if (snapshot.snapshot.value == null) {
      print('Adicionando tags padrão para novo usuário ou nó vazio.');
      for (var tag in _getDefaultTags()) {
        final newTagRef = _dbRef.child('users/$userId/tags').push();
        final String newId = newTagRef.key!;
        final Tag tagWithId = Tag(
          id: newId,
          name: tag.name,
          isDefault: tag.isDefault,
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
      Tag(id: '1', name: 'Ônibus', isDefault: true),
      Tag(id: '2', name: 'Restaurante', isDefault: true),
      Tag(id: '3', name: 'Mercado', isDefault: true),
      Tag(id: '4', name: 'Uber', isDefault: true),
      Tag(id: '5', name: 'Férias', isDefault: true),
      Tag(id: '6', name: 'Aniversário', isDefault: true),
      Tag(id: '7', name: 'Dieta', isDefault: true),
      Tag(id: '8', name: 'Autocuidado', isDefault: true),
    ];
  }

  String? get _currentUserId => _auth.currentUser?.uid;

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

  Future<void> deleteExpense(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/expenses/$id').remove();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    if (_currentUserId == null) return;

    final String categoryNameLower = category.name.toLowerCase();

    if (_addingCategories.contains(categoryNameLower)) {
      print('DEBUG: [addCategory] Categoria "${category.name}" já está em processo de adição. Abortando.');
      return;
    }
    _addingCategories.add(categoryNameLower); // Adicionar ao conjunto de "em andamento"

    try {
      print('DEBUG: [addCategory] Tentando adicionar categoria: ${category.name}');

      // 1. Verificação local para otimização (bom para UI responsiva)
      bool localExists = _categories.any((c) => c.name.toLowerCase() == categoryNameLower);
      if (localExists) {
        print('DEBUG: [addCategory] Categoria "${category.name}" JÁ EXISTE LOCALMENTE. Abortando adição ao Firebase.');
        return;
      }

      // 2. Consulta ao Firebase para verificar a existência pelo nome
      final Query existingCategoryQuery = _dbRef.child('users/${_currentUserId!}/categories')
          .orderByChild('name')
          .equalTo(category.name); // Mantenha o nome original para a consulta Firebase

      print('DEBUG: [addCategory] Consultando Firebase por categoria com nome: ${category.name}');
      final DataSnapshot snapshot = await existingCategoryQuery.get();
      print('DEBUG: [addCategory] Resultado da consulta Firebase (snapshot.value): ${snapshot.value}');

      bool firebaseExists = false;
      if (snapshot.value != null && snapshot.value is Map) {
        (snapshot.value as Map).forEach((key, value) {
          if (value is Map && value['name'] != null && (value['name'] as String).toLowerCase() == categoryNameLower) {
            firebaseExists = true;
            print('DEBUG: [addCategory] ENCONTRADO item correspondente no Firebase: ${value['name']} com ID: $key');
          }
        });
      }

      if (firebaseExists) {
        print('DEBUG: [addCategory] Categoria "${category.name}" JÁ EXISTE NO FIREBASE. Não adicionando duplicata.');
        return;
      }

      // 3. Se não existe, adicione a nova categoria
      final newCategoryRef = _dbRef.child('users/${_currentUserId!}/categories').push();
      final String newId = newCategoryRef.key!;

      final ExpenseCategory categoryWithId = ExpenseCategory(
        id: newId,
        name: category.name,
        isDefault: category.isDefault,
      );
      await newCategoryRef.set(categoryWithId.toMap());
      print('DEBUG: [addCategory] Categoria "${category.name}" ADICIONADA com sucesso ao Firebase com ID: $newId');
    } finally {
      _addingCategories.remove(categoryNameLower); // Remover do conjunto de "em andamento" SEMPRE
    }
  }

  Future<void> deleteCategory(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/categories/$id').remove();
  }

  Future<void> addTag(Tag tag) async {
    if (_currentUserId == null) return;

    final String tagNameLower = tag.name.toLowerCase();

    if (_addingTags.contains(tagNameLower)) {
      print('DEBUG: [addTag] Tag "${tag.name}" já está em processo de adição. Abortando.');
      return;
    }
    _addingTags.add(tagNameLower); // Adicionar ao conjunto de "em andamento"

    try {
      print('DEBUG: [addTag] Tentando adicionar tag: ${tag.name}');

      // 1. Verificação local para otimização
      bool localExists = _tags.any((t) => t.name.toLowerCase() == tagNameLower);
      if (localExists) {
        print('DEBUG: [addTag] Tag "${tag.name}" JÁ EXISTE LOCALMENTE. Abortando adição ao Firebase.');
        return;
      }

      // 2. Consulta ao Firebase para verificar a existência pelo nome
      final Query existingTagQuery = _dbRef.child('users/${_currentUserId!}/tags')
          .orderByChild('name')
          .equalTo(tag.name);

      print('DEBUG: [addTag] Consultando Firebase por tag com nome: ${tag.name}');
      final DataSnapshot snapshot = await existingTagQuery.get();
      print('DEBUG: [addTag] Resultado da consulta Firebase (snapshot.value): ${snapshot.value}');

      bool firebaseExists = false;
      if (snapshot.value != null && snapshot.value is Map) {
        (snapshot.value as Map).forEach((key, value) {
          if (value is Map && value['name'] != null && (value['name'] as String).toLowerCase() == tagNameLower) {
            firebaseExists = true;
            print('DEBUG: [addTag] ENCONTRADO item correspondente no Firebase: ${value['name']} com ID: $key');
          }
        });
      }

      if (firebaseExists) {
        print('DEBUG: [addTag] Tag "${tag.name}" JÁ EXISTE NO FIREBASE. Não adicionando duplicata.');
        return;
      }

      // 3. Se não existe, adicione a nova tag
      final newTagRef = _dbRef.child('users/${_currentUserId!}/tags').push();
      final String newId = newTagRef.key!;

      final Tag tagWithId = Tag(
        id: newId,
        name: tag.name,
        isDefault: tag.isDefault,
      );
      await newTagRef.set(tagWithId.toMap());
      print('DEBUG: [addTag] Tag "${tag.name}" ADICIONADA com sucesso ao Firebase com ID: $newId');
    } finally {
      _addingTags.remove(tagNameLower); // Remover do conjunto de "em andamento" SEMPRE
    }
  }

  Future<void> deleteTag(String id) async {
    if (_currentUserId == null) return;
    await _dbRef.child('users/${_currentUserId!}/tags/$id').remove();
  }

  @override
  void dispose() {
    // É uma boa prática cancelar as subscriptions explicitamente.
    // O `onValue.drain()` não garante que a subscription é cancelada.
    // Para cancelar, você precisa guardar a StreamSubscription.
    // Exemplo:
    // StreamSubscription<DatabaseEvent>? _categoriesSubscription;
    // _categoriesSubscription = _categoriesRef!.onValue.listen(...);
    // _categoriesSubscription?.cancel();
    // Neste caso, como os listeners são recriados no `_onAuthStateChanged`
    // (que é chamado apenas no login/logout), e os refs são reatribuídos,
    // o gerenciamento de memória já é razoável.
    // Se o aplicativo tiver muitos ciclos de login/logout rápidos,
    // considere guardar as subscriptions.
    super.dispose();
  }
}