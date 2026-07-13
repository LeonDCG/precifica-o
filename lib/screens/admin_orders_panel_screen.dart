import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_request.dart';
import '../database/db_helper.dart';

class AdminOrdersPanelScreen extends StatefulWidget {
  const AdminOrdersPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersPanelScreen> createState() => _AdminOrdersPanelScreenState();
}

class _AdminOrdersPanelScreenState extends State<AdminOrdersPanelScreen> {
  bool _isLoading = true;
  List<OrderRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getAllOrderRequests();
      setState(() {
        _requests = list;
      });
    } catch (e) {
      debugPrint('Erro ao carregar pedidos dos vendedores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await DatabaseHelper.instance.updateOrderRequestStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido atualizado para $status')),
      );
      _loadRequests();
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
    }
  }

  Future<void> _deliverOrder(int id) async {
    try {
      await DatabaseHelper.instance.deliverOrderRequest(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estoque entregue e adicionado ao vendedor!')),
      );
      _loadRequests();
    } catch (e) {
      debugPrint('Erro ao entregar estoque: $e');
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
        title: Text('Pedidos de Vendedores', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Text('Nenhum pedido de vendedor recebido.', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final statusColor = _getStatusColor(req.status);
                      final formattedReqDate = '${req.requestedDate.day}/${req.requestedDate.month}/${req.requestedDate.year}';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    req.sellerName ?? 'Vendedor',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              const Divider(height: 24),
                              Text(
                                req.productName ?? 'Bolo',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text('Quantidade Solicitada: ${req.quantity.toStringAsFixed(0)}'),
                              Text('Data desejada: $formattedReqDate'),
                              
                              // Ações
                              if (req.status == 'pending' || req.status == 'approved') ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (req.status == 'pending') ...[
                                      TextButton(
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        onPressed: () => _updateStatus(req.id!, 'rejected'),
                                        child: const Text('Recusar'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                        onPressed: () => _updateStatus(req.id!, 'approved'),
                                        child: const Text('Aprovar', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                    if (req.status == 'approved') ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        icon: const Icon(Icons.delivery_dining, color: Colors.white),
                                        label: const Text('Entregar / Despachar', style: TextStyle(color: Colors.white)),
                                        onPressed: () => _deliverOrder(req.id!),
                                      ),
                                    ],
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
