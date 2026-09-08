import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile.dart';
import '../models/order_request.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class SellerOrdersScreen extends StatefulWidget {
  final Profile profile;
  const SellerOrdersScreen({super.key, required this.profile});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  bool _isLoading = true;
  List<OrderRequest> _requests = [];
  List<Product> _products = [];

  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  double _quantity = 1.0;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedProductsSummary;
    if (cached != null && cached.isNotEmpty) {
      _products = cached;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    if (_requests.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getSellerOrderRequests(widget.profile.id),
        DatabaseHelper.instance.readProductsSummary(),
      ]);
      if (mounted) {
        setState(() {
          _requests = results[0] as List<OrderRequest>;
          _products = results[1] as List<Product>;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar encomendas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      _formKey.currentState!.save();

      final request = OrderRequest(
        sellerId: widget.profile.id,
        productId: _selectedProduct!.id!,
        quantity: _quantity,
        requestedDate: _deliveryDate,
        status: 'pending',
      );

      try {
        await DatabaseHelper.instance.createOrderRequest(request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encomenda enviada com sucesso!')),
        );
        setState(() {
          _selectedProduct = null;
          _quantity = 1.0;
          _deliveryDate = DateTime.now().add(const Duration(days: 1));
        });
        _loadData();
      } catch (e) {
        debugPrint('Erro ao enviar encomenda: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'approved':
        return 'Aprovado';
      case 'delivered':
        return 'Entregue';
      case 'rejected':
        return 'Recusado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Encomendas', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Novo Pedido Card
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solicitar Reposição / Novo Pedido',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // Seleção do bolo
                            DropdownButtonFormField<Product>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Selecione o Bolo/Produto',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedProduct,
                              items: _products.map<DropdownMenuItem<Product>>((p) {
                                return DropdownMenuItem<Product>(
                                  value: p,
                                  child: Text(p.name),
                                );
                              }).toList(),
                              validator: (v) => v == null ? 'Selecione um produto' : null,
                              onChanged: (val) {
                                setState(() {
                                  _selectedProduct = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Quantidade e Data
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '1',
                                    decoration: const InputDecoration(
                                      labelText: 'Quantidade',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                                    onSaved: (v) {
                                      _quantity = double.tryParse(v!.replaceAll(',', '.')) ?? 1.0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDeliveryDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${_deliveryDate.day}/${_deliveryDate.month}'),
                                          const Icon(Icons.calendar_today, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _submitRequest,
                                child: const Text('Enviar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Histórico de Pedidos
                  Text(
                    'Histórico de Solicitações',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _requests.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('Nenhuma solicitação enviada ainda.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final req = _requests[index];
                            final statusColor = _getStatusColor(req.status);
                            final formattedReqDate = '${req.requestedDate.day}/${req.requestedDate.month}/${req.requestedDate.year}';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req.productName ?? 'Bolo',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Qtd: ${req.quantity.toStringAsFixed(0)}  •  Para: $formattedReqDate',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getStatusText(req.status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
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
    );
  }
}
