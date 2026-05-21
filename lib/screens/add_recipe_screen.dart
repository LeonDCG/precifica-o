import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../database/db_helper.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({Key? key, this.recipe}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _yieldAmount = 1;
  String _yieldUnit = 'Unidade';
  String _instructions = '';
  int _prepTimeMinutes = 0;
  double _hourlyRate = 0.0;

  List<Ingredient> _availableIngredients = [];
  final List<RecipeIngredient> _selectedIngredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await DatabaseHelper.instance.readAllIngredients();
    
    final salaryStr = await DatabaseHelper.instance.getSetting('desiredSalary');
    final hoursStr = await DatabaseHelper.instance.getSetting('workedHoursPerMonth');
    final desiredSalary = double.tryParse(salaryStr ?? '') ?? 2000.0;
    final workedHoursPerMonth = double.tryParse(hoursStr ?? '') ?? 160.0;
    final rate = workedHoursPerMonth > 0 ? desiredSalary / workedHoursPerMonth : 0.0;

    setState(() {
      _availableIngredients = ingredients;
      _hourlyRate = rate;
      
      if (widget.recipe != null) {
        _name = widget.recipe!.name;
        _yieldAmount = widget.recipe!.yieldAmount;
        _yieldUnit = widget.recipe!.yieldUnit;
        _instructions = widget.recipe!.instructions;
        _prepTimeMinutes = widget.recipe!.prepTimeMinutes;
        _selectedIngredients.addAll(widget.recipe!.ingredients);
      }
    });
  }

  void _showAddIngredientDialog(String type) {
    Ingredient? selectedIngredient;
    double qty = 0;

    final filteredList = _availableIngredients.where((i) => i.type == type).toList();

    String title = type == 'ingredient' ? 'Adicionar Ingrediente' : (type == 'packaging' ? 'Adicionar Embalagem' : 'Adicionar Operacional');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Ingredient>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Selecione', border: OutlineInputBorder()),
                    value: selectedIngredient,
                    items: filteredList.map((ing) {
                      return DropdownMenuItem(
                        value: ing,
                        child: Text('${ing.name} (R\$ ${ing.price}/${ing.quantity}${ing.unit})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedIngredient = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedIngredient != null)
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Qtd usada (${selectedIngredient!.unit})',
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
                    if (selectedIngredient != null && qty > 0) {
                      final cost = selectedIngredient!.unitPrice * qty;
                      setState(() {
                        _selectedIngredients.add(
                          RecipeIngredient(
                            recipeId: 0,
                            ingredientId: selectedIngredient!.id!,
                            ingredientName: selectedIngredient!.name,
                            ingredientUnit: selectedIngredient!.unit,
                            ingredientType: selectedIngredient!.type,
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

  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final recipe = Recipe(
        id: widget.recipe?.id,
        name: _name,
        yieldAmount: _yieldAmount,
        yieldUnit: _yieldUnit,
        instructions: _instructions,
        prepTimeMinutes: _prepTimeMinutes,
        laborCost: (_prepTimeMinutes / 60.0) * _hourlyRate,
        ingredients: _selectedIngredients,
      );
      if (widget.recipe != null) {
        await DatabaseHelper.instance.deleteRecipe(widget.recipe!.id!);
      }
      await DatabaseHelper.instance.createRecipe(recipe);
      if (mounted) Navigator.pop(context);
    }
  }

  double get _currentTotalCost {
    double sum = 0;
    for (var ri in _selectedIngredients) sum += ri.cost;
    sum += (_prepTimeMinutes / 60.0) * _hourlyRate;
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                Text('Nova Receita', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: 'Nome da Receita'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    onSaved: (v) => _name = v!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: _prepTimeMinutes > 0 ? _prepTimeMinutes.toString() : null,
                    decoration: const InputDecoration(labelText: 'Tempo (Min)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _prepTimeMinutes = int.tryParse(v) ?? 0),
                    onSaved: (v) => _prepTimeMinutes = int.tryParse(v ?? '') ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Card Escuro
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CUSTO TOTAL / RENDIMENTO', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1)),
                      if (_prepTimeMinutes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text('+ Mão de obra (R\$ ${((_prepTimeMinutes / 60.0) * _hourlyRate).toStringAsFixed(2)})', style: const TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                    ],
                  ),
                  Text('R\$ ${_currentTotalCost.toStringAsFixed(2)}', style: GoogleFonts.merriweather(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RENDIMENTO', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: _yieldAmount.toString(),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (v) => _yieldAmount = double.tryParse(v!.replaceAll(',', '.')) ?? 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UNIDADE', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: _yieldUnit,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              onSaved: (v) => _yieldUnit = v!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Ingredientes Section
            _buildSection(
              title: 'Ingredientes',
              type: 'ingredient',
              emptyText: 'Nenhum ingrediente adicionado.',
            ),
            const SizedBox(height: 16),
            
            // Embalagem e Operacional Side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSection(title: 'Embalagem', type: 'packaging', emptyText: 'Nenhuma embalagem.', icon: Icons.inventory_2)),
                const SizedBox(width: 16),
                Expanded(child: _buildSection(title: 'Operacional', type: 'operational', emptyText: 'Nenhum custo op.', icon: Icons.bolt)),
              ],
            ),
            const SizedBox(height: 16),

            // Modo de Preparo
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, size: 20, color: Colors.brown),
                        const SizedBox(width: 8),
                        Text('Modo de Preparo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      initialValue: _instructions,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Descreva o passo a passo da receita aqui...',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSaved: (v) => _instructions = v ?? '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String type, required String emptyText, IconData? icon}) {
    final list = _selectedIngredients.where((i) => i.ingredientType == type).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[Icon(icon, size: 18, color: Colors.brown), const SizedBox(width: 6)],
                      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                if (type == 'ingredient') 
                  GestureDetector(
                    onTap: () => _showAddIngredientDialog(type),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text('Add', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )
              ],
            ),
          ),
          const Divider(height: 1),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text(emptyText, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ri = list[index];
                return ListTile(
                  title: Text(ri.ingredientName, style: const TextStyle(fontSize: 14)),
                  subtitle: Text('${ri.quantityUsed} ${ri.ingredientUnit}', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('R\$ ${ri.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        onPressed: () => setState(() => _selectedIngredients.remove(ri)),
                      )
                    ],
                  ),
                );
              },
            ),
          if (type != 'ingredient')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('ADD'),
                  onPressed: () => _showAddIngredientDialog(type),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
