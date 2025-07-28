import 'package:mockito/mockito.dart';
import 'package:controle_despesas/providers/expense_provider.dart';
import 'package:controle_despesas/models/expense.dart';
import 'package:controle_despesas/models/expense_category.dart';
import 'package:controle_despesas/models/tag.dart';

// O Mockito gera a implementação dos métodos mocados.
// Certifique-se de que `ExpenseProvider` seja uma classe e não um `mixin` sem construtor.
// Se `ExpenseProvider` fosse um `mixin`, precisaríamos de uma classe concreta para mockar:
// class MockExpenseProvider extends Mock implements ExpenseProvider {}
// No seu caso, como é uma classe com `with ChangeNotifier`, podemos mockar diretamente.

// Gerar o mock usando o build_runner: flutter pub run build_runner build
// ou manualmente, se preferir
class MockExpenseProvider extends Mock implements ExpenseProvider {
  // Você precisará mockar os getters e métodos que seu teste espera.
  // Exemplo de como mockar os getters para que não sejam nulos:
  @override
  List<Expense> get expenses => super.noSuchMethod(
        Invocation.getter(#expenses),
        returnValue: [], // Retorna uma lista vazia por padrão
      );

  @override
  List<ExpenseCategory> get categories => super.noSuchMethod(
        Invocation.getter(#categories),
        returnValue: [],
      );

  @override
  List<Tag> get tags => super.noSuchMethod(
        Invocation.getter(#tags),
        returnValue: [],
      );

  // Exemplo de mock para o método addExpense:
  @override
  Future<void> addExpense(Expense expense) => super.noSuchMethod(
        Invocation.method(#addExpense, [expense]),
        returnValue: Future.value(null), // Retorna um Future<void> completo
      );

  // Mocke outros métodos conforme a necessidade do seu teste
  @override
  Future<void> deleteExpense(String id) => super.noSuchMethod(
        Invocation.method(#deleteExpense, [id]),
        returnValue: Future.value(null),
      );

  @override
  Future<void> addCategory(ExpenseCategory category) => super.noSuchMethod(
        Invocation.method(#addCategory, [category]),
        returnValue: Future.value(null),
      );

  @override
  Future<void> deleteCategory(String id) => super.noSuchMethod(
        Invocation.method(#deleteCategory, [id]),
        returnValue: Future.value(null),
      );

  @override
  Future<void> addTag(Tag tag) => super.noSuchMethod(
        Invocation.method(#addTag, [tag]),
        returnValue: Future.value(null),
      );

  @override
  Future<void> deleteTag(String id) => super.noSuchMethod(
        Invocation.method(#deleteTag, [id]),
        returnValue: Future.value(null),
      );


  // Mockar notifyListeners para não fazer nada real, apenas para que o Mockito saiba que o método existe.
  @override
  void notifyListeners() => super.noSuchMethod(Invocation.method(#notifyListeners, []));
}