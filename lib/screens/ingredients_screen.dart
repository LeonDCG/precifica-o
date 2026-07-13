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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _allIngredients = await DatabaseHelper.instance.readAllIngredients();
    } catch (e) {
      debugPrint('Erro ao carregar insumos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                      fillColor: Theme.of(context).cardTheme.color ?? Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.brown.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.brown.withOpacity(0.2),
                        ),
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
    Color stripeColor = const Color(0xFF81C784); // Default: Verde
    if (item.type == 'packaging') {
      stripeColor = const Color(0xFF64B5F6); // Azul
    } else if (item.type == 'operational') {
      stripeColor = const Color(0xFFFFB74D); // Laranja
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              color: stripeColor,
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () => _showAddIngredientSheet(ingredient: item),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Comprou: ${item.quantity}${item.unit} por R\$ ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$ ${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteIngredient(item.id!);
                        _refreshIngredients();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
