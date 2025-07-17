import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../providers/expense_provider.dart';

class AddTagDialog extends StatefulWidget {
  final Function(Tag) onAdd;

  const AddTagDialog({super.key, required this.onAdd});

  @override
  _AddTagDialogState createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      title: const Text('Adicionar Nova Tag',style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nome da Tag',
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Adicionar',
          style: TextStyle(color: Colors.white)),
          onPressed: () {
            var newTag = Tag(id: DateTime.now().toString(), name: _controller.text);
            widget.onAdd(newTag);
            // Update the provider and UI
            Provider.of<ExpenseProvider>(context, listen: false).addTag(newTag);
            // Clear the input field for next input
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