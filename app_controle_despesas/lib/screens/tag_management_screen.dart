import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_tag_dialog.dart';

class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text("Gerenciar Tags"),
        backgroundColor: Colors.black, // Themed color similar to your inspirations
        foregroundColor: Colors.white,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.tags.length,
            itemBuilder: (context, index) {
              final tag = provider.tags[index];
              return ListTile(
                title: Text(tag.name),textColor: const Color.fromARGB(255, 250, 255, 255),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Delete the tag
                    provider.deleteTag(tag.id);
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
            builder: (context) => AddTagDialog(
              onAdd: (newTag) {
                Provider.of<ExpenseProvider>(context, listen: false).addTag(newTag);
                Navigator.pop(context); // Close the dialog after adding the new tag
              },
            ),
          );
        },
        tooltip: 'Adicionar Nova Etiqueta',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}