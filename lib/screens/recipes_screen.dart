import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/recipe.dart';
import 'add_recipe_screen.dart';

/// Modelo de análise para identificação de famílias e variações de receitas
class ParsedRecipeInfo {
  final bool isGrouped;
  final String familyName;
  final int? eggCount;
  final String variantLabel;
  final Recipe recipe;

  ParsedRecipeInfo({
    required this.isGrouped,
    required this.familyName,
    this.eggCount,
    required this.variantLabel,
    required this.recipe,
  });

  static ParsedRecipeInfo parse(Recipe recipe) {
    final clean = recipe.name.trim();
    final regExp = RegExp(
      r'^(.*?)\s*\(\s*(\d+)\s*(?:ovos|ovo)\s*(?:-\s*(.*?))?\s*\)$',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(clean);
    if (match != null) {
      final family = match.group(1)!.trim();
      final eggCount = int.tryParse(match.group(2)!);
      final extra = match.group(3) != null ? ' - ${match.group(3)!.trim()}' : '';
      return ParsedRecipeInfo(
        isGrouped: true,
        familyName: family,
        eggCount: eggCount,
        variantLabel: '${eggCount ?? 0} Ovos$extra',
        recipe: recipe,
      );
    }
    return ParsedRecipeInfo(
      isGrouped: false,
      familyName: clean,
      eggCount: null,
      variantLabel: clean,
      recipe: recipe,
    );
  }
}

/// Agrupamento por subgrupo/família (ex: Massa Branca Oficial) dentro de uma categoria
class RecipeFamilyGroup {
  final String familyName;
  final bool isGrouped;
  final List<ParsedRecipeInfo> variants;

  RecipeFamilyGroup({
    required this.familyName,
    required this.isGrouped,
    required this.variants,
  });

  double get minCost {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.recipe.totalCost).reduce((a, b) => a < b ? a : b);
  }

