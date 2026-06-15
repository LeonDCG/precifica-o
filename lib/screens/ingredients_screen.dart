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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                  Text(
                    'Custo: R\$ ${item.unitPrice.toStringAsFixed(2)} por ${item.unit}',
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
