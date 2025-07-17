import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'package:firebase_database/firebase_database.dart'; // Nao precisa aqui

import 'providers/expense_provider.dart'; // Ative este import
import 'screens/home_screen.dart';       // Ative este import
import 'screens/category_management_screen.dart'; // Ative este import
import 'screens/tag_management_screen.dart';      // Ative este import


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <<< ESSENCIAL
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()), // Aqui o ExpenseProvider é criado
      ],
      child: MaterialApp(
        title: 'Controle de Despesas',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/manage_categories': (context) => const CategoryManagementScreen(),
          '/manage_tags': (context) => const TagManagementScreen(),
        },
      ),
    );
  }
}