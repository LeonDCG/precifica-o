import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../database/db_helper.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({Key? key}) : super(key: key);

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<Product> _products = [];
  Product? _selectedProduct;
  
  double _quantity = 1.0;
  double _customSellPrice = 0.0;
  DateTime _saleDate = DateTime.now();
  String _notes = '';
  
  String _sellerType = 'me'; // 'me' ou 'other'
  String _sellerName = '';
  double _commissionPercent = 10.0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  double get _productCost {
    if (_selectedProduct == null) return 0.0;
    return _selectedProduct!.totalCost / _selectedProduct!.yieldAmount;
  }

  double get _productPrice {
    if (_selectedProduct == null) return 0.0;
    return _selectedProduct!.sellPrice > 0 ? _selectedProduct!.sellPrice : _selectedProduct!.suggestedPrice;
  }

  double get _effectiveSellPrice {
    return _customSellPrice > 0 ? _customSellPrice : _productPrice;
  }

  double get _totalSaleValue => _effectiveSellPrice * _quantity;
  double get _totalSaleCost => _productCost * _quantity;
  double get _totalSaleProfit => _totalSaleValue - _totalSaleCost;

  double get _commissionValue {
    if (_sellerType == 'me') return 0.0;
    // Comissão calculada sobre o LUCRO da venda
    if (_totalSaleProfit <= 0) return 0.0;
    return _totalSaleProfit * (_commissionPercent / 100);
  }

  double get _netProfit => _totalSaleProfit - _commissionValue;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _saleDate = picked;
      });
    }
  }

  void _saveSale() async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      _formKey.currentState!.save();
      
      final sale = Sale(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        quantity: _quantity,
        totalValue: _totalSaleValue,
        totalCost: _totalSaleCost,
        totalProfit: _totalSaleProfit,
        sellerType: _sellerType,
        sellerName: _sellerType == 'me' ? 'Você' : _sellerName,
        commissionPercent: _sellerType == 'me' ? 0.0 : _commissionPercent,
        commissionValue: _commissionValue,
        netProfit: _netProfit,
        saleDate: _saleDate,
        notes: _notes,
      );
      
      await DatabaseHelper.instance.createSale(sale);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSale,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dropdown de seleção do produto
            DropdownButtonFormField<Product>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecione o Produto',
                border: OutlineInputBorder(),
              ),
              value: _selectedProduct,
              items: _products.map((p) {
                final price = p.sellPrice > 0 ? p.sellPrice : p.suggestedPrice;
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (R\$ ${price.toStringAsFixed(2)} / ${p.unit})'),
                );
              }).toList(),
              validator: (v) => v == null ? 'Selecione um produto' : null,
              onChanged: (val) {
                setState(() {
                  _selectedProduct = val;
                  _customSellPrice = 0.0; // Reset preço customizado ao mudar produto
                });
              },
            ),
            const SizedBox(height: 16),
            
            if (_selectedProduct != null) ...[
              // Quantidade e Preço de Venda
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _quantity.toString(),
                      decoration: InputDecoration(
                        labelText: 'Qtd Vendida (${_selectedProduct!.unit})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onChanged: (v) {
                        setState(() {
                          _quantity = double.tryParse(v.replaceAll(',', '.')) ?? 1.0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(_selectedProduct!.id),
                      initialValue: _productPrice.toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'Preço Praticado (R\$)',
                        border: OutlineInputBorder(),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {
                          _customSellPrice = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Seletor de Data
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data da Venda: ${_saleDate.day}/${_saleDate.month}/${_saleDate.year}'),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Vendedor (Quem vendeu?)
              Text('Quem realizou a venda?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Eu Mesmo'),
                    selected: _sellerType == 'me',
                    onSelected: (selected) {
                      if (selected) setState(() => _sellerType = 'me');
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Outra Pessoa'),
                    selected: _sellerType == 'other',
                    onSelected: (selected) {
                      if (selected) setState(() => _sellerType = 'other');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_sellerType == 'other') ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nome do Vendedor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _sellerType == 'other' && v!.isEmpty ? 'Obrigatório' : null,
                  onSaved: (v) => _sellerName = v ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _commissionPercent.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Comissão (% sobre o lucro)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      _commissionPercent = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Resumo Financeiro da Venda
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESUMO DA VENDA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor Total Recebido:'),
                        Text('R\$ ${_totalSaleValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Custo Total Proporcional:'),
                        Text('R\$ ${_totalSaleCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lucro Bruto:'),
                        Text('R\$ ${_totalSaleProfit.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _totalSaleProfit >= 0 ? Colors.green : Colors.red)),
                      ],
                    ),
                    if (_sellerType == 'other' && _totalSaleProfit > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Comissão do Vendedor ($_commissionPercent%):'),
                          Text('- R\$ ${_commissionValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seu Lucro Líquido Real:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('R\$ ${_netProfit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações (Opcional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
