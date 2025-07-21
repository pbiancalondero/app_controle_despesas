import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/tag_management_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        title: 'Controle de Despesas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith( // Ajuste o tema para um visual escuro consistente
          primaryColor: Colors.black,
          scaffoldBackgroundColor: Colors.grey[800],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueAccent,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white54),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        // Use StreamBuilder para lidar com o estado de autenticação
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Exibir um indicador de carregamento enquanto verifica o estado de autenticação
              return const Scaffold(
                backgroundColor: Colors.grey,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }
            if (snapshot.hasData) {
              // Se o usuário estiver logado, vá para a HomeScreen
              return const HomeScreen();
            }
            // Se o usuário não estiver logado, vá para a LoginScreen
            return const LoginScreen();
          },
        ),
        routes: {
          '/manage_categories': (context) => const CategoryManagementScreen(),
          '/manage_tags': (context) => const TagManagementScreen(),
          // Se você quiser que a LoginScreen seja acessível via rota, pode adicioná-la aqui também,
          // mas 'home' já lida com o fluxo inicial.
          // '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
