import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_category_dialog.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text("Gerenciar Categorias"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                title: Text(category.name), textColor: const Color.fromARGB(255, 250, 255, 255),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    provider.deleteCategory(category.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddCategoryDialog(
              onAdd: (newCategory) {
                Provider.of<ExpenseProvider>(context, listen: false)
                    .addCategory(newCategory);
                Navigator.pop(context);
              },
            ),
          );
        },
        tooltip: 'Adicionar Nova Categoria',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}