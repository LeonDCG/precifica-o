import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import 'add_sale_screen.dart';
import '../models/profile.dart';
import '../widgets/app_cached_image.dart';

class SalesScreen extends StatefulWidget {
  final Profile? profile;
  const SalesScreen({super.key, this.profile});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'all'
  double _monthlyTarget = 0.0;
  Map<int, String> _productImages = {};

  @override
  void initState() {
    super.initState();
    final cached = widget.profile != null && widget.profile!.role == 'seller'
        ? DatabaseHelper.instance.getCachedSellerSales(widget.profile!.name)
        : DatabaseHelper.instance.cachedSales;
    if (cached != null && cached.isNotEmpty) {
      _sales = cached;
      _isLoading = false;
    }
    _refreshSales();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final targetStr = await DatabaseHelper.instance.getSetting('salesTarget');
    if (targetStr != null) {
      setState(() {
        _monthlyTarget = double.tryParse(targetStr) ?? 0.0;
      });
    }
  }

  void _showSetTargetDialog() {
    final controller = TextEditingController(text: _monthlyTarget > 0 ? _monthlyTarget.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Meta de Lucro do Mês'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Valor da Meta (R\$)',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newTarget = double.tryParse(controller.text) ?? 0.0;
              await DatabaseHelper.instance.saveSetting('salesTarget', newTarget.toString());
              setState(() {
                _monthlyTarget = newTarget;
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSales() async {
    if (!mounted) return;
    if (_sales.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final Future<List<Sale>> salesFuture;
      if (widget.profile != null && widget.profile!.role == 'seller') {
        salesFuture = DatabaseHelper.instance.readSalesForSeller(widget.profile!.name);
      } else {
        salesFuture = DatabaseHelper.instance.readAllSales();
      }

      final results = await Future.wait([
        salesFuture,
        DatabaseHelper.instance.getProductImages(),
      ]);
      final salesData = results[0] as List<Sale>;
      final images = results[1] as Map<int, String>;

      if (mounted) {
        setState(() {
          _sales = salesData;
          _productImages = images;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar vendas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  List<Sale> get _filteredSales {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);

    return _sales.where((s) {
      final sDate = DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day);
      if (_selectedPeriod == 'day') {
        return sDate.isAtSameMomentAs(todayStart);
      } else if (_selectedPeriod == 'week') {
        return sDate.compareTo(weekStart) >= 0;
      } else if (_selectedPeriod == 'month') {
        return sDate.compareTo(monthStart) >= 0;
      }
      return true; // 'all'
    }).toList();
  }

  double get _totalRevenue {
    double sum = 0.0;
    for (var s in _filteredSales) sum += s.totalValue;
    return sum;
  }

  double get _totalCommission {
    double sum = 0.0;
    for (var s in _filteredSales) sum += s.commissionValue;
    return sum;
  }

  double get _totalNetProfit {
    double sum = 0.0;
    for (var s in _filteredSales) sum += s.netProfit;
    return sum;
  }

  double get _ticketMedio {
    final list = _filteredSales;
    if (list.isEmpty) return 0.0;
    return _totalRevenue / list.length;
  }

  List<MapEntry<String, double>> get _topProducts {
    final Map<String, double> counts = {};
    for (var s in _filteredSales) {
      counts[s.productName] = (counts[s.productName] ?? 0.0) + s.quantity;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredSales;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.point_of_sale, size: 24),
            const SizedBox(width: 8),
            Text('Vendas', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Métricas Rápidas e Período
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Resumo de Vendas', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Filtro de Período (ChoiceChips)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPeriodChip('Hoje', 'day'),
                            _buildPeriodChip('7 Dias', 'week'),
                            _buildPeriodChip('Este Mês', 'month'),
                            _buildPeriodChip('Tudo', 'all'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (widget.profile?.role != 'seller') ...[
                              Expanded(
                                child: _buildMetricCard(
                                  'FATURAMENTO',
                                  'R\$ ${_totalRevenue.toStringAsFixed(2)}',
                                  Colors.blue[800]!,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: _buildMetricCard(
                                widget.profile?.role == 'seller' ? 'LUCRO DE SUAS VENDAS' : 'COMISSÕES',
                                'R\$ ${_totalCommission.toStringAsFixed(2)}',
                                Colors.orange[800]!,
                              ),
                            ),
                            if (widget.profile?.role != 'seller') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricCard(
                                  'LUCRO LÍQUIDO',
                                  'R\$ ${_totalNetProfit.toStringAsFixed(2)}',
                                  Colors.green[800]!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Insights do Período
                  if (list.isNotEmpty) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.analytics_outlined, size: 16, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  'INSIGHTS DO PERÍODO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Volume de Vendas', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text('${list.length} transações', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.profile?.role == 'seller' ? 'Comissões no Período' : 'Ticket Médio',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.profile?.role == 'seller'
                                            ? 'R\$ ${_totalCommission.toStringAsFixed(2)}'
                                            : 'R\$ ${_ticketMedio.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_topProducts.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              Text(
                                'Produtos Mais Vendidos:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              ..._topProducts.asMap().entries.map((entry) {
                                final idx = entry.key + 1;
                                final name = entry.value.key;
                                final qty = entry.value.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Row(
                                    children: [
                                      Text('$idxº ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 11)),
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        '${qty.toStringAsFixed(0)} un.',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Card de Meta Mensal
                  if (_selectedPeriod == 'month' && widget.profile?.role != 'seller') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.flag_outlined, size: 16, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'META DE LUCRO MENSAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit, size: 14, color: Colors.grey),
                                    onPressed: _showSetTargetDialog,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_monthlyTarget <= 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Nenhuma meta definida para este mês.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _showSetTargetDialog,
                                      child: const Text('Definir Meta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Builder(
                                  builder: (context) {
                                    final progress = _monthlyTarget > 0 ? (_totalNetProfit / _monthlyTarget).clamp(0.0, 1.0) : 0.0;
                                    final percent = (progress * 100).toStringAsFixed(0);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'R\$ ${_totalNetProfit.toStringAsFixed(2)} de R\$ ${_monthlyTarget.toStringAsFixed(0)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              '$percent%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.secondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.secondary,
                                            ),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Histórico de Vendas', style: Theme.of(context).textTheme.titleLarge),
                        FloatingActionButton.extended(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddSaleScreen()),
                            );
                            if (result == true) {
                              _refreshSales();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nova Venda'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista de Vendas
                  list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: Text('Nenhuma venda no período selecionado.')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final sale = list[index];
                            final formattedDate = '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}';
                                       final imageUrl = _productImages[sale.productId] ?? _getPlaceholderImage(sale.productId ?? index);
                            final isSellerSale = sale.sellerType == 'other' || (sale.sellerName.isNotEmpty && sale.sellerName != 'Você');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                height: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Background Image otimizada com AppCachedImage
                                      Positioned.fill(
                                        child: AppCachedImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          cacheWidth: 500,
                                          cacheHeight: 300,
                                        ),
                                      ),
                                      // Dark overlay
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.65),
                                        ),
                                      ),
                                      
                                      // Content
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Top Row: Product Name & Badges + Delete
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        sale.productName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Data: $formattedDate',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                
                                                // Badges + Delete
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isSellerSale)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFD4AF37), // Dourado
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.store, color: Colors.black, size: 12),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              sale.sellerName.toUpperCase(),
                                                              style: const TextStyle(
                                                                color: Colors.black,
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.teal.withOpacity(0.85),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.person, color: Colors.white, size: 12),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'VENDA DIRETA',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: EdgeInsets.zero,
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                      onPressed: () async {
                                                        await DatabaseHelper.instance.deleteSale(sale.id!);
                                                        _refreshSales();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            
                                             // Bottom Row: Sale metrics
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
                                                     if (widget.profile?.role != 'seller') ...[
                                                       const SizedBox(height: 2),
                                                       Text(
                                                         'Total: R\$ ${sale.totalValue.toStringAsFixed(2)}',
                                                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                       ),
                                                     ],
                                                   ],
                                                 ),
                                                 Column(
                                                   crossAxisAlignment: CrossAxisAlignment.end,
                                                   children: [
                                                     if (widget.profile?.role != 'seller') ...[
                                                        Text(
                                                          'Lucro Conf.: R\$ ${sale.netProfit.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            color: Colors.greenAccent,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        if (sale.commissionValue > 0) ...[
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Comissão (${sale.commissionPercent.toStringAsFixed(0)}% lucro): R\$ ${sale.commissionValue.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                              color: Colors.orangeAccent,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ] else ...[
                                                        Text(
                                                          'Sua Comissão: R\$ ${sale.commissionValue.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            color: Colors.greenAccent,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = period;
          });
        }
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
