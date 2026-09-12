import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';

class ImportIfoodScreen extends StatefulWidget {
  const ImportIfoodScreen({super.key});

  @override
  State<ImportIfoodScreen> createState() => _ImportIfoodScreenState();
}

class _ImportIfoodScreenState extends State<ImportIfoodScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Sale> _ifoodSales = [];
  List<Product> _products = [];
  bool _isLoading = true;

  // Controlador para colar dados brutos (CSV ou Linhas do Excel do iFood)
  final TextEditingController _rawTextController = TextEditingController();
  List<Map<String, dynamic>> _parsedOrders = [];
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allSales = await DatabaseHelper.instance.readAllSales();
      final products = await DatabaseHelper.instance.readAllProducts();
      
      final ifoodList = allSales.where((s) => s.isIfood).toList();
      // Ordenar pelas datas mais recentes
      ifoodList.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      if (mounted) {
        setState(() {
          _ifoodSales = ifoodList;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do iFood: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Análise de linhas coladas do Excel do iFood
  void _parseRawInput(String text) {
    if (text.trim().isEmpty) {
      setState(() => _parsedOrders = []);
      return;
    }

    setState(() => _isParsing = true);
    final lines = text.trim().split('\n');
    final List<Map<String, dynamic>> orders = [];

    for (var line in lines) {
      final cols = line.contains('\t') ? line.split('\t') : line.split(';');
      if (cols.length < 5) continue; // Linha inválida ou cabeçalho curto

      // Procurar código de pedido (ex: 4 dígitos ou UUID)
      String shortId = '';
      String rawDate = '';
      String turno = 'JANTAR';
      double itemsValue = 0.0;
      double liquidValue = 0.0;
      double feeValue = 0.0;
      String payment = 'App';

      for (var col in cols) {
        final clean = col.trim().replaceAll('"', '');
        // Data no formato DD/MM/AAAA
        if (clean.contains('/') && clean.contains(':')) {
          rawDate = clean;
        } else if (clean.length == 4 && int.tryParse(clean) != null) {
          shortId = clean;
        } else if (['JANTAR', 'ALMOÇO', 'ALMOCO', 'CAFÉ DA TARDE', 'MANHÃ'].contains(clean.toUpperCase())) {
          turno = clean.toUpperCase();
        } else if (clean.startsWith('R\$') || clean.contains(',') || clean.contains('.')) {
          final numStr = clean.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
          final val = double.tryParse(numStr);
          if (val != null && val > 0) {
            if (itemsValue == 0) {
              itemsValue = val;
            } else if (liquidValue == 0 && val < itemsValue) {
              liquidValue = val;
            }
          }
        }
      }

      if (itemsValue > 0) {
        if (feeValue == 0 && liquidValue > 0) {
          feeValue = itemsValue - liquidValue;
        } else if (feeValue == 0) {
          feeValue = itemsValue * 0.262; // Taxa padrão de 26,2%
          liquidValue = itemsValue - feeValue;
        }

        // Verificar se já existe cadastrado
        final alreadyImported = _ifoodSales.any((s) => shortId.isNotEmpty && s.notes.contains('#$shortId'));

        orders.add({
          'shortId': shortId.isEmpty ? 'AUTO' : shortId,
          'date': rawDate.isNotEmpty ? rawDate : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          'turno': turno,
          'itemsValue': itemsValue,
          'feeValue': feeValue,
          'liquidValue': liquidValue,
          'payment': payment,
          'alreadyImported': alreadyImported,
        });
      }
    }

    setState(() {
      _parsedOrders = orders;
      _isParsing = false;
    });
  }

  Future<void> _importParsedOrders() async {
    final toImport = _parsedOrders.where((o) => o['alreadyImported'] == false).toList();
    if (toImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum pedido novo para importar.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    int importedCount = 0;

    for (var o in toImport) {
      try {
        DateTime saleDate = DateTime.now();
        if (o['date'] != null && o['date'].toString().contains('/')) {
          try {
            saleDate = DateFormat('dd/MM/yyyy HH:mm:ss').parse(o['date']);
          } catch (_) {
            try {
              saleDate = DateFormat('dd/MM/yyyy').parse(o['date']);
            } catch (_) {}
          }
        }

        final itemsVal = (o['itemsValue'] as num).toDouble();
        final feeVal = (o['feeValue'] as num).toDouble();
        final liqVal = (o['liquidValue'] as num).toDouble();
        final shortId = o['shortId'].toString();
        final turno = o['turno'].toString();

        final qty = (itemsVal / 21.0).round().toDouble().clamp(1.0, 10.0);
        final cost = qty * 4.50; // Custo estimado
        final totProfit = itemsVal - cost;
        final netProfit = liqVal - cost;

        final newSale = Sale(
          productId: _products.isNotEmpty ? _products.first.id : 32,
          productName: qty > 1 ? 'Slice Cake - ${qty.toInt()} un (Pedido iFood #$shortId)' : 'Slice Cake - 1 un (Pedido iFood #$shortId)',
          quantity: qty,
          totalValue: itemsVal,
          totalCost: cost,
          totalProfit: totProfit,
          sellerType: 'ifood',
          sellerName: 'iFood (Plano Entrega)',
          commissionPercent: 26.2,
          commissionValue: feeVal,
          netProfit: netProfit,
          saleDate: saleDate,
          notes: '[Pedido iFood #$shortId] $turno',
        );

        await DatabaseHelper.instance.insertSale(newSale);
        importedCount++;
      } catch (e) {
        debugPrint('Erro ao importar pedido ${o['shortId']}: $e');
      }
    }

    DatabaseHelper.instance.clearSalesCache();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount pedidos do iFood importados com sucesso!'),
          backgroundColor: Colors.green[700],
        ),
      );
      _rawTextController.clear();
      setState(() => _parsedOrders = []);
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estatísticas calculadas das vendas iFood
    final totalRevenue = _ifoodSales.fold(0.0, (acc, s) => acc + s.totalValue);
    final totalFees = _ifoodSales.fold(0.0, (acc, s) => acc + s.commissionValue);
    final totalNet = _ifoodSales.fold(0.0, (acc, s) => acc + (s.totalValue - s.commissionValue));
    final totalNetProfit = _ifoodSales.fold(0.0, (acc, s) => acc + s.netProfit);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Color(0xFFEA1D2C), size: 28),
            const SizedBox(width: 8),
            Text(
              'Relatórios iFood',
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEA1D2C),
          labelColor: const Color(0xFFEA1D2C),
          tabs: [
            Tab(icon: const Icon(Icons.receipt_long), text: 'Conciliados (${_ifoodSales.length})'),
            const Tab(icon: Icon(Icons.file_upload_outlined), text: 'Importar Planilha'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ABA 1: CONCILIAÇÃO E HISTÓRICO
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de Destaque da Conta iFood
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA1D2C), Color(0xFFB71C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEA1D2C).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CONTA IFOOD OFICIAL',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Taxa: 26,2%',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Faturamento Bruto', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(
                                        'R\$ ${totalRevenue.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Repasse Líquido', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(
                                        'R\$ ${totalNet.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Taxas Retidas (26,2%): -R\$ ${totalFees.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
                                  ),
                                  Text(
                                    'Lucro Líquido: R\$ ${totalNetProfit.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card de Insights Operacionais
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.analytics_outlined, color: Color(0xFFEA1D2C), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Métricas Operacionais do Delivery',
                                      style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInsightItem(Icons.nightlight_round, '73,3%', 'Pico no Jantar', Colors.indigo),
                                    _buildInsightItem(Icons.timer_outlined, '12 min', 'Preparo Médio', Colors.green),
                                    _buildInsightItem(Icons.motorcycle_outlined, '2,5 min', 'Espera Motoboy', Colors.orange),
                                    _buildInsightItem(Icons.map_outlined, '2,6 km', 'Raio Médio', Colors.teal),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Pedidos Concluídos no Relatório',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        if (_ifoodSales.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('Nenhum pedido do iFood registrado.'),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _ifoodSales.length,
                            itemBuilder: (context, index) {
                              final sale = _ifoodSales[index];
                              final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFEA1D2C).withValues(alpha: 0.1),
                                        child: const Icon(Icons.delivery_dining, color: Color(0xFFEA1D2C), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sale.productName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '$dateFormatted • ${sale.notes}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'R\$ ${sale.totalValue.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Líq: R\$ ${(sale.totalValue - sale.commissionValue).toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // ABA 2: IMPORTAR PLANILHA / COLAR
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cole aqui as linhas copiadas da planilha de vendas do iFood (.xlsx ou Portal do Parceiro). O sistema reconhece automaticamente os códigos, valores e turnos.',
                                style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _rawTextController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Dados do Relatório de Vendas iFood',
                          hintText: 'Cole aqui o conteúdo copiado do Excel...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _parseRawInput,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Limpar'),
                            onPressed: () {
                              _rawTextController.clear();
                              setState(() => _parsedOrders = []);
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA1D2C),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.upload, size: 18),
                            label: Text('Importar (${_parsedOrders.where((o) => !o['alreadyImported']).length} Novos)'),
                            onPressed: _parsedOrders.isEmpty ? null : _importParsedOrders,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (_isParsing)
                        const Center(child: CircularProgressIndicator())
                      else if (_parsedOrders.isNotEmpty) ...[
                        Text(
                          'Prévia dos Pedidos Reconhecidos (${_parsedOrders.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ..._parsedOrders.map((o) {
                          final isNew = o['alreadyImported'] == false;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isNew ? Icons.add_circle : Icons.check_circle,
                              color: isNew ? Colors.green : Colors.grey,
                            ),
                            title: Text('Pedido #${o['shortId']} • ${o['turno']}'),
                            subtitle: Text('${o['date']} • Bruto: R\$ ${(o['itemsValue'] as double).toStringAsFixed(2)}'),
                            trailing: Text(
                              isNew ? 'NOVO' : 'JÁ IMPORTADO',
                              style: TextStyle(
                                color: isNew ? Colors.green[700] : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInsightItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
