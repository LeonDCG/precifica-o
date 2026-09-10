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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedRecipes;
    if (cached != null && cached.isNotEmpty) {
      _recipes = cached;
      _isLoading = false;
      _initDefaultExpandedCategories(cached);
    }
    _refreshRecipes(force: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initDefaultExpandedCategories(List<Recipe> recipes) {
    if (_expandedCategories.isEmpty) {
      for (var r in recipes) {
        final cat = r.category.trim();
        if (cat.isNotEmpty) {
          _expandedCategories.add(cat);
        }
      }
    }
  }

  Future<void> _refreshRecipes({bool force = false}) async {
    if (!mounted) return;
    if (_recipes.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final fetched = await DatabaseHelper.instance.readAllRecipes(forceRefresh: force);
      if (mounted) {
        setState(() {
          _recipes = fetched;
          _initDefaultExpandedCategories(fetched);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar receitas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Recipe> get _filteredRecipes {
    if (_searchQuery.trim().isEmpty) return _recipes;
    final query = _searchQuery.toLowerCase().trim();
    return _recipes.where((r) {
      return r.name.toLowerCase().contains(query) ||
             r.category.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, List<Recipe>> _getGroupedRecipes() {
    final Map<String, List<Recipe>> grouped = {};
    for (var recipe in _filteredRecipes) {
      final cat = recipe.category.trim().isEmpty ? 'Geral' : recipe.category.trim();
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(recipe);
    }

    // Ordenar categorias: 'Massas' primeiro, depois alfabético
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a.toLowerCase() == 'massas') return -1;
        if (b.toLowerCase() == 'massas') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final Map<String, List<Recipe>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    return sortedGrouped;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains('bolo') || cat.contains('massa')) {
      return const Color(0xFFFFB74D); // Laranja / Âmbar
    } else if (cat.contains('recheio') || cat.contains('cobertura') || cat.contains('doce') || cat.contains('brigadeiro')) {
      return const Color(0xFFE57373); // Vermelho / Rosa
    } else if (cat.contains('embalagem') || cat.contains('torta')) {
      return const Color(0xFF64B5F6); // Azul
    } else if (cat.contains('chantilly')) {
      return const Color(0xFFBA68C8); // Roxo claro
    } else if (cat.contains('geléia') || cat.contains('geleia')) {
      return const Color(0xFFFF8A65); // Coral
    }
    final int hash = cat.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, (r % 100) + 120, (g % 100) + 120, (b % 100) + 120);
  }

  @override
  Widget build(BuildContext context) {
    final groupedRecipes = _getGroupedRecipes();
    final totalDisplay = _filteredRecipes.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Buscar receitas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 24),
                  const SizedBox(width: 8),
                  Text('Receitas', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar receitas',
            onPressed: () => _refreshRecipes(force: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _refreshRecipes(force: true),
              child: Column(
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
                            Text('$totalDisplay receitas cadastradas', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        FloatingActionButton(
                          mini: true,
                          tooltip: 'Nova Receita',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
                            );
                            _refreshRecipes(force: true);
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _recipes.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              const Center(child: Text('Nenhuma receita encontrada.')),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _refreshRecipes(force: true),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Recarregar'),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                    title: Row(
                                      children: [
                                        Text(
                                          category.isEmpty ? 'SEM CATEGORIA' : category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${categoryRecipes.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
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
                                                    _refreshRecipes(force: true);
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
                                                          final confirm = await showDialog<bool>(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              title: const Text('Excluir Receita'),
                                                              content: Text('Deseja realmente excluir "${recipe.name}"?'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(ctx, false),
                                                                  child: const Text('Cancelar'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(ctx, true),
                                                                  child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (confirm == true) {
                                                            await DatabaseHelper.instance.deleteRecipe(recipe.id!);
                                                            _refreshRecipes(force: true);
                                                          }
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
            ),
    );
  }
}
