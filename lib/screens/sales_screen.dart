import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import 'add_sale_screen.dart';
import '../models/profile.dart';

class SalesScreen extends StatefulWidget {
  final Profile? profile;
  const SalesScreen({Key? key, this.profile}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'all'
  double _monthlyTarget = 0.0;

  @override
  void initState() {
    super.initState();
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
    setState(() => _isLoading = true);
    try {
      var salesData = await DatabaseHelper.instance.readAllSales();
      if (widget.profile != null && widget.profile!.role == 'seller') {
        salesData = salesData.where((s) => s.sellerName == widget.profile!.name || s.sellerName == 'Você').toList();
      }
      if (mounted) {
        setState(() {
          _sales = salesData;
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
                            Expanded(
                              child: _buildMetricCard(
                                'FATURAMENTO',
                                'R\$ ${_totalRevenue.toStringAsFixed(2)}',
                                Colors.blue[800]!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                'COMISSÕES',
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
                                      const Text('Ticket Médio', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text('R\$ ${_ticketMedio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  if (_selectedPeriod == 'month') ...[
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
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  sale.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Data: $formattedDate  •  Vendedor: ${sale.sellerName}\nQtd: ${sale.quantity.toStringAsFixed(0)}  •  Faturamento: R\$ ${sale.totalValue.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Lucro: R\$ ${sale.netProfit.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (sale.commissionValue > 0)
                                          Text(
                                            'Comissão: R\$ ${sale.commissionValue.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        await DatabaseHelper.instance.deleteSale(sale.id!);
                                        _refreshSales();
                                      },
                                    ),
                                  ],
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
