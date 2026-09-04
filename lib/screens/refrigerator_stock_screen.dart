import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/refrigerator_item.dart';
import '../models/product.dart';
import '../models/recipe.dart';

class RefrigeratorStockScreen extends StatefulWidget {
  const RefrigeratorStockScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorStockScreen> createState() => _RefrigeratorStockScreenState();
}

class _RefrigeratorStockScreenState extends State<RefrigeratorStockScreen> {
  bool _isLoading = true;
  List<RefrigeratorItem> _stockItems = [];
  List<Product> _products = [];
  List<Recipe> _recipes = [];

  String _filterType = 'all'; // 'all', 'product', 'recipe'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.readRefrigeratorStock(),
        DatabaseHelper.instance.readAllProducts(),
        DatabaseHelper.instance.readAllRecipes(),
      ]);
      _stockItems = results[0] as List<RefrigeratorItem>;
      _products = results[1] as List<Product>;
      _recipes = results[2] as List<Recipe>;
    } catch (e) {
      debugPrint('Erro ao carregar geladeira: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<RefrigeratorItem> get _filteredItems {
    if (_filterType == 'all') return _stockItems;
    return _stockItems.where((item) => item.type == _filterType).toList();
  }

  Future<void> _adjustQuantity(RefrigeratorItem item, double amount) async {
    final newQty = (item.quantity + amount).clamp(0.0, double.infinity);
    if (newQty == item.quantity) return;
    
    setState(() {
      item.quantity = newQty;
    });

    try {
      await DatabaseHelper.instance.updateRefrigeratorItem(item);
    } catch (e) {
      debugPrint('Erro ao atualizar quantidade de estoque: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar alteração no banco de dados.')),
      );
    }
  }

  Future<void> _deleteItem(RefrigeratorItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Deseja realmente remover "${item.name}" do estoque do refrigerador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteRefrigeratorItem(item.id!);
        _loadData();
      } catch (e) {
        debugPrint('Erro ao remover item do estoque: $e');
      }
    }
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddRefrigeratorItemSheet(
          products: _products,
          recipes: _recipes,
          onSaved: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.kitchen, size: 22),
            const SizedBox(width: 8),
            Text(
              'Geladeira Virtual',
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Choice chips para filtragem
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildFilterChip('Tudo', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bolos Prontos', 'product'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Recheios/Bases', 'recipe'),
                    ],
                  ),
                ),
                
                // Lista de itens
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.kitchen_outlined,
                                  size: 64,
                                  color: Colors.brown.withOpacity(isDark ? 0.4 : 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Geladeira Vazia!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Adicione bolos prontos ou recheios para controlar o estoque refrigerado.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isProduct = item.type == 'product';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.05) 
                                      : Colors.brown.withOpacity(0.08),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Indicador visual de tipo
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: isProduct
                                                ? Colors.teal.withOpacity(isDark ? 0.15 : 0.08)
                                                : Colors.pink.withOpacity(isDark ? 0.15 : 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            isProduct ? Icons.cake : Icons.restaurant_menu,
                                            color: isProduct ? Colors.teal : Colors.pink,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        
                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isProduct
                                                          ? Colors.teal.withOpacity(0.12)
                                                          : Colors.pink.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isProduct ? 'Bolo/Produto' : 'Recheio/Base',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: isProduct ? Colors.teal : Colors.pink,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (item.lastUpdated != null)
                                                    Text(
                                                      'Atualizado: ${item.lastUpdated!.day}/${item.lastUpdated!.month}',
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Deletar
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _deleteItem(item),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.brown.withOpacity(0.06)),
                                    const SizedBox(height: 12),
                                    
                                    // Controles de estoque
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantidade no refrigerador:',
                                          style: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, size: 22),
                                              color: Colors.brown,
                                              onPressed: () => _adjustQuantity(item, -1.0),
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 40),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 22),
                                              color: Theme.of(context).primaryColor,
                                              onPressed: () => _adjustQuantity(item, 1.0),
                                            ),
                                          ],
                                        ),
                                      ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemModal,
        tooltip: 'Adicionar à Geladeira',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = type;
          });
        }
      },
    );
  }
}

