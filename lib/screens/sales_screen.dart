import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import 'add_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSales();
  }

  Future<void> _refreshSales() async {
    setState(() => _isLoading = true);
    final salesData = await DatabaseHelper.instance.readAllSales();
    setState(() {
      _sales = salesData;
      _isLoading = false;
    });
  }

  double get _totalRevenue {
    double sum = 0.0;
    for (var s in _sales) sum += s.totalValue;
    return sum;
  }

  double get _totalCommission {
    double sum = 0.0;
    for (var s in _sales) sum += s.commissionValue;
    return sum;
  }

  double get _totalNetProfit {
    double sum = 0.0;
    for (var s in _sales) sum += s.netProfit;
    return sum;
  }

  @override
  Widget build(BuildContext context) {
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Métricas Rápidas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumo de Vendas', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMetricCard(
                            'FATURAMENTO',
                            'R\$ ${_totalRevenue.toStringAsFixed(2)}',
                            Colors.blue[800]!,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricCard(
                            'COMISSÕES',
                            'R\$ ${_totalCommission.toStringAsFixed(2)}',
                            Colors.orange[800]!,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricCard(
                            'LUCRO LÍQUIDO',
                            'R\$ ${_totalNetProfit.toStringAsFixed(2)}',
                            Colors.green[800]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Histórico de Vendas', style: Theme.of(context).textTheme.titleLarge),
                      FloatingActionButton.extended(
                        mini: true,
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
                Expanded(
                  child: _sales.isEmpty
                      ? const Center(child: Text('Nenhuma venda registrada.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
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
                ),
              ],
            ),
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
