import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe.dart';
import '../database/db_helper.dart';

class RecipeCookbookScreen extends StatefulWidget {
  final Recipe? initialRecipe;
  final List<Recipe>? allRecipes;

  const RecipeCookbookScreen({
    super.key,
    this.initialRecipe,
    this.allRecipes,
  });

  @override
  State<RecipeCookbookScreen> createState() => _RecipeCookbookScreenState();
}

class _RecipeCookbookScreenState extends State<RecipeCookbookScreen> {
  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  bool _isLoading = true;

  // Multiplicador da receita (1x = padrão, 2x = dobro, etc)
  double _multiplier = 1.0;

  // Checklist de ingredientes marcados como colocados na tigela/batedeira
  final Set<int> _checkedIngredientIndices = {};

  // Checklist de passos de preparo concluídos
  final Set<int> _checkedInstructionSteps = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  // Estado do Catálogo/Índice do Livro de Receitas
  final TextEditingController _catalogSearchController = TextEditingController();
  String _catalogSearchQuery = '';
  String _catalogCategoryFilter = 'Todas';

  static String _normalizeCategory(String? raw) {
    if (raw == null) return 'Geral';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Geral';
    final lower = trimmed.toLowerCase();
    if (lower == 'brownie') return 'Brownies';
    if (lower == 'geleia') return 'Geléias';
    if (lower == 'chantilly') return 'Chantillys';
    return trimmed;
  }

  // Indica se a tela foi aberta no modo catálogo ou se o usuário navegou até o catálogo
  bool _navigatedToCatalog = false;

