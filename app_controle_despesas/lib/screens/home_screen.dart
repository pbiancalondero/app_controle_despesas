import 'package:controle_despesas/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../screens/add_expense_screen.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <<< Adicione este import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _signInAnonymously(); // <<< CHAME O MÉTODO DE LOGIN AQUI!
  }

  // >>> ADICIONE O MÉTODO DE LOGIN ANÔNIMO AQUI DENTRO DA CLASSE _HomeScreenState
  Future<void> _signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Usuário anônimo logado com sucesso! UID: ${userCredential.user?.uid}");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        print("Erro: Autenticação anônima não habilitada. Habilite-a no console do Firebase.");
      } else {
        print("Erro ao logar anonimamente: ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("Ocorreu um erro inesperado ao tentar login anônimo: $e");
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (o restante do seu código build permanece o mesmo)
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text("Controle de Despesas"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.grey,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Por data"),
            Tab(text: "Por Categoria"),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[800],
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.white),
              title: const Text('Gerenciar Categorias',
              style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // This closes the drawer
                Navigator.pushNamed(context, '/manage_categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag, color: Colors.white),
              title: const Text('Gerenciar Tags',
              style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // This closes the drawer
                Navigator.pushNamed(context, '/manage_tags');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildExpensesByDate(context),
          buildExpensesByCategory(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen())),
        tooltip: 'Adicionar despesa',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget buildExpensesByDate(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.expenses.isEmpty) {
          return const Center(
            child: Text("Clique no botão + para registrar despesas.",
                style: TextStyle(color: Colors.grey, fontSize: 18)),
          );
        }
        return ListView.builder(
          itemCount: provider.expenses.length,
          itemBuilder: (context, index) {
            final expense = provider.expenses[index];
            String formattedDate =
                DateFormat('dd/MM/yyyy').format(expense.date);
            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                provider.deleteExpense(expense.id);
              },
              background: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                color: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: ListTile(
                  title: Text(
                      "${expense.note} - \$${expense.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                      color: Colors.white,
                    ),),
                  subtitle: Text(
                      "$formattedDate - Categoria: ${getCategoryNameById(context, expense.categoryId)}",
                          style: const TextStyle(
                      color: Colors.white,
                    ),),
                  isThreeLine: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildExpensesByCategory(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.expenses.isEmpty) {
          return const Center(
            child: Text("Clique no botão + para registrar despesas.",
                style: TextStyle(color: Colors.grey, fontSize: 18)),
          );
        }

        // Grouping expenses by category
        var grouped = groupBy(provider.expenses, (Expense e) => e.categoryId);
        return ListView(
          children: grouped.entries.map((entry) {
            String categoryName = getCategoryNameById(
                context, entry.key); // Ensure you implement this function
            double total = entry.value.fold(
                0.0, (double prev, Expense element) => prev + element.amount);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "$categoryName - Total: \$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ListView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // to disable scrolling within the inner list view
                  shrinkWrap:
                      true, // necessary to integrate a ListView within another ListView
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    Expense expense = entry.value[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.monetization_on, color: Colors.white),
                      title: Text(
                          "${expense.note} - \$${expense.amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                          color: Colors.white,
                        ),),
                      subtitle: Text(DateFormat('MMM dd, yyyy')
                          .format(expense.date),
                              style: const TextStyle(
                          color: Colors.white,
                        ),),
                    );
                  },
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // home_screen.dart
  String getCategoryNameById(BuildContext context, String categoryId) {
    var category = Provider.of<ExpenseProvider>(context, listen: false)
        .categories
        .firstWhere((cat) => cat.id == categoryId, orElse: () => ExpenseCategory(id: categoryId, name: 'Desconhecida', isDefault: false)); // Added orElse
    return category.name;
  }
}