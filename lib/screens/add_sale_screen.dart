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
  
  String _sellerType = 'me'; // 'me', 'ifood' ou 'other'
  String _sellerName = '';
  double _commissionPercent = 30.0;
  String _saleUnitType = 'unit'; // 'unit' ou 'whole'

  // iFood settings:
  String _ifoodPlan = 'delivery'; // 'delivery' (Plano Entrega 27%), 'basic' (Plano Básico 15.2%), 'custom'
  double _ifoodRate = 27.0; // 27.0% default for Plano Entrega as user specified
  String _ifoodOrderCode = '';
  double _ifoodDiscount = 0.0;
  
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
    if (_sellerType == 'ifood') {
      // Retenção do iFood: taxa sobre valor bruto dos itens + cupom da loja
      return (_totalSaleValue * (_ifoodRate / 100)) + _ifoodDiscount;
    }
    // Comissão de vendedor parceiro sobre o lucro bruto da venda
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

      String effectiveSellerName;
      double effectiveCommissionPercent;
      String effectiveNotes = _notes;

      if (_sellerType == 'me') {
        effectiveSellerName = 'Você';
        effectiveCommissionPercent = 0.0;
      } else if (_sellerType == 'ifood') {
        effectiveSellerName = _ifoodPlan == 'basic'
            ? 'iFood (Básico)'
            : (_ifoodPlan == 'custom' ? 'iFood' : 'iFood (Plano Entrega)');
        effectiveCommissionPercent = _ifoodRate;
        if (_ifoodOrderCode.trim().isNotEmpty) {
          final prefix = '[Pedido iFood #${_ifoodOrderCode.trim().replaceAll('#', '')}]';
          effectiveNotes = effectiveNotes.isEmpty ? prefix : '$prefix $effectiveNotes';
        }
      } else {
        effectiveSellerName = _sellerName;
        effectiveCommissionPercent = _commissionPercent;
      }

      final sale = Sale(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name + suffix,
        quantity: _quantity,
        totalValue: _totalSaleValue,
        totalCost: _totalSaleCost,
        totalProfit: _totalSaleProfit,
        sellerType: _sellerType,
        sellerName: effectiveSellerName,
        commissionPercent: effectiveCommissionPercent,
        commissionValue: _commissionValue,
        netProfit: _netProfit,
        saleDate: _saleDate,
        notes: effectiveNotes,
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
                Text('Canal / Modalidade de Venda:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _sellerType = 'me'),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _sellerType == 'me'
                                ? Colors.teal.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _sellerType == 'me' ? Colors.teal : Colors.grey.withValues(alpha: 0.3),
                              width: _sellerType == 'me' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.storefront, color: _sellerType == 'me' ? Colors.teal : Colors.grey, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'Venda Direta',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _sellerType == 'me' ? FontWeight.bold : FontWeight.normal,
                                  color: _sellerType == 'me' ? Colors.teal : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _sellerType = 'ifood'),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _sellerType == 'ifood'
                                ? const Color(0xFFEA1D2C).withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _sellerType == 'ifood' ? const Color(0xFFEA1D2C) : Colors.grey.withValues(alpha: 0.3),
                              width: _sellerType == 'ifood' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.delivery_dining, color: _sellerType == 'ifood' ? const Color(0xFFEA1D2C) : Colors.grey, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'iFood',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _sellerType == 'ifood' ? FontWeight.bold : FontWeight.normal,
                                  color: _sellerType == 'ifood' ? const Color(0xFFEA1D2C) : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _sellerType = 'other'),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _sellerType == 'other'
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _sellerType == 'other' ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.3),
                              width: _sellerType == 'other' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.handshake_outlined, color: _sellerType == 'other' ? const Color(0xFFB8860B) : Colors.grey, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'Vendedor',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _sellerType == 'other' ? FontWeight.bold : FontWeight.normal,
                                  color: _sellerType == 'other' ? const Color(0xFFB8860B) : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Configurações do iFood
                if (_sellerType == 'ifood') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA1D2C).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEA1D2C).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA1D2C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'DETALHES DO PEDIDO IFOOD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA1D2C),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Plano iFood:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              avatar: const Icon(Icons.two_wheeler, size: 16),
                              label: const Text('Plano Entrega (27%)'),
                              selected: _ifoodPlan == 'delivery',
                              selectedColor: const Color(0xFFEA1D2C).withValues(alpha: 0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _ifoodPlan = 'delivery';
                                    _ifoodRate = 27.0;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.store, size: 16),
                              label: const Text('Plano Básico (15,2%)'),
                              selected: _ifoodPlan == 'basic',
                              selectedColor: const Color(0xFFEA1D2C).withValues(alpha: 0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _ifoodPlan = 'basic';
                                    _ifoodRate = 15.2;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.tune, size: 16),
                              label: const Text('Personalizado'),
                              selected: _ifoodPlan == 'custom',
                              selectedColor: const Color(0xFFEA1D2C).withValues(alpha: 0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _ifoodPlan = 'custom';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        if (_ifoodPlan == 'custom') ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: _ifoodRate.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Taxa Total iFood (%)',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              setState(() {
                                _ifoodRate = double.tryParse(v.replaceAll(',', '.')) ?? 27.0;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Nº do Pedido iFood',
                                  hintText: 'Ex: 4821',
                                  prefixText: '# ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => _ifoodOrderCode = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Cupom Loja (R\$)',
                                  hintText: '0,00',
                                  prefixText: 'R\$ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  setState(() {
                                    _ifoodDiscount = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Taxa Plataforma (${_ifoodRate.toStringAsFixed(1)}%):',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    '- R\$ ${_commissionValue.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA1D2C)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Repasse Líquido Estimado:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'R\$ ${(_totalSaleValue - _commissionValue).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                        Text(_sellerType == 'ifood' ? 'Valor Total no Cardápio iFood:' : 'Valor Total Recebido:'),
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
                          const Text('Custo Total Proporcional (CMV):'),
                          Text('R\$ ${_totalSaleCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      const Divider(height: 20),
                      if (_sellerType == 'ifood') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Taxa do iFood (${_ifoodRate.toStringAsFixed(1)}%):'),
                            Text('- R\$ ${_commissionValue.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEA1D2C), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Repasse Líquido Estimado:'),
                            Text('R\$ ${(_totalSaleValue - _commissionValue).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                      ] else ...[
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
                        ],
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