  @override
  void initState() {
    super.initState();
    _navigatedToCatalog = widget.initialRecipe == null;
    if (widget.allRecipes != null && widget.allRecipes!.isNotEmpty) {
      _recipes = widget.allRecipes!;
      _selectedRecipe = widget.initialRecipe; // Se nulo, abre o Catálogo/Índice do Livro
      _isLoading = false;
    } else {
      _loadRecipes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _catalogSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.readAllRecipes();
      if (mounted) {
        setState(() {
          _recipes = list;
          if (widget.initialRecipe != null) {
            _selectedRecipe = _recipes.firstWhere(
              (r) => r.id == widget.initialRecipe!.id,
              orElse: () => widget.initialRecipe!,
            );
          } else {
            _selectedRecipe = null; // Abre no Catálogo para o usuário escolher!
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar receitas para o Livro: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectRecipe(Recipe recipe) {
    setState(() {
      _selectedRecipe = recipe;
      _checkedIngredientIndices.clear();
      _checkedInstructionSteps.clear();
      _multiplier = 1.0;
    });
  }

  void _setMultiplier(double m) {
    setState(() {
      _multiplier = m;
    });
  }

  void _resetChecklist() {
    setState(() {
      _checkedIngredientIndices.clear();
      _checkedInstructionSteps.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nova fornada iniciada! Checklist zerado.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('massa')) return '🥣';
    if (cat.contains('brigadeir')) return '🍫';
    if (cat.contains('recheio')) return '🍯';
    if (cat.contains('geléia') || cat.contains('geleia')) return '🍓';
    if (cat.contains('chantilly') || cat.contains('chantininho')) return '🥛';
    if (cat.contains('brownie')) return '⚡';
    if (cat.contains('cobertura')) return '🎂';
    return '🍰';
  }

  String _formatQuantity(double qty) {
    final scaled = qty * _multiplier;
    if (scaled == scaled.roundToDouble()) {
      return scaled.toInt().toString();
    }
    return scaled.toStringAsFixed(1).replaceAll('.', ',');
  }

  List<String> _parseInstructionSteps(String instructions) {
    if (instructions.trim().isEmpty) return [];
    final lines = instructions.split(RegExp(r'\r?\n'));
    final List<String> steps = [];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // Remove numeração manual se já houver (ex: "1.", "1 -", "Passo 1:")
        final clean = trimmed.replaceFirst(RegExp(r'^(\d+[\.\-\)]|\bPasso\s*\d+:?)\s*', caseSensitive: false), '');
        steps.add(clean.isNotEmpty ? clean : trimmed);
      }
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedRecipe == null || !_navigatedToCatalog,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedRecipe != null) {
          setState(() => _selectedRecipe = null);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121216) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedRecipe != null && _navigatedToCatalog) {
                setState(() => _selectedRecipe = null);
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedRecipe == null ? 'Livro de Receitas' : _selectedRecipe!.name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _selectedRecipe == null ? 'Escolha uma receita para a bancada' : 'Modo Cozinha & Bancada',
                style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : Colors.white),
              ),
            ],
          ),
          actions: [
            if (_selectedRecipe != null) ...[
              // Botão para voltar ao índice do livro
              IconButton(
                icon: const Icon(Icons.menu_book_rounded),
                tooltip: 'Índice de Receitas',
                onPressed: () {
                  setState(() {
                    _navigatedToCatalog = true;
                    _selectedRecipe = null;
                  });
                },
              ),
              // Botão para resetar checklist
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reiniciar Fornada',
                onPressed: _resetChecklist,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedRecipe == null
                ? _buildRecipeCatalog(isDark)
                : _buildCookbookBody(isDark),
      ),
    );
  }

  /// Catálogo e Índice visual de todas as receitas agrupadas por categoria
  Widget _buildRecipeCatalog(bool isDark) {
    final query = _catalogSearchQuery.toLowerCase().trim();
    final filtered = _recipes.where((r) {
      final nameMatch = r.name.toLowerCase().contains(query);
      final cat = _normalizeCategory(r.category);
      final catMatch = cat.toLowerCase().contains(query);
      final filterMatch = _catalogCategoryFilter == 'Todas' || cat.toLowerCase() == _catalogCategoryFilter.toLowerCase();
      return (nameMatch || catMatch) && filterMatch;
    }).toList();

    final Map<String, List<Recipe>> byCategory = {};
    for (var r in filtered) {
      final cat = _normalizeCategory(r.category);
      byCategory.putIfAbsent(cat, () => []).add(r);
    }

    final sortedCategories = byCategory.keys.toList()
      ..sort((a, b) {
        if (a.toLowerCase() == 'massas') return -1;
        if (b.toLowerCase() == 'massas') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final allCategories = ['Todas', 'Massas', 'Brigadeiros', 'Recheios', 'Caldas', 'Geléias', 'Chantillys', 'Brownies'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // CABEÇALHO DO ÍNDICE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF26262D), const Color(0xFF1E1E24)]
                  : [const Color(0xFFFDF2F8), const Color(0xFFFFF1F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('📖', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Índice de Receitas',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF9D174D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escolha uma receita abaixo para abrir os ingredientes e a bancada de preparo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFFBE185D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CAMPO DE BUSCA
        TextField(
          controller: _catalogSearchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Buscar receita no livro...',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _catalogSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _catalogSearchController.clear();
                      setState(() => _catalogSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onChanged: (v) {
            setState(() => _catalogSearchQuery = v);
          },
        ),

        const SizedBox(height: 12),

        // FILTROS DE CATEGORIA (CHIPS)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: allCategories.map((cat) {
              final isSelected = _catalogCategoryFilter.toLowerCase() == cat.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEC4899),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFEC4899)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) {
                    setState(() => _catalogCategoryFilter = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // LISTA DE CATEGORIAS E RECEITAS
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhuma receita encontrada para a busca.',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedCategories.map((cat) {
            final recs = byCategory[cat]!;
            final catIcon = _getCategoryIcon(cat);

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título da Categoria
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: Row(
                      children: [
                        Text(catIcon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          cat,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${recs.length} receita${recs.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cards das Receitas desta categoria
                  ...recs.map((recipe) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectRecipe(recipe),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(catIcon, style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.name,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${recipe.ingredients.length} ingredientes • Rende: ${recipe.yieldAmount.toStringAsFixed(0)} ${recipe.yieldUnit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEC4899),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _selectRecipe(recipe),
                                icon: const Icon(Icons.soup_kitchen_rounded, size: 14),
                                label: const Text(
                                  'Cozinhar',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCookbookBody(bool isDark) {
    final recipe = _selectedRecipe!;
    final ingredients = recipe.ingredients;
    final steps = _parseInstructionSteps(recipe.instructions);

    final totalIngredients = ingredients.length;
    final checkedIngredientsCount = _checkedIngredientIndices.length;
    final progress = totalIngredients > 0 ? (checkedIngredientsCount / totalIngredients) : 0.0;
    final isAllIngredientsDone = totalIngredients > 0 && checkedIngredientsCount == totalIngredients;

    final scaledYield = recipe.yieldAmount * _multiplier;
    final yieldStr = scaledYield == scaledYield.roundToDouble()
        ? scaledYield.toInt().toString()
        : scaledYield.toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 1. CARD PRINCIPAL DA RECEITA (NOME, CATEGORIA, RENDIMENTO)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getCategoryIcon(recipe.category),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                recipe.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '⏱️ ${recipe.prepTimeMinutes > 0 ? '${recipe.prepTimeMinutes} min' : 'Preparo rápido'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botão rápido para trocar de receita
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openRecipePickerModal(isDark),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Trocar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // BARRA MULTIPLICADORA DE FORNADA (FATOR DE ESCALA)
              Row(
                children: [
                  Text(
                    'Fornada:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [0.5, 1.0, 1.5, 2.0, 3.0].map((factor) {
                        final isSelected = _multiplier == factor;
                        return ChoiceChip(
                          label: Text(
                            factor == 1.0 ? '1x (Padrão)' : '${factor}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFEC4899),
                          backgroundColor: isDark ? const Color(0xFF26262D) : Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onSelected: (_) => _setMultiplier(factor),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Rendimento recalculado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🥧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Rendimento previsto: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.amber.shade900,
                      ),
                    ),
                    Text(
                      '$yieldStr ${recipe.yieldUnit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. BARRA DE PROGRESSO DO CHECKLIST DE INGREDIENTES
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAllIngredientsDone
                  ? Colors.green.shade400
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAllIngredientsDone ? Icons.check_circle_rounded : Icons.checklist_rounded,
                        color: isAllIngredientsDone ? Colors.green : const Color(0xFFEC4899),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingredientes Pesados e Adicionados',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$checkedIngredientsCount de $totalIngredients',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isAllIngredientsDone ? Colors.green : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllIngredientsDone ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                  ),
                ),
              ),
              if (isAllIngredientsDone) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Tudo pesado e adicionado! Pronto para bater/assar.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.greenAccent : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. LISTA DE INGREDIENTES COM CHECKBOX DE BANCADA
        if (ingredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Nenhum ingrediente vinculado a esta receita.'),
          )
        else
          ...ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isChecked = _checkedIngredientIndices.contains(idx);
            final formattedQty = _formatQuantity(item.quantityUsed);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? (isDark ? const Color(0xFF062E1B) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF1E1E24) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked
                      ? (isDark ? Colors.green.shade800 : Colors.green.shade300)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: isChecked ? 1.5 : 1.0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _checkedIngredientIndices.remove(idx);
                    } else {
                      _checkedIngredientIndices.add(idx);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Checkbox estilizado
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white38 : Colors.grey.shade400),
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),

                      // Quantidade em Destaque Grande (para balança)
                      Container(
                        constraints: const BoxConstraints(minWidth: 70),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? (isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade100)
                              : (isDark ? const Color(0xFF26262D) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$formattedQty ${item.ingredientUnit}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isChecked
                                ? (isDark ? Colors.greenAccent : Colors.green.shade900)
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nome do Ingrediente
                      Expanded(
                        child: Text(
                          item.ingredientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isChecked ? FontWeight.w500 : FontWeight.bold,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            color: isChecked
                                ? (isDark ? Colors.white38 : Colors.grey.shade500)
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 20),

        // 4. MODO DE PREPARO / INSTRUÇÕES PASSO A PASSO
        if (steps.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFEC4899), size: 22),
              const SizedBox(width: 8),
              Text(
                'Modo de Preparo (Passo a Passo)',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final stepText = entry.value;
            final isDone = _checkedInstructionSteps.contains(idx);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDone
                    ? (isDark ? const Color(0xFF062E1B) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF1E1E24) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDone
                      ? (isDark ? Colors.green.shade800 : Colors.green.shade300)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (isDone) {
                      _checkedInstructionSteps.remove(idx);
                    } else {
                      _checkedInstructionSteps.add(idx);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF26262D) : Colors.pink.shade50),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFFEC4899),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stepText,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.35,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? (isDark ? Colors.white38 : Colors.grey.shade500)
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 24),

        // 5. BOTÃO DE REINICIAR FORNADA NO RODAPÉ
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _resetChecklist,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Reiniciar Checklist / Próxima Fornada',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// Modal para escolher rapidamente qualquer outra receita
  void _openRecipePickerModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _recipes.where((r) {
              if (_searchFilter.isEmpty) return true;
              final q = _searchFilter.toLowerCase();
              return r.name.toLowerCase().contains(q) || r.category.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Escolher Receita para Cozinha',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou categoria...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF26262D) : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (v) {
                          setModalState(() => _searchFilter = v.trim());
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Nenhuma receita encontrada.'))
                            : Builder(
                                builder: (context) {
                                  final Map<String, List<Recipe>> byCategory = {};
                                  for (var r in filtered) {
                                    String cat = r.category.trim();
                                    if (cat.isEmpty) {
                                      cat = 'Geral';
                                    } else if (cat.toLowerCase() == 'brownie') {
                                      cat = 'Brownies';
                                    } else if (cat.toLowerCase() == 'geleia') {
                                      cat = 'Geléias';
                                    }
                                    byCategory.putIfAbsent(cat, () => []).add(r);
                                  }

                                  final sortedCategories = byCategory.keys.toList()
                                    ..sort((a, b) {
                                      if (a.toLowerCase() == 'massas') return -1;
                                      if (b.toLowerCase() == 'massas') return 1;
                                      return a.toLowerCase().compareTo(b.toLowerCase());
                                    });

                                  return ListView.builder(
                                    controller: scrollController,
                                    itemCount: sortedCategories.length,
                                    itemBuilder: (_, catIdx) {
                                      final cat = sortedCategories[catIdx];
                                      final recs = byCategory[cat]!;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4, right: 4),
                                            child: Row(
                                              children: [
                                                Text(_getCategoryIcon(cat), style: const TextStyle(fontSize: 18)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  cat,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEC4899).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${recs.length}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFEC4899),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...recs.map((r) {
                                            final isCurrent = _selectedRecipe?.id == r.id;
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: isCurrent
                                                    ? const Color(0xFFEC4899).withOpacity(0.12)
                                                    : (isDark ? const Color(0xFF26262D) : Colors.grey.shade50),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isCurrent
                                                      ? const Color(0xFFEC4899)
                                                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                                                  width: isCurrent ? 1.5 : 1.0,
                                                ),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                title: Text(
                                                  r.name,
                                                  style: TextStyle(
                                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isCurrent
                                                        ? const Color(0xFFEC4899)
                                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${r.ingredients.length} ingredientes • Rende: ${r.yieldAmount.toStringAsFixed(0)} ${r.yieldUnit}',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                                  ),
                                                ),
                                                trailing: isCurrent
                                                    ? const Icon(Icons.check_circle, color: Color(0xFFEC4899), size: 20)
                                                    : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  _selectRecipe(r);
                                                },
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
