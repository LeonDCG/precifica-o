import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/recipe.dart';
import '../database/db_helper.dart';
import '../widgets/app_cached_image.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = 'Geral';
  String _unit = 'unidade';
  double _yieldAmount = 1.0;
  double _profitMarginPercent = 30.0;
  double _sellPrice = 0.0;
  double _ifoodPrice = 0.0;
  late TextEditingController _ifoodPriceController;
  String _imagePath = '';

  final ImagePicker _picker = ImagePicker();

  List<Recipe> _availableRecipes = [];
  final List<ProductRecipe> _selectedRecipes = [];
  final List<ProductExpense> _expenses = [];

  List<String> _existingCategories = ['Geral'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _category = widget.product!.category;
      _unit = widget.product!.unit;
      _yieldAmount = widget.product!.yieldAmount;
      _profitMarginPercent = widget.product!.profitMarginPercent;
      _sellPrice = widget.product!.sellPrice;
      _ifoodPrice = widget.product!.ifoodPrice;
      _imagePath = widget.product!.imagePath;
      _selectedRecipes.addAll(widget.product!.recipes);
      _expenses.addAll(widget.product!.extraExpenses);
    }
    _ifoodPriceController = TextEditingController(
      text: _ifoodPrice > 0 ? _ifoodPrice.toStringAsFixed(2) : '',
    );
    if (DatabaseHelper.instance.cachedRecipes != null) {
      _availableRecipes = DatabaseHelper.instance.cachedRecipes!;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _ifoodPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.readAllRecipes(),
        DatabaseHelper.instance.getCategories(),
      ]);
      
      if (mounted) {
        setState(() {
          _availableRecipes = results[0] as List<Recipe>;
          _existingCategories = results[1] as List<String>;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais em AddProductScreen: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final ext = image.name.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        if (mounted) {
          setState(() {
            _imagePath = 'data:$mime;base64,$base64String';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
  }

  void _showAddRecipeDialog() {
    Recipe? selectedRecipe;
    double qty = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar Receita'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Recipe>(
                    isExpanded: true,
                    hint: const Text('Selecione a receita'),
                    value: selectedRecipe,
                    items: _availableRecipes.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text('${r.name} (R\$ ${r.costPerYield.toStringAsFixed(2)}/${r.yieldUnit})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedRecipe = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedRecipe != null)
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Quantidade usada (${selectedRecipe!.yieldUnit})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        qty = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedRecipe != null && qty > 0) {
                      final cost = selectedRecipe!.costPerYield * qty;
                      setState(() {
                        _selectedRecipes.add(
                          ProductRecipe(
                            productId: 0,
                            recipeId: selectedRecipe!.id!,
                            recipeName: selectedRecipe!.name,
                            quantityUsed: qty,
                            cost: cost,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    String expenseName = '';
    double expenseCost = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gasto Extra (Embalagem, etc)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Descrição (ex: Caixa)'),
                onChanged: (val) => expenseName = val,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Custo (R\$)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  expenseCost = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (expenseName.isNotEmpty && expenseCost > 0) {
                  setState(() {
                    _expenses.add(
                      ProductExpense(
                        productId: 0,
                        name: expenseName,
                        cost: expenseCost,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final product = Product(
        id: widget.product?.id,
        name: _name,
        category: _category,
        unit: _unit,
        yieldAmount: _yieldAmount,
        profitMarginPercent: _profitMarginPercent,
        sellPrice: _sellPrice,
        ifoodPrice: _ifoodPrice,
        recipes: _selectedRecipes,
        extraExpenses: _expenses,
        imagePath: _imagePath,
        isFeatured: widget.product?.isFeatured ?? false,
      );
      product.calculateSuggestedPrice();
      if (widget.product != null) {
        await DatabaseHelper.instance.updateProduct(product);
      } else {
        await DatabaseHelper.instance.createProduct(product);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  double get _currentTotalCost {
    double sum = 0;
    for (var r in _selectedRecipes) sum += r.cost;
    for (var e in _expenses) sum += e.cost;
    return sum;
  }

  double get _currentSuggestedPrice {
    return _currentTotalCost * (1 + (_profitMarginPercent / 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Novo Produto' : 'Editar Produto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProduct,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
                  ),
                  child: ClipOval(
                    child: _imagePath.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: _imagePath,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.primary, size: 32),
                              const SizedBox(height: 4),
                              Text('Adicionar\nFoto', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Nome do Produto (ex: Bolo de Casamento)'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _category),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return _existingCategories;
                }
                return _existingCategories.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _category = selection;
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Categoria / Agrupamento',
                    hintText: 'Digite ou escolha uma categoria',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  onSaved: (v) => _category = v!,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _yieldAmount.toString(),
                    decoration: const InputDecoration(labelText: 'Rendimento (ex: 10)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    onChanged: (v) {
                      setState(() {
                        _yieldAmount = double.tryParse(v.replaceAll(',', '.')) ?? 1.0;
                      });
                    },
                    onSaved: (v) => _yieldAmount = double.tryParse(v!.replaceAll(',', '.')) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unidade (fatia, etc)'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    onChanged: (v) {
                      setState(() {
                        _unit = v;
                      });
                    },
                    onSaved: (v) => _unit = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- Receitas ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Receitas Utilizadas', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _showAddRecipeDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            ..._selectedRecipes.map((r) => ListTile(
                  title: Text(r.recipeName),
                  subtitle: Text('Qtd: ${r.quantityUsed}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('R\$ ${r.cost.toStringAsFixed(2)}'),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setState(() => _selectedRecipes.remove(r)),
                      )
                    ],
                  ),
                )),
            const Divider(),

            // --- Gastos Extras ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gastos Extras', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            ..._expenses.map((e) => ListTile(
                  title: Text(e.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('R\$ ${e.cost.toStringAsFixed(2)}'),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setState(() => _expenses.remove(e)),
                      )
                    ],
                  ),
                )),
            const Divider(),

            // --- Fechamento ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. RESUMO DOS CUSTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Custo Total (Lote):', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('R\$ ${_currentTotalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_yieldAmount > 1) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Custo por $_unit (Rendimento):', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('R\$ ${(_currentTotalCost / _yieldAmount).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  
                  Text('2. DEFINE SEU LUCRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Margem de Lucro Desejada (%)', 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _profitMarginPercent.toString(),
                    onChanged: (v) {
                      setState(() {
                        _profitMarginPercent = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                      });
                    },
                    onSaved: (v) => _profitMarginPercent = double.tryParse(v!.replaceAll(',', '.')) ?? 30,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Preço Sugerido (Lote):', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('R\$ ${_currentSuggestedPrice.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_yieldAmount > 1) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sugerido por $_unit:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('R\$ ${(_currentSuggestedPrice / _yieldAmount).toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),

                  Text('3. PREÇO DE VENDA PRATICADO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _sellPrice > 0 ? _sellPrice.toString() : null,
                    decoration: const InputDecoration(
                      labelText: 'Preço de Venda Final (Total R\$)', 
                      border: OutlineInputBorder(), 
                      prefixText: 'R\$ ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Informe o preço de venda' : null,
                    onChanged: (v) {
                      setState(() {
                        _sellPrice = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                      });
                    },
                    onSaved: (v) => _sellPrice = double.tryParse(v!.replaceAll(',', '.')) ?? 0,
                  ),
                  if (_yieldAmount > 1 && _sellPrice > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Venda por $_unit:', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('R\$ ${(_sellPrice / _yieldAmount).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),

                  // Lucro Praticado Real
                  Builder(
                    builder: (context) {
                      final realProfit = _sellPrice - _currentTotalCost;
                      final isPositive = realProfit >= 0;
                      final profitPerUnit = _yieldAmount > 0 ? realProfit / _yieldAmount : 0.0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPositive ? '4. SEU LUCRO PROJETADO (LOJA/BALCÃO)' : '4. PREJUÍZO DETECTADO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green[800] : Colors.red[800],
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isPositive ? 'Lucro Total (Lote):' : 'Prejuízo Total:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green[900] : Colors.red[900]),
                                ),
                                Text(
                                  'R\$ ${realProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                            if (_yieldAmount > 1) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lucro por $_unit:',
                                    style: TextStyle(fontSize: 13, color: isPositive ? Colors.green[700] : Colors.red[700]),
                                  ),
                                  Text(
                                    'R\$ ${profitPerUnit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? Colors.green[800] : Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(thickness: 1.5),
                  ),

                  // Seção iFood
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA1D2C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '5. PREÇO DE VENDA NO IFOOD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEA1D2C),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFEA1D2C)),
                        label: Text(
                          _yieldAmount > 1 ? 'Sugerir p/ Fatia (100% Lucro)' : 'Sugerir (+26,2%)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA1D2C)),
                        ),
                        onPressed: () {
                          final marginMultiplier = 1 + (_profitMarginPercent / 100);
                          if (_yieldAmount > 1) {
                            // Venda por fatia no iFood:
                            // Custo base da fatia + Kit de despacho (Sacola Kraft R$0,60 + Embalagem fatia R$0,60 + Pote 30ml R$0,42 + Garfo R$0,07 + Calda R$0,71 = R$2,40)
                            final unitCost = _yieldAmount > 0 ? _currentTotalCost / _yieldAmount : _currentTotalCost;
                            const kitCost = 2.40;
                            final totalCostPerSlice = unitCost + kitCost;
                            // Preço de venda com 100% de lucro líquido cobrindo os 26.2% do iFood
                            final suggested = (totalCostPerSlice * marginMultiplier) / 0.738;
                            setState(() {
                              _ifoodPrice = double.parse(suggested.toStringAsFixed(2));
                              _ifoodPriceController.text = _ifoodPrice.toStringAsFixed(2);
                            });
                          } else {
                            final baseCost = _currentTotalCost > 0 ? _currentTotalCost : (_sellPrice > 0 ? _sellPrice / marginMultiplier : 0.0);
                            if (baseCost > 0) {
                              final totalCostDispatched = baseCost + 0.60; // sacola kraft
                              final suggested = (totalCostDispatched * marginMultiplier) / 0.738;
                              setState(() {
                                _ifoodPrice = double.parse(suggested.toStringAsFixed(2));
                                _ifoodPriceController.text = _ifoodPrice.toStringAsFixed(2);
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ifoodPriceController,
                    decoration: InputDecoration(
                      labelText: _yieldAmount > 1 ? 'Preço da Fatia no Cardápio iFood (R\$)' : 'Preço Praticado no Cardápio iFood (R\$)',
                      hintText: _yieldAmount > 1 ? 'Ex: 20,99' : 'Ex: 68,50',
                      border: const OutlineInputBorder(),
                      prefixText: 'R\$ ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      setState(() {
                        _ifoodPrice = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                  if (_ifoodPrice > 0) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final isSlice = _yieldAmount > 1;
                        final unitBaseCost = isSlice ? (_currentTotalCost / _yieldAmount) : _currentTotalCost;
                        final kitCost = isSlice ? 2.40 : 0.60;
                        final totalDispatchedCost = unitBaseCost + kitCost;
                        
                        final ifoodFee = _ifoodPrice * 0.262;
                        final netPayout = _ifoodPrice * 0.738;
                        final realProfit = netPayout - totalDispatchedCost;
                        final profitMarginOnCost = totalDispatchedCost > 0 ? (realProfit / totalDispatchedCost) * 100 : 0.0;
                        final isPositive = realProfit >= 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA1D2C).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEA1D2C).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSlice) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Custo da Fatia (1/$_yieldAmount):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('R\$ ${unitBaseCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Kit iFood (Embalagens + Calda 30ml):', style: TextStyle(fontSize: 12, color: Colors.brown)),
                                    Text('+ R\$ ${kitCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Custo Total por Fatia no iFood:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('R\$ ${totalDispatchedCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(height: 10),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Taxa iFood Plano Entrega (26,2%):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('- R\$ ${ifoodFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA1D2C))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Repasse Líquido Estimado:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('R\$ ${netPayout.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Seu Lucro Real no iFood:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(
                                        '${profitMarginOnCost >= 0 ? "+" : ""}${profitMarginOnCost.toStringAsFixed(1)}% sobre o custo',
                                        style: TextStyle(fontSize: 11, color: isPositive ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'R\$ ${realProfit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isPositive ? Colors.green[800] : Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
