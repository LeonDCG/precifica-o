import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../database/db_helper.dart';
import '../models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

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
  double _commissionPercent = 30.0;
  String _saleUnitType = 'unit'; // 'unit' ou 'whole'
  
  bool _isLoading = true;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedProductsSummary;
    if (cached != null && cached.isNotEmpty) {
      _products = cached;
      _isLoading = false;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await DatabaseHelper.instance.readProductsSummary();
    final user = Supabase.instance.client.auth.currentUser;
    Profile? profile;
    if (user != null) {
      profile = await DatabaseHelper.instance.getProfile(user.id);
    }
    if (mounted) {
      setState(() {
        _products = prods;
        _profile = profile;
        if (_profile != null && _profile!.role == 'seller') {
          _sellerType = 'other';
          _sellerName = _profile!.name;
          _commissionPercent = _profile!.commissionPercent;
        }
        _isLoading = false;
      });
    }
  }

  double get _productCost {
    if (_selectedProduct == null) return 0.0;
    if (_saleUnitType == 'unit') {
      return _selectedProduct!.totalCost / _selectedProduct!.yieldAmount;
    } else {
      return _selectedProduct!.totalCost;
    }
  }

  double get _productPrice {
    if (_selectedProduct == null) return 0.0;
    double basePrice = _selectedProduct!.sellPrice > 0 ? _selectedProduct!.sellPrice : _selectedProduct!.suggestedPrice;
    if (_saleUnitType == 'unit') {
      return basePrice / _selectedProduct!.yieldAmount;
    } else {
      return basePrice;
    }
  }

  double get _effectiveSellPrice {
    return _customSellPrice > 0 ? _customSellPrice : _productPrice;
  }

  double get _totalSaleValue => _effectiveSellPrice * _quantity;
  double get _totalSaleCost => _productCost * _quantity;
  double get _totalSaleProfit => _totalSaleValue - _totalSaleCost;

  double get _commissionValue {
    if (_sellerType == 'me') return 0.0;
    // Comissão calculada sobre o LUCRO BRUTO da venda
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
      
      final suffix = _selectedProduct!.yieldAmount > 1 
          ? (_saleUnitType == 'unit' ? ' (${_selectedProduct!.unit})' : ' (Inteiro)')
          : '';
      final sale = Sale(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name + suffix,
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
      if (_profile != null && _profile!.role == 'seller') {
        await DatabaseHelper.instance.deductSellerStock(
          _profile!.id,
          sale.productId!,
          _quantity,
          yieldAmount: _selectedProduct!.yieldAmount,
          isSliceSale: _saleUnitType == 'unit',
        );
      } else {
        await DatabaseHelper.instance.deductStockForProduct(
          sale.productId!,
          _quantity,
          yieldAmount: _selectedProduct!.yieldAmount,
          isSliceSale: _saleUnitType == 'unit',
        );
      }
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
              items: _products.map<DropdownMenuItem<Product>>((p) {
                final price = p.sellPrice > 0 ? p.sellPrice : p.suggestedPrice;
                final unitPrice = p.yieldAmount > 1 ? price / p.yieldAmount : price;
                final details = p.yieldAmount > 1 
                    ? 'Inteiro: R\$ ${price.toStringAsFixed(2)} / ${p.unit}: R\$ ${unitPrice.toStringAsFixed(2)}'
                    : 'R\$ ${price.toStringAsFixed(2)}';
                return DropdownMenuItem<Product>(
                  value: p,
                  child: Text('${p.name} ($details)'),
                );
              }).toList(),
              validator: (v) => v == null ? 'Selecione um produto' : null,
              onChanged: (val) {
                setState(() {
                  _selectedProduct = val;
                  _customSellPrice = 0.0; // Reset preço customizado ao mudar produto
                  if (val != null && val.yieldAmount > 1) {
                    _saleUnitType = 'unit';
                  } else {
                    _saleUnitType = 'whole';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            if (_selectedProduct != null) ...[
              if (_selectedProduct!.yieldAmount > 1) ...[
                Text('Unidade de Venda:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('${_selectedProduct!.unit.toUpperCase()} (Fatia/Pedaço)'),
                      selected: _saleUnitType == 'unit',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _saleUnitType = 'unit';
                            _customSellPrice = 0.0;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('PRODUTO INTEIRO'),
                      selected: _saleUnitType == 'whole',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _saleUnitType = 'whole';
                            _customSellPrice = 0.0;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Quantidade e Preço de Venda
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('${_selectedProduct!.id}_${_saleUnitType}'),
                      initialValue: _quantity.toString(),
                      decoration: InputDecoration(
                        labelText: 'Qtd Vendida (${_saleUnitType == 'unit' ? _selectedProduct!.unit : 'inteiro'})',
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
              
              if (_profile?.role != 'seller') ...[
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
                    if (_profile?.role == 'seller') ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sua Comissão (${_commissionPercent.toStringAsFixed(0)}%):'),
                          Text('R\$ ${_commissionValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ] else ...[
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
