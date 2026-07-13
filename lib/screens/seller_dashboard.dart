import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../database/db_helper.dart';
import 'add_sale_screen.dart';
import 'login_screen.dart';

class SellerDashboard extends StatefulWidget {
  final Profile profile;
  const SellerDashboard({Key? key, required this.profile}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _consignedStock = [];
  double _monthlySalesRevenue = 0.0;
  double _monthlyCommission = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Carrega estoque consignado
      _consignedStock = await DatabaseHelper.instance.getSellerStock(widget.profile.id);

      // 2. Calcula receitas e comissões do mês
      final sales = await DatabaseHelper.instance.readAllSales();
      final now = DateTime.now();

      double revenueSum = 0.0;
      double commissionSum = 0.0;

      for (var s in sales) {
        if (s.sellerName == widget.profile.name || s.sellerName == 'Você') { // Tratamento para quando é o próprio vendedor
          final sDate = s.saleDate;
          if (sDate.year == now.year && sDate.month == now.month) {
            revenueSum += s.totalValue;
            commissionSum += s.commissionValue;
          }
        }
      }

      setState(() {
        _monthlySalesRevenue = revenueSum;
        _monthlyCommission = commissionSum;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do vendedor: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de Vendas', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Text(
                      'Olá, ${widget.profile.name}! 🍰',
                      style: GoogleFonts.merriweather(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Boas vendas hoje!', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 20),

                    // Resumo Financeiro
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'VENDIDO NO MÊS',
                            'R\$ ${_monthlySalesRevenue.toStringAsFixed(2)}',
                            Colors.blue[800]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'SUA COMISSÃO',
                            'R\$ ${_monthlyCommission.toStringAsFixed(2)}',
                            Colors.green[800]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Botão rápido para nova venda
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Registrar Nova Venda', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddSaleScreen()),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Estoque Consignado
                    Text(
                      'Seu Estoque Consignado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _consignedStock.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2B2724) : Colors.brown.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'Sem bolos consignados no momento.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Faça uma solicitação de estoque na aba Encomendar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _consignedStock.length,
                            itemBuilder: (context, index) {
                              final stock = _consignedStock[index];
                              final productName = stock['products']?['name'] ?? 'Bolo';
                              final qty = ((stock['quantity'] ?? 0.0) as num).toDouble();
                              final unit = stock['products']?['unit'] ?? 'unidade';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.cake, color: Colors.white, size: 20),
                                  ),
                                  title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Estoque disponível com você'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: qty > 0 ? Colors.teal.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${qty.toStringAsFixed(0)} $unit',
                                      style: TextStyle(
                                        color: qty > 0 ? Colors.teal : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
