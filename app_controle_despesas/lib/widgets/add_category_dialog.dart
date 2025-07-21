import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(ExpenseCategory) onAdd;

  const AddCategoryDialog({super.key, required this.onAdd});

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      title: const Text('Adicionar Nova Categoria', 
                  style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nome da Categoria',
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Adicionar',
                  style: TextStyle(color: Colors.white)),
          onPressed: () {
            var newCategory = ExpenseCategory(
                id: DateTime.now().toString(), name: _controller.text);
            widget.onAdd(newCategory);
            Provider.of<ExpenseProvider>(context, listen: false)
                .addCategory(newCategory);
            _controller.clear(); 
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}