import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Import the new LoginScreen

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('pt_BR', null);
    
    await Supabase.initialize(
      url: DatabaseHelper.supabaseUrl,
      anonKey: DatabaseHelper.supabaseAnonKey,
    );
    
    runApp(const PrecificacaoApp());
    
    // Carregar preferência de tema em background sem travar a abertura inicial
    DatabaseHelper.instance.getSetting('themeMode').then((themeStr) {
      if (themeStr == 'dark') {
        themeNotifier.value = ThemeMode.dark;
      }
    }).catchError((_) {});
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
    
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentThemeMode, __) {
        return MaterialApp(
          title: 'Doce & Ponto',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: session != null ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
