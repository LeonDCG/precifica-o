import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/recipe.dart';
import 'add_recipe_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshRecipes();
  }

  Future<void> _refreshRecipes() async {
    setState(() => _isLoading = true);
    _recipes = await DatabaseHelper.instance.readAllRecipes();
    setState(() => _isLoading = false);
  }

  Map<String, List<Recipe>> _getGroupedRecipes() {
    final Map<String, List<Recipe>> grouped = {};
    for (var recipe in _recipes) {
      final cat = recipe.category;
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(recipe);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedRecipes = _getGroupedRecipes();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 24),
            const SizedBox(width: 8),
            Text('Receitas', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Minhas Receitas', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                          Text('${_recipes.length} receitas cadastradas', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
                          );
                          _refreshRecipes();
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _recipes.isEmpty
                      ? const Center(child: Text('Nenhuma receita cadastrada.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: groupedRecipes.length,
                          itemBuilder: (context, catIndex) {
                            final category = groupedRecipes.keys.elementAt(catIndex);
                            final categoryRecipes = groupedRecipes[category]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  child: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                 ...categoryRecipes.map((recipe) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AddRecipeScreen(recipe: recipe)),
                                        );
                                        _refreshRecipes();
                                      },
                                      title: Text(
                                        recipe.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        'Rende: ${recipe.yieldAmount} ${recipe.yieldUnit}  •  Custo: R\$ ${recipe.totalCost.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'R\$ ${recipe.costPerYield.toStringAsFixed(2)} / ${recipe.yieldUnit}',
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
                                              await DatabaseHelper.instance.deleteRecipe(recipe.id!);
                                              _refreshRecipes();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