  double get maxCost {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.recipe.totalCost).reduce((a, b) => a > b ? a : b);
  }

  double get minUnitCost {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.recipe.costPerYield).reduce((a, b) => a < b ? a : b);
  }

  double get maxUnitCost {
    if (variants.isEmpty) return 0.0;
    return variants.map((v) => v.recipe.costPerYield).reduce((a, b) => a > b ? a : b);
  }

  String get costRangeStr {
    if (minCost == maxCost) {
      return 'R\$ ${minCost.toStringAsFixed(2)}';
    }
    return 'R\$ ${minCost.toStringAsFixed(2)} ~ R\$ ${maxCost.toStringAsFixed(2)}';
  }

  String get unitCostRangeStr {
    if (minUnitCost == maxUnitCost) {
      return 'R\$ ${minUnitCost.toStringAsFixed(2)} / un';
    }
    return 'R\$ ${minUnitCost.toStringAsFixed(2)} ~ R\$ ${maxUnitCost.toStringAsFixed(2)} / un';
  }
}

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  // Controle de expansão: por padrão vazios (minimizados)
  final Set<String> _expandedCategories = {};
  final Set<String> _expandedSubgroups = {};

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
    }
    _refreshRecipes(force: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Retorna as receitas agrupadas em 2 níveis: Categoria -> Subgrupos/Famílias
  Map<String, List<RecipeFamilyGroup>> _getHierarchicalRecipes() {
    // 1. Agrupar receitas filtradas por categoria principal
    final Map<String, List<Recipe>> byCategory = {};
    for (var recipe in _filteredRecipes) {
      final cat = recipe.category.trim().isEmpty ? 'Geral' : recipe.category.trim();
      byCategory.putIfAbsent(cat, () => []).add(recipe);
    }

    // 2. Ordenar categorias: 'Massas' primeiro, depois alfabética
    final sortedCategoryKeys = byCategory.keys.toList()
      ..sort((a, b) {
        if (a.toLowerCase() == 'massas') return -1;
        if (b.toLowerCase() == 'massas') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final Map<String, List<RecipeFamilyGroup>> result = {};

    for (var cat in sortedCategoryKeys) {
      final recipesInCat = byCategory[cat]!;

      // 3. Agrupar receitas da categoria em famílias/subgrupos
      final Map<String, List<ParsedRecipeInfo>> familyMap = {};
      for (var recipe in recipesInCat) {
        final parsed = ParsedRecipeInfo.parse(recipe);
        familyMap.putIfAbsent(parsed.familyName, () => []).add(parsed);
      }

      final List<RecipeFamilyGroup> groups = [];
      familyMap.forEach((familyName, items) {
        // Ordenar variantes pelo número de ovos
        items.sort((a, b) => (a.eggCount ?? 0).compareTo(b.eggCount ?? 0));
        final isGrouped = items.any((i) => i.isGrouped) && items.length > 1;

        groups.add(RecipeFamilyGroup(
          familyName: familyName,
          isGrouped: isGrouped,
          variants: items,
        ));
      });

      // Ordenar subgrupos por nome
      groups.sort((a, b) => a.familyName.compareTo(b.familyName));
      result[cat] = groups;
    }

    return result;
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

  IconData _getFamilyIcon(String familyName, String category) {
    final fn = familyName.toLowerCase();
    if (fn.contains('velvet')) {
      return fn.contains('purple') ? Icons.circle : Icons.favorite;
    } else if (fn.contains('cenoura')) {
      return Icons.eco;
    } else if (fn.contains('café') || fn.contains('cafe')) {
      return Icons.coffee;
    } else if (fn.contains('nozes')) {
      return Icons.grain;
    } else if (fn.contains('chocolate') || fn.contains('cacau')) {
      return Icons.cookie;
    } else if (fn.contains('branca')) {
      return Icons.bakery_dining;
    }
    return Icons.menu_book;
  }

  Color _getFamilyIconColor(String familyName) {
    final fn = familyName.toLowerCase();
    if (fn.contains('purple velvet')) {
      return const Color(0xFFAB47BC); // Roxo
    } else if (fn.contains('red velvet')) {
      return const Color(0xFFE53935); // Vermelho
    } else if (fn.contains('cenoura')) {
      return const Color(0xFFFF7043); // Laranja Cenoura
    } else if (fn.contains('café') || fn.contains('cafe')) {
      return const Color(0xFF8D6E63); // Marrom Café
    } else if (fn.contains('nozes')) {
      return const Color(0xFFFFB300); // Âmbar Nozes
    } else if (fn.contains('chocolate')) {
      return const Color(0xFF6D4C41); // Chocolate
    } else if (fn.contains('branca')) {
      return const Color(0xFFFFCA28); // Amarelo Dourado
    }
    return const Color(0xFF90A4AE);
  }

  void _toggleAllCategories(bool expand) {
    setState(() {
      if (expand) {
        final grouped = _getHierarchicalRecipes();
        _expandedCategories.addAll(grouped.keys);
      } else {
        _expandedCategories.clear();
        _expandedSubgroups.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _getHierarchicalRecipes();
    final totalDisplay = _filteredRecipes.length;
    final isSearchingActive = _searchQuery.trim().isNotEmpty;

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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar receitas ou massas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
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
                  // CABEÇALHO COM CONTADORES E CONTROLE DE EXPANSÃO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minhas Receitas',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalDisplay receitas cadastradas • Minimizadas por padrão',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _expandedCategories.isEmpty ? Icons.unfold_more : Icons.unfold_less,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              tooltip: _expandedCategories.isEmpty ? 'Expandir todos' : 'Recolher todos',
                              onPressed: () => _toggleAllCategories(_expandedCategories.isEmpty),
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
                      ],
                    ),
                  ),

                  // LISTA HIERÁRQUICA: CATEGORIA -> SUBGRUPOS (FAMÍLIAS) -> VARIAÇÕES
                  Expanded(
                    child: _recipes.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              const Center(child: Text('Nenhuma receita cadastrada.')),
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
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                            itemCount: groupedData.length,
                            itemBuilder: (context, catIndex) {
                              final category = groupedData.keys.elementAt(catIndex);
                              final familyGroups = groupedData[category]!;

                              // Na busca ativa, expande automaticamente. Senão, respeita o set minimizado.
                              final isCategoryExpanded = isSearchingActive || _expandedCategories.contains(category);
                              final totalRecipesInCat = familyGroups.fold<int>(0, (sum, g) => sum + g.variants.length);

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
                                    key: Key('cat_${category}_$isCategoryExpanded'),
                                    initiallyExpanded: isCategoryExpanded,
                                    onExpansionChanged: (expanded) {
                                      setState(() {
                                        if (expanded) {
                                          _expandedCategories.add(category);
                                        } else {
                                          _expandedCategories.remove(category);
                                        }
                                      });
                                    },
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(category).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.folder_open_rounded,
                                        color: _getCategoryColor(category),
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category.isEmpty ? 'SEM CATEGORIA' : category.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$totalRecipesInCat receitas',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                    children: familyGroups.map((familyGroup) {
                                      if (familyGroup.isGrouped) {
                                        return _buildSubgroupCard(context, category, familyGroup, isSearchingActive);
                                      } else {
                                        // Receita individual (avulsa) dentro da categoria
                                        return _buildRecipeItemCard(context, familyGroup.variants.first.recipe, isStandalone: true);
                                      }
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

  /// Constrói o Card de um Subgrupo de Receitas (ex: Subgrupo "Massa Branca Oficial", "Massa de Cenoura", etc.)
  Widget _buildSubgroupCard(
    BuildContext context,
    String category,
    RecipeFamilyGroup group,
    bool isSearchingActive,
  ) {
    final subgroupKey = '${category}_${group.familyName}';
    final isSubgroupExpanded = isSearchingActive || _expandedSubgroups.contains(subgroupKey);
    final iconColor = _getFamilyIconColor(group.familyName);
    final icon = _getFamilyIcon(group.familyName, category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('sub_${subgroupKey}_$isSubgroupExpanded'),
          initiallyExpanded: isSubgroupExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedSubgroups.add(subgroupKey);
              } else {
                _expandedSubgroups.remove(subgroupKey);
              }
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            group.familyName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🥚 ${group.variants.length} proporções',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.costRangeStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          children: group.variants.map((variant) {
            return _buildRecipeItemCard(
              context,
              variant.recipe,
              variantLabel: variant.variantLabel,
              isStandalone: false,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Constrói o Card individual de uma variação ou receita sem quebra de texto
  Widget _buildRecipeItemCard(
    BuildContext context,
    Recipe recipe, {
    String? variantLabel,
    bool isStandalone = false,
  }) {
    final stripeColor = _getCategoryColor(recipe.category);
    final displayName = variantLabel != null ? '🥚 $variantLabel' : recipe.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipeScreen(recipe: recipe)),
          );
          _refreshRecipes(force: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LINHA 1: TÍTULO DA RECEITA/VARIAÇÃO (100% de largura disponível) + AÇÕES
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: stripeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isStandalone ? 14 : 13.5,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Botão de Excluir Compacto
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
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
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // LINHA 2: RENDIMENTO E CUSTOS EM BADGES HORIZONTAIS
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Rendimento
                  Text(
                    'Rende: ${recipe.yieldAmount.toStringAsFixed(0)} ${recipe.yieldUnit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  Text('•', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  // Custo total
                  Text(
                    'Custo: R\$ ${recipe.totalCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  Text('•', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  // Custo unitário em destaque verde
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'R\$ ${recipe.costPerYield.toStringAsFixed(2)} / ${recipe.yieldUnit}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
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
