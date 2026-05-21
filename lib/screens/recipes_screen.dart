import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe.dart';
import '../database/db_helper.dart';
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

  @override
  Widget build(BuildContext context) {
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
                          itemCount: _recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _recipes[index];
                            return InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddRecipeScreen(recipe: recipe)),
                                );
                                _refreshRecipes();
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              recipe.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () async {
                                              await DatabaseHelper.instance.deleteRecipe(recipe.id!);
                                              _refreshRecipes();
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('RENDE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                              Text('${recipe.yieldAmount} ${recipe.yieldUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('CUSTO TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                              Text('R\$ ${recipe.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text('CUSTO / ${recipe.yieldUnit.toUpperCase()}', style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                                Text('R\$ ${recipe.costPerYield.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
