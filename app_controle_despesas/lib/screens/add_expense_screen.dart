import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_tag_dialog.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? initialExpense;

  const AddExpenseScreen({super.key, this.initialExpense});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String? _selectedCategoryId;
  String? _selectedTagId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.initialExpense?.amount.toString() ?? '');
    _noteController =
        TextEditingController(text: widget.initialExpense?.note ?? '');
    _selectedDate = widget.initialExpense?.date ?? DateTime.now();

    // Adicionado um Future.microtask para garantir que o provider esteja disponível
    // e as categorias/tags estejam carregadas.
    Future.microtask(() {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      // Tenta definir a categoria e tag selecionadas com base no initialExpense
  _selectedCategoryId = widget.initialExpense?.categoryId;
_selectedTagId = widget.initialExpense?.tag;

if ((_selectedCategoryId == null || !expenseProvider.categories.any((cat) => cat.id == _selectedCategoryId)) && expenseProvider.categories.isNotEmpty) {
  setState(() {
    _selectedCategoryId = expenseProvider.categories.first.id;
  });
}
if ((_selectedTagId == null || !expenseProvider.tags.any((tag) => tag.id == _selectedTagId)) && expenseProvider.tags.isNotEmpty) {
  setState(() {
    _selectedTagId = expenseProvider.tags.first.id;
  });
}
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text(
            widget.initialExpense == null ? 'Adicionar Despesa' : 'Editar Despesa'),
            foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(_amountController, 'Valor',
                const TextInputType.numberWithOptions(decimal: true)),
            buildTextField(_noteController, 'Descrição', TextInputType.text),
            buildDateField(_selectedDate),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildCategoryDropdown(expenseProvider),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildTagDropdown(expenseProvider),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _saveExpense,
          child: const Text('Salvar Despesa'),
        ),
      ),
    );
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty ||
        _selectedCategoryId == null || // <<< Verificação para categoria
        _selectedTagId == null) {      // <<< Verificação para tag
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios (Valor, Categoria e Tag)!')));
      return;
    }

    final expense = Expense(
  id: widget.initialExpense?.id ?? '', // ID vazio para novas despesas, Firebase irá gerar
  amount: double.parse(_amountController.text),
  categoryId: _selectedCategoryId!, 
  note: _noteController.text,
  date: _selectedDate,
  tag: _selectedTagId!, 
);

    Provider.of<ExpenseProvider>(context, listen: false)
        .addExpense(expense);
    Navigator.pop(context);
  }

  Widget buildTextField(
      TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          border: const OutlineInputBorder(),
        ),
        keyboardType: type,
      ),
    );
  }

  Widget buildDateField(DateTime selectedDate) {
    return ListTile(
      title: Text("Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
          style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.calendar_today, color: Colors.white),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
    );
  }

  Widget buildCategoryDropdown(ExpenseProvider provider) {
    // Usar 'Consumer' aqui para garantir que o Dropdown seja reconstruído
    // quando as categorias do provider mudarem (ex: após adicionar uma nova)
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Se não houver categorias, talvez exiba uma mensagem ou desabilite
        if (expenseProvider.categories.isEmpty) {
          return DropdownButtonFormField<String>(
            value: null,
            items: const [
              DropdownMenuItem(
                value: "Novo",
                child: Text("Adicionar Nova Categoria", style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (newValue) {
              if (newValue == 'Novo') {
                showDialog(
                  context: context,
                  builder: (context) => AddCategoryDialog(onAdd: (newCategory) {
                    setState(() {
                      // Note: O provider.addCategory() é assíncrono.
                      // A lista do provider será atualizada pela stream do Firebase.
                      // Aqui, apenas selecionamos a nova categoria.
                      _selectedCategoryId = newCategory.id;
                      expenseProvider.addCategory(newCategory); // Adicionar via provider
                    });
                  }),
                );
              }
            },
            decoration: const InputDecoration(
              labelText: 'Categoria',
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.white),
            ),
            dropdownColor: Colors.grey[900],
          );
        }

        // Se o _selectedCategoryId não estiver entre as categorias disponíveis,
        // ou se estiver nulo, defina um valor padrão (a primeira categoria)
        if (_selectedCategoryId == null || !expenseProvider.categories.any((cat) => cat.id == _selectedCategoryId)) {
          _selectedCategoryId = expenseProvider.categories.first.id;
        }


        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          dropdownColor: Colors.grey[900],
          onChanged: (newValue) {
            if (newValue == 'Novo') {
              showDialog(
                context: context,
                builder: (context) => AddCategoryDialog(onAdd: (newCategory) {
                  setState(() {
                    _selectedCategoryId = newCategory.id;
                    expenseProvider.addCategory(newCategory);
                  });
                }),
              );
            } else {
              setState(() => _selectedCategoryId = newValue);
            }
          },
          items: expenseProvider.categories.map<DropdownMenuItem<String>>((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name, style: const TextStyle(color: Colors.white)),
            );
          }).toList()
            ..add(const DropdownMenuItem(
                value: "Novo",
                child: Text("Adicionar Nova Categoria",
                    style: TextStyle(color: Colors.white)),
            )),
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget buildTagDropdown(ExpenseProvider provider) {
    // Usar 'Consumer' aqui também para reconstruir quando as tags mudarem
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.tags.isEmpty) {
           return DropdownButtonFormField<String>(
            value: null,
            items: const [
              DropdownMenuItem(
                value: "Novo",
                child: Text("Adicionar Nova Tag", style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (newValue) {
              if (newValue == 'Novo') {
                showDialog(
                  context: context,
                  builder: (context) => AddTagDialog(onAdd: (newTag) {
                    setState(() {
                      _selectedTagId = newTag.id;
                      expenseProvider.addTag(newTag);
                    });
                  }),
                );
              }
            },
            decoration: const InputDecoration(
              labelText: 'Tag',
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.white),
            ),
            dropdownColor: Colors.grey[900],
          );
        }

        if (_selectedTagId == null || !expenseProvider.tags.any((tag) => tag.id == _selectedTagId)) {
          _selectedTagId = expenseProvider.tags.first.id;
        }

        return DropdownButtonFormField<String>(
          value: _selectedTagId,
          dropdownColor: Colors.grey[900],
          onChanged: (newValue) {
            if (newValue == 'Novo') {
              showDialog(
                context: context,
                builder: (context) => AddTagDialog(onAdd: (newTag) {
                  expenseProvider.addTag(newTag);
                  setState(() => _selectedTagId = newTag.id);
                }),
              );
            } else {
              setState(() => _selectedTagId = newValue);
            }
          },
          items: expenseProvider.tags.map<DropdownMenuItem<String>>((tag) {
            return DropdownMenuItem<String>(
              value: tag.id,
              child: Text(tag.name, style: const TextStyle(color: Colors.white)),
            );
          }).toList()
            ..add(const DropdownMenuItem(
                value: "Novo",
                child: Text("Adicionar Nova Tag",
                    style: TextStyle(color: Colors.white)),
            )),
          decoration: const InputDecoration(
            labelText: 'Tag',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}