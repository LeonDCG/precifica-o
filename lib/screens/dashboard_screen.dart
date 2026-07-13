import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import 'login_screen.dart';
import 'add_recipe_screen.dart';
import 'add_product_screen.dart';
import 'add_sale_screen.dart';
import '../main.dart'; // Para acessar o themeNotifier
import 'home_screen.dart';
import 'refrigerator_stock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _desiredSalary = 2000.0;
  double _workedHoursPerMonth = 160.0;
  List<Product> _products = [];
  double _monthlyTarget = 0.0;
  double _monthlyNetProfit = 0.0;

  double get _hourlyRate => _workedHoursPerMonth > 0 ? _desiredSalary / _workedHoursPerMonth : 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final salaryStr = await DatabaseHelper.instance.getSetting('desiredSalary');
      final hoursStr = await DatabaseHelper.instance.getSetting('workedHoursPerMonth');
      final targetStr = await DatabaseHelper.instance.getSetting('salesTarget');
      
      if (salaryStr != null) _desiredSalary = double.tryParse(salaryStr) ?? 2000.0;
      if (hoursStr != null) _workedHoursPerMonth = double.tryParse(hoursStr) ?? 160.0;
      if (targetStr != null) _monthlyTarget = double.tryParse(targetStr) ?? 0.0;
      
      _products = await DatabaseHelper.instance.readAllProducts();

      // Calcular Lucro Mensal Real
      final sales = await DatabaseHelper.instance.readAllSales();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      double monthlyProfitSum = 0.0;
      for (var s in sales) {
        final sDate = DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day);
        if (sDate.compareTo(monthStart) >= 0) {
          monthlyProfitSum += s.netProfit;
        }
      }
      _monthlyNetProfit = monthlyProfitSum;
    } catch (e, stack) {
      debugPrint('Erro ao carregar dados do Dashboard: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLaborConfigDialog() async {
    final salaryController = TextEditingController(text: _desiredSalary.toStringAsFixed(2));
    final hoursController = TextEditingController(text: _workedHoursPerMonth.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar Mão de Obra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salário Desejado (R\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Horas trabalhadas no mês',
                  helperText: 'Ex: 40h/semana * 4 = 160h',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSalary = double.tryParse(salaryController.text.replaceAll(',', '.')) ?? 0.0;
                final newHours = double.tryParse(hoursController.text.replaceAll(',', '.')) ?? 0.0;
                
                await DatabaseHelper.instance.saveSetting('desiredSalary', newSalary.toString());
                await DatabaseHelper.instance.saveSetting('workedHoursPerMonth', newHours.toString());
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia! 🍰';
    } else if (hour < 18) {
      return 'Boa tarde! 🍰';
    } else {
      return 'Boa noite! 🍰';
    }
  }

  Widget _buildCircularProgressRing() {
    final progress = _monthlyTarget > 0 ? (_monthlyNetProfit / _monthlyTarget).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2724) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.brown.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUCRO DESTE MÊS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${_monthlyNetProfit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthlyTarget > 0 
                      ? 'Meta: R\$ ${_monthlyTarget.toStringAsFixed(0)}'
                      : 'Nenhuma meta de lucro definida.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String label, IconData icon, Color color, Widget? screen, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF37312C) : color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () async {
          if (onTap != null) {
            onTap();
          } else if (screen != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDark ? Theme.of(context).colorScheme.secondary : color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Doce & Ponto', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // Botão Chaveador Modo Escuro
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.yellow : Colors.black),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () async {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              await DatabaseHelper.instance.saveSetting('themeMode', isDark ? 'light' : 'dark');
              themeNotifier.value = newMode;
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Saudação Personalizada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.brown, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Text(
                        'Doce & Ponto Confeitaria',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Progresso Circular
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCircularProgressRing(),
            ),

            // Atalhos Rápidos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildQuickActionCard(
                        context,
                        'Registrar Venda',
                        Icons.add_shopping_cart,
                        Colors.green,
                        const AddSaleScreen(),
                      ),
                      _buildQuickActionCard(
                        context,
                        'Geladeira Virtual',
                        Icons.kitchen,
                        Colors.teal,
                        const RefrigeratorStockScreen(),
                      ),
                      _buildQuickActionCard(
                        context,
                        'Nova Receita',
                        Icons.restaurant_menu,
                        Colors.blue,
                        const AddRecipeScreen(),
                      ),
                      _buildQuickActionCard(
                        context,
                        'Novo Produto',
                        Icons.cake,
                        Colors.purple,
                        const AddProductScreen(),
                      ),
                      _buildQuickActionCard(
                        context,
                        'Meta Mensal',
                        Icons.flag,
                        Colors.orange,
                        null,
                        onTap: () {
                          final homeState = context.findAncestorStateOfType<HomeScreenState>();
                          if (homeState != null) {
                            homeState.setTab(4); // Switch to Vendas tab
                          }
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        'Novo Insumo',
                        Icons.inventory_2,
                        Colors.amber,
                        null,
                        onTap: () {
                          final homeState = context.findAncestorStateOfType<HomeScreenState>();
                          if (homeState != null) {
                            homeState.setTab(1); // Switch to Insumos tab
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cartão de Mão de Obra
                  Card(
                    elevation: 4,
                    shadowColor: Colors.brown.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CUSTO DA MÃO DE OBRA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                                onPressed: _showLaborConfigDialog,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('R\$ ${_hourlyRate.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32, color: Theme.of(context).primaryColor)),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6.0, left: 4.0),
                                child: Text('/hora', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('SALÁRIO DESEJADO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text('R\$ ${_desiredSalary.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('HORAS/MÊS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text('${_workedHoursPerMonth.toStringAsFixed(0)}h', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Resumo do Catálogo', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2724) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.brown.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cake, color: Colors.brown, size: 32),
                              const SizedBox(height: 8),
                              Text('${_products.length}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                              const Text('Produtos', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.trending_up, color: Theme.of(context).primaryColor, size: 32),
                              const SizedBox(height: 8),
                              Text('100%', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24, color: Theme.of(context).primaryColor)),
                              Text('Lucro Médio', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
