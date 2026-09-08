import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/recipe.dart';
import 'add_recipe_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedRecipes;
    if (cached != null && cached.isNotEmpty) {
      _recipes = cached;
      _isLoading = false;
    }
    _refreshRecipes();
  }

  Future<void> _refreshRecipes() async {
    if (!mounted) return;
    if (_recipes.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      _recipes = await DatabaseHelper.instance.readAllRecipes();
    } catch (e) {
      debugPrint('Erro ao carregar receitas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains('bolo') || cat.contains('massa')) {
      return const Color(0xFFFFB74D); // Laranja / Âmbar
    } else if (cat.contains('recheio') || cat.contains('cobertura') || cat.contains('doce')) {
      return const Color(0xFFE57373); // Vermelho / Rosa
    } else if (cat.contains('embalagem') || cat.contains('torta')) {
      return const Color(0xFF64B5F6); // Azul
    }
    // Fallback: cor pastel consistente gerada pelo texto
    final int hash = cat.hashCode;
    // Criar cor pastel a partir de um hash
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, (r % 100) + 120, (g % 100) + 120, (b % 100) + 120);
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
                            final isExpanded = _expandedCategories.contains(category);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      if (expanded) {
                                        _expandedCategories.add(category);
                                      } else {
                                        _expandedCategories.remove(category);
                                      }
                                    });
                                  },
                                  title: Text(
                                    category.isEmpty ? 'SEM CATEGORIA' : category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  leading: Icon(Icons.folder_open_outlined, color: Theme.of(context).primaryColor, size: 20),
                                  childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                  children: categoryRecipes.map((recipe) {
                                    final stripeColor = _getCategoryColor(category);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0.5,
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
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
