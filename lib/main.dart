import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Import the new LoginScreen

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('pt_BR', null);
    
    await Supabase.initialize(
      url: 'https://jfpswioaikpflvjiylqa.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmcHN3aW9haWtwZmx2aml5bHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMzA3ODQsImV4cCI6MjA5NDkwNjc4NH0.lZmckQNXdD99KAWpdYoY9Eb5rRdcmVzQh9S67rXXPdM',
    );
    
    await DatabaseHelper.instance.seedData(); // Popula os dados iniciais se vazio!
    runApp(const PrecificacaoApp());
  } catch (e, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erro crítico ao iniciar:\n$e\n\nStack:\n$stack',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
  }
}

class PrecificacaoApp extends StatelessWidget {
  const PrecificacaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    
    return MaterialApp(
      title: 'Doce & Ponto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: session != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
