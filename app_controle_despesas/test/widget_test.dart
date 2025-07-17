import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart'; // Importe o Provider
import 'package:controle_despesas/main.dart'; // Seu arquivo main.dart
import 'package:controle_despesas/providers/expense_provider.dart'; // Seu ExpenseProvider
import 'mocks/mock_expense_provider.dart'; // Seu mock do ExpenseProvider

void main() {
  // Inicialização mockada do Firebase para testes de widget
  // Isso evita que o Firebase precise ser inicializado de verdade nos testes.
  // Adicione esta função auxiliar:
  void setupMockFirebase() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger`
    // para mockar canais de plataforma se necessário,
    // mas para inicialização básica do Firebase, não é estritamente necessário mockar o FirebaseCore aqui
    // se você está mockando o Provider que interage com ele.
    // Para um teste de widget simples, apenas garantir que o App não tente inicializar o Firebase real é o suficiente.
    // Se seus testes precisarem de comportamento do Firebase real (como retorno de chamadas),
    // você precisará de mais mocks ou do Firebase Test Lab/Emulators.
  }

  setUpAll(() {
    setupMockFirebase();
  });

  testWidgets('Home Screen loads and displays initial text', (WidgetTester tester) async {
    // Crie uma instância do seu mock do ExpenseProvider
    final mockExpenseProvider = MockExpenseProvider();

    // Mockar o comportamento dos getters para que retornem listas vazias ou controladas
    // quando o Consumer tentar acessá-las.
    when(mockExpenseProvider.expenses).thenReturn([]);
    when(mockExpenseProvider.categories).thenReturn([]);
    when(mockExpenseProvider.tags).thenReturn([]);

    // Envolva seu MyApp em um Provider.value para usar o mock
    await tester.pumpWidget(
      ChangeNotifierProvider<ExpenseProvider>.value(
        value: mockExpenseProvider,
        child: const MyApp(), // MyApp agora não recebe localStorage
      ),
    );

    // Agora o teste verificará se a mensagem de "nenhuma despesa" é exibida,
    // já que o mock do provider retorna uma lista vazia de despesas.
    expect(find.text('Clique no botão + para registrar despesas.'), findsOneWidget);

    // Se você quiser testar adicionar uma despesa, você mocaria o método addOrUpdateExpense
    // when(mockExpenseProvider.addOrUpdateExpense(any)).thenAnswer((_) async => Future.value());

    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pumpAndSettle(); // Espera a transição para AddExpenseScreen
    // expect(find.byType(AddExpenseScreen), findsOneWidget);

    // Nota: O teste original do contador não se aplica mais diretamente à sua aplicação atual.
    // Este é um exemplo mais relevante para a sua HomeScreen.
  });

  // Você pode adicionar mais testes para outras funcionalidades, mockando os métodos relevantes
  // do ExpenseProvider conforme a necessidade.
}