class _AddRefrigeratorItemSheet extends StatefulWidget {
  final List<Product> products;
  final List<Recipe> recipes;
  final VoidCallback onSaved;

  const _AddRefrigeratorItemSheet({
    Key? key,
    required this.products,
    required this.recipes,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_AddRefrigeratorItemSheet> createState() => _AddRefrigeratorItemSheetState();
}

class _AddRefrigeratorItemSheetState extends State<_AddRefrigeratorItemSheet> {
  final _formKey = GlobalKey<FormState>();
  
  String _type = 'product'; // 'product', 'recipe', 'custom'
  Product? _selectedProduct;
  Recipe? _selectedRecipe;
  
  String _customName = '';
  double _quantity = 1.0;
  String _unit = 'unidade';

  bool _isSaving = false;

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      String name = '';
      int? productId;
      int? recipeId;

      if (_type == 'product') {
        name = _selectedProduct!.name;
        productId = _selectedProduct!.id;
        _unit = _selectedProduct!.yieldAmount > 1 ? _selectedProduct!.unit : 'unidade';
      } else if (_type == 'recipe') {
        name = _selectedRecipe!.name;
        recipeId = _selectedRecipe!.id;
        _unit = _selectedRecipe!.yieldUnit;
      } else {
        name = _customName;
      }

      final item = RefrigeratorItem(
        productId: productId,
        recipeId: recipeId,
        name: name,
        quantity: _quantity,
        unit: _unit,
        type: _type == 'product' ? 'product' : 'recipe', // custom mapeado para recipe ou product
      );

      try {
        await DatabaseHelper.instance.createRefrigeratorItem(item);
        widget.onSaved();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Erro ao cadastrar estoque: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar item na geladeira.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adicionar à Geladeira',
                  style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Tipo de item
            Text(
              'O que deseja estocar?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Bolo Pronto'),
                  selected: _type == 'product',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _type = 'product';
                        _unit = 'unidade';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Recheio / Massa'),
                  selected: _type == 'recipe',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _type = 'recipe';
                        _unit = 'kg';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Outro'),
                  selected: _type == 'custom',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _type = 'custom';
                        _unit = 'unidade';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dropdowns ou Campo Customizado
            if (_type == 'product') ...[
              DropdownButtonFormField<Product>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Selecione o Bolo/Produto',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProduct,
                items: widget.products.map<DropdownMenuItem<Product>>((p) {
                  return DropdownMenuItem<Product>(
                    value: p,
                    child: Text(p.name),
                  );
                }).toList(),
                validator: (v) => v == null ? 'Selecione um produto' : null,
                onChanged: (val) {
                  setState(() {
                    _selectedProduct = val;
                    if (val != null) {
                      _unit = val.yieldAmount > 1 ? val.unit : 'unidade';
                    }
                  });
                },
              ),
            ] else if (_type == 'recipe') ...[
              DropdownButtonFormField<Recipe>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Selecione a Receita (Recheio/Massa)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedRecipe,
                items: widget.recipes.map<DropdownMenuItem<Recipe>>((r) {
                  return DropdownMenuItem<Recipe>(
                    value: r,
                    child: Text(r.name),
                  );
                }).toList(),
                validator: (v) => v == null ? 'Selecione uma receita' : null,
                onChanged: (val) {
                  setState(() {
                    _selectedRecipe = val;
                    if (val != null) {
                      _unit = val.yieldUnit;
                    }
                  });
                },
              ),
            ] else ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Item (ex: Sobras de Morango)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onSaved: (v) => _customName = v ?? '',
              ),
            ],
            const SizedBox(height: 16),

            // Quantidade e Unidade
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _quantity.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantidade Inicial (${_unit})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    onSaved: (v) {
                      _quantity = double.tryParse(v!.replaceAll(',', '.')) ?? 1.0;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                if (_type == 'custom')
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onSaved: (v) => _unit = v ?? 'unidade',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Botão de Salvar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Cadastrar no Estoque',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
