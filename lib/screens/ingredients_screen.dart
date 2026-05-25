import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../database/db_helper.dart';
import '../widgets/add_ingredient_sheet.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({Key? key}) : super(key: key);

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  List<Ingredient> _allIngredients = [];
  String _selectedTab = 'ingredient'; // ingredient, packaging, operational
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshIngredients();
  }

  Future<void> _refreshIngredients() async {
    setState(() => _isLoading = true);
    _allIngredients = await DatabaseHelper.instance.readAllIngredients();
    setState(() => _isLoading = false);
  }

  void _showAddIngredientSheet({Ingredient? ingredient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddIngredientSheet(
          ingredient: ingredient,
          onSaved: _refreshIngredients,
        ),
      ),
    );
  }

  void _showRestockDialog(Ingredient ingredient) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Repor ${ingredient.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estoque atual: ${ingredient.stock.toStringAsFixed(2)} ${ingredient.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Qtd comprada (${ingredient.unit})'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Valor total pago (R\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final addedQty = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0.0;
                final paidPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                
                if (addedQty > 0 && paidPrice > 0) {
                  // Custo Médio Ponderado
                  final currentStockValue = ingredient.stock * (ingredient.price / ingredient.quantity);
                  final newTotalStock = ingredient.stock + addedQty;
                  
                  double newAverageUnitPrice = 0;
                  if (newTotalStock > 0) {
                     newAverageUnitPrice = (currentStockValue + paidPrice) / newTotalStock;
                  }
                  
                  // Atualiza o 'price' (referente à 'quantity' cadastrada no banco)
                  final newPriceForStandardQuantity = newAverageUnitPrice * ingredient.quantity;

                  ingredient.stock = newTotalStock;
                  ingredient.price = newPriceForStandardQuantity;

                  await DatabaseHelper.instance.updateIngredient(ingredient);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshIngredients();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estoque atualizado!')));
                  }
                }
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar a lista pela aba selecionada e pela busca
    final displayedList = _allIngredients.where((i) {
      final matchesTab = i.type == _selectedTab;
      final matchesSearch = _searchQuery.isEmpty || 
          i.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          i.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Insumos', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insumos e Custos', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text('Gerencie ingredientes, embalagens e custos por hora.', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tabs customizadas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildTab('Ingredientes', 'ingredient'),
                      const SizedBox(width: 8),
                      _buildTab('Embalagens', 'packaging'),
                      const SizedBox(width: 8),
                      _buildTab('Operacional', 'operational'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar...',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.brown.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: displayedList.isEmpty
                      ? Center(child: Text('Nenhum item nesta categoria.', style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayedList.length,
                          itemBuilder: (context, index) {
                            final item = displayedList[index];
                            return _buildItemCard(item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredientSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String title, String type) {
    bool isSelected = _selectedTab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? null : Border.all(color: Colors.brown.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Ingredient item) {
    IconData icon = Icons.eco;
    if (item.type == 'packaging') icon = Icons.inventory_2;
    if (item.type == 'operational') icon = Icons.bolt;
    final bool isLowStock = item.stock <= item.minStock;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isLowStock 
            ? BorderSide(color: Colors.red.withOpacity(0.5), width: 2) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAddIngredientSheet(ingredient: item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(item.category.isNotEmpty ? item.category : 'Sem Categoria', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.blue),
                    onPressed: () => _showRestockDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteIngredient(item.id!);
                      _refreshIngredients();
                    },
                  )
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                     children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: isLowStock ? Colors.red : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Estoque: ${item.stock.toStringAsFixed(2)} ${item.unit}',
                        style: TextStyle(
                          color: isLowStock ? Colors.red : Colors.grey[800],
                          fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isLowStock)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Text('BAIXO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Custo: R\$ ${item.unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddIngredientSheet extends StatefulWidget {
  final Ingredient? ingredient;
  final VoidCallback onSaved;

  const AddIngredientSheet({Key? key, this.ingredient, required this.onSaved}) : super(key: key);

  @override
  State<AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<AddIngredientSheet> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String unit = 'unidade';
  double price = 0.0;
  double quantity = 1.0;
  double stock = 0.0;
  double minStock = 0.0;
  String type = 'ingredient';
  String category = '';

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      name = widget.ingredient!.name;
      unit = widget.ingredient!.unit;
      price = widget.ingredient!.price;
      quantity = widget.ingredient!.quantity;
      stock = widget.ingredient!.stock;
      minStock = widget.ingredient!.minStock;
      type = widget.ingredient!.type;
      category = widget.ingredient!.category;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final ingredient = Ingredient(
        id: widget.ingredient?.id,
        name: name,
        unit: unit,
        price: price,
        quantity: quantity,
        stock: stock,
        minStock: minStock,
        type: type,
        category: category,
      );
      if (ingredient.id == null) {
        await DatabaseHelper.instance.createIngredient(ingredient);
      } else {
        await DatabaseHelper.instance.updateIngredient(ingredient);
      }
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ingredient == null ? 'Novo Insumo' : 'Editar Insumo',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Nome do Insumo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onSaved: (v) => name = v!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: price > 0 ? price.toString() : '',
                      decoration: const InputDecoration(labelText: 'Preço Pago (R\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onSaved: (v) => price = double.parse(v!.replaceAll(',', '.')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: quantity > 0 ? quantity.toString() : '',
                      decoration: const InputDecoration(labelText: 'Quantidade da Embalagem', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onSaved: (v) => quantity = double.parse(v!.replaceAll(',', '.')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: unit,
                decoration: const InputDecoration(labelText: 'Unidade (ex: kg, g, L, ml, unidade)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onSaved: (v) => unit = v!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: stock > 0 ? stock.toString() : '',
                      decoration: const InputDecoration(labelText: 'Estoque Atual', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => stock = double.tryParse(v!.replaceAll(',', '.')) ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: minStock > 0 ? minStock.toString() : '',
                      decoration: const InputDecoration(labelText: 'Estoque Mínimo (Alerta)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => minStock = double.tryParse(v!.replaceAll(',', '.')) ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ingredient', child: Text('Ingrediente')),
                  DropdownMenuItem(value: 'packaging', child: Text('Embalagem')),
                  DropdownMenuItem(value: 'operational', child: Text('Custo Operacional')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoria (Opcional)', border: OutlineInputBorder()),
                onSaved: (v) => category = v ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
