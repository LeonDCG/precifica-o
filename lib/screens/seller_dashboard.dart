import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/sale.dart';
import '../database/db_helper.dart';
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
  List<Sale> _sellerSales = [];
  Map<int, String> _productImages = {};
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
      final results = await Future.wait([
        DatabaseHelper.instance.getSellerStock(widget.profile.id),
        DatabaseHelper.instance.getProductImages(),
        DatabaseHelper.instance.readAllSales(),
      ]);

      _consignedStock = results[0] as List<Map<String, dynamic>>;
      final images = results[1] as Map<int, String>;
      final sales = results[2] as List<Sale>;

      final List<Sale> filteredSales = [];
      double commissionSum = 0.0;

      final profileName = widget.profile.name.trim().toLowerCase();
      for (var s in sales) {
        if (s.sellerName.trim().toLowerCase() == profileName) {
          filteredSales.add(s);
          commissionSum += s.commissionValue;
        }
      }

      setState(() {
        _sellerSales = filteredSales;
        _productImages = images;
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

  String _getPlaceholderImage(int index) {
    final urls = [
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?auto=format&fit=crop&w=800&q=80',
    ];
    return urls[index % urls.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do Vendedor', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    const Text('Acompanhe suas vendas e estoque abaixo.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 20),

                    // Apenas o lucro de venda dele (Total Commission)
                    _buildMetricCard(
                      'LUCRO TOTAL DE SUAS VENDAS',
                      'R\$ ${_monthlyCommission.toStringAsFixed(2)}',
                      const Color(0xFFD4AF37), // Dourado
                    ),
                    const SizedBox(height: 24),

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
                                  subtitle: const Text('Estoque disponível com você'),
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
                    const SizedBox(height: 28),

                    // Cards da Venda
                    Text(
                      'Suas Vendas Realizadas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _sellerSales.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2B2724) : Colors.brown.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'Nenhuma venda registrada ainda.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _sellerSales.length,
                            itemBuilder: (context, index) {
                              final sale = _sellerSales[index];
                              final formattedDate = '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}';
                              final imageUrl = _productImages[sale.productId] ?? _getPlaceholderImage(sale.productId ?? index);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        // Background Image
                                        Positioned.fill(
                                          child: imageUrl.startsWith('data:')
                                              ? Image.memory(
                                                  base64Decode(imageUrl.split(',').last),
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        // Dark overlay
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withOpacity(0.65),
                                          ),
                                        ),
                                        
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      sale.productName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Qtd: ${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 1)}',
                                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Total: R\$ ${sale.totalValue.toStringAsFixed(2)}',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'Seu Lucro: R\$ ${sale.commissionValue.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          color: Colors.greenAccent,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 26,
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
