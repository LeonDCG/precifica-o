import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/simple_cake.dart';

class SimpleCakesScreen extends StatefulWidget {
  const SimpleCakesScreen({super.key});

  @override
  State<SimpleCakesScreen> createState() => _SimpleCakesScreenState();
}

class _SimpleCakesScreenState extends State<SimpleCakesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SimpleCake> _cakes = [];
  bool _isLoading = true;
  bool _isGridView = false; // Padrão: Lista de Balcão (ultra legível e rápida)

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedSimpleCakes;
    if (cached != null && cached.isNotEmpty) {
      _cakes = cached;
      _isLoading = false;
    }
    _loadCakes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCakes({bool forceRefresh = false}) async {
    if (_cakes.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await DatabaseHelper.instance.readSimpleCakes(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _cakes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar bolos simples: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SimpleCake> get _filteredCakes {
    if (_searchQuery.isEmpty) return _cakes;
    final q = _searchQuery.toLowerCase().trim();
    return _cakes.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Mapeamento de Emojis idêntico ao catálogo oficial da loja
  String _getCakeEmoji(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('brownie')) return '⚡';
    if (n.contains('café') || n.contains('cafe')) return '🧁';
    if (n.contains('caramelo')) return '🥞';
    if (n.contains('cenoura')) return '🍰';
    if (n.contains('doce de leite')) return '🍫';
    if (n.contains('chocolate') || n.contains('choc') || n.contains('brigadeir')) return '🍫';
    if (n.contains('coco')) return '🍋';
    if (n.contains('kinder')) return '🍋';
    if (n.contains('limão') || n.contains('limao')) return '🍋';
    if (n.contains('maracuj') || n.contains('maracuja')) return '🍋';
    if (n.contains('matcha')) return '🧁';
    if (n.contains('morango')) return '🍓';
    if (n.contains('red velvet')) return '🍓';
    if (n.contains('purple velvet') || n.contains('blueberry') || n.contains('mirtilo')) return '🫐';
    if (n.contains('ninho')) return '🎂';
    if (n.contains('nozes')) return '🥞';
    if (n.contains('uva')) return '🎂';
    if (n.contains('fub') || n.contains('milho')) return '🧁';
    if (n.contains('abacaxi')) return '🍍';
    return '🎂';
  }

  /// Ajuste rápido de quantidade (+ / -) com atualização otimista imediata e persistência
  Future<void> _adjustQty(SimpleCake cake, int delta) async {
    final currentQty = cake.quantity;
    final newQty = (currentQty + delta) < 0 ? 0 : (currentQty + delta);

    if (currentQty == 0 && delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${cake.name}" já está zerado!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // 1. Atualização Otimista Imediata na UI
    setState(() {
      final idx = _cakes.indexWhere((c) => c.id == cake.id);
      if (idx != -1) {
        _cakes[idx] = _cakes[idx].copyWith(quantity: newQty);
      }
    });

    // 2. Persistência em Nuvem no Supabase
    try {
      if (cake.id != null) {
        await DatabaseHelper.instance.updateSimpleCakeQuantity(cake.id!, newQty);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar quantidade no Supabase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao salvar no banco: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toque para digitar quantidade exata
  Future<void> _promptExactQty(SimpleCake cake) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: cake.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(_getCakeEmoji(cake.name), style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cake.name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite a quantidade em balcão:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                suffixText: 'unidades',
                suffixStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF26262D) : Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final delta = result - cake.quantity;
      await _adjustQty(cake, delta);
    }
  }

  /// Cadastro / Edição SUPER SIMPLES: Apenas Nome e Quantidade
  Future<void> _openSimpleCakeModal({SimpleCake? cake}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = cake != null;
    final nameCtrl = TextEditingController(text: cake?.name ?? '');
    final qtyCtrl = TextEditingController(text: cake?.quantity.toString() ?? '1');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.pink.shade900.withValues(alpha: 0.3) : Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isEditing ? _getCakeEmoji(cake.name) : '🎂',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEditing ? 'Editar Bolo' : 'Novo Bolo',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Nome do Bolo *',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                hintText: 'Ex: Cenoura, Brownie, Red Velvet...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: isDark ? const Color(0xFF26262D) : Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Quantidade Inicial',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                suffixText: 'unidades',
                suffixStyle: TextStyle(color: isDark ? Colors.white60 : null),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: isDark ? const Color(0xFF26262D) : Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              Navigator.pop(ctx);

              if (isEditing) {
                final updated = cake.copyWith(name: name, quantity: qty);
                setState(() {
                  final idx = _cakes.indexWhere((c) => c.id == cake.id);
                  if (idx != -1) _cakes[idx] = updated;
                });
                await DatabaseHelper.instance.updateSimpleCake(updated);
              } else {
                final newCake = SimpleCake(name: name, quantity: qty);
                final saved = await DatabaseHelper.instance.createSimpleCake(newCake);
                setState(() {
                  _cakes.add(saved);
                  _cakes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                });
              }
              _loadCakes(forceRefresh: true);
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar Bolo'),
          ),
        ],
      ),
    );
  }

  /// Excluir bolo
  Future<void> _deleteCake(SimpleCake cake) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        title: Text(
          'Excluir Bolo',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Deseja realmente remover o bolo "${cake.name}" do controle de estoque?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && cake.id != null) {
      setState(() {
        _cakes.removeWhere((c) => c.id == cake.id);
      });
      await DatabaseHelper.instance.deleteSimpleCake(cake.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bolo "${cake.name}" removido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUnits = _cakes.fold<int>(0, (sum, c) => sum + c.quantity);
    final totalTypes = _cakes.length;
    final zeroCount = _cakes.where((c) => c.quantity == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estoque de Bolos',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Salvo em nuvem (Supabase)',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Alternar entre visualização em Lista ou Cards
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'Ver em Lista' : 'Ver em Cards',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar do Banco',
            onPressed: () => _loadCakes(forceRefresh: true),
          ),
        ],
      ),
      body: StreamBuilder<List<SimpleCake>>(
        stream: DatabaseHelper.instance.streamSimpleCakes(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _cakes = snapshot.data!;
          }

          final displayList = _filteredCakes;

          return Column(
            children: [
              // Barra de Busca Rápida
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Buscar sabor...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.white60 : Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

              // Resumo de Topo Elegante e Adaptado ao Tema
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildStatPill(
                      'Total',
                      '$totalUnits un',
                      isDark ? const Color(0xFF3F1B2E) : const Color(0xFFFCE7F3),
                      isDark ? const Color(0xFFF472B6) : const Color(0xFF9D174D),
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      'Sabores',
                      '$totalTypes tipos',
                      isDark ? const Color(0xFF1E2640) : const Color(0xFFE0E7FF),
                      isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3),
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      'Zerados',
                      '$zeroCount esgotados',
                      isDark ? const Color(0xFF3B1818) : const Color(0xFFFEE2E2),
                      isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Lista / Grid de Bolos com Alto Contraste
              Expanded(
                child: _isLoading && _cakes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : displayList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🎂', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhum bolo encontrado',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cadastre bolos rápidos pelo botão abaixo',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadCakes(forceRefresh: true),
                            child: _isGridView
                                ? _buildGridView(displayList, isDark)
                                : _buildListView(displayList, isDark),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Bolo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openSimpleCakeModal(),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 1),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
          ],
        ),
      ),
    );
  }

  /// Visão Padrão: Lista de Balcão (Ergonômica, Limpa e com Alto Contraste)
  Widget _buildListView(List<SimpleCake> list, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), // Espaço para não tampar com o FAB
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cake = list[index];
        final emoji = _getCakeEmoji(cake.name);
        final isZero = cake.quantity == 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isZero
                  ? (isDark ? Colors.red.shade900 : Colors.red.shade300)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isZero ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji em destaque
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),

              // Nome do Bolo + Badge de Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cake.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isZero
                            ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isZero
                            ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                            : (isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isZero ? '⚠️ ESGOTADO' : '✓ DISPONÍVEL',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isZero
                              ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
                              : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu discreto de opções
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white38 : Colors.grey.shade400),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openSimpleCakeModal(cake: cake);
                  } else if (val == 'delete') {
                    _deleteCake(cake);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Renomear'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              // Botão Menos (-)
              Material(
                color: isZero
                    ? (isDark ? Colors.white10 : Colors.grey.shade100)
                    : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _adjustQty(cake, -1),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.remove,
                      color: isZero
                          ? (isDark ? Colors.white24 : Colors.grey.shade400)
                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                      size: 22,
                    ),
                  ),
                ),
              ),

              // Quantidade com Toque para Digitar
              InkWell(
                onTap: () => _promptExactQty(cake),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 46),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Column(
                    children: [
                      Text(
                        '${cake.quantity}',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isZero
                              ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      Text(
                        'un',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botão Mais (+)
              Material(
                color: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _adjustQty(cake, 1),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.add,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Visão alternativa em Grid (Cards Compactos e Proporcionais)
  Widget _buildGridView(List<SimpleCake> list, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88, // Proporção mais compacta, sem vazios exagerados
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cake = list[index];
        return _buildCakeGridCard(cake, isDark);
      },
    );
  }

  /// Card Visual no Grid (com contraste AAA em Dark/Light Mode)
  Widget _buildCakeGridCard(SimpleCake cake, bool isDark) {
    final emoji = _getCakeEmoji(cake.name);
    final isZero = cake.quantity == 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isZero
              ? (isDark ? Colors.red.shade900 : Colors.red.shade300)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isZero ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Menu de opções
          Positioned(
            top: 2,
            right: 2,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, size: 20, color: isDark ? Colors.white38 : Colors.grey.shade400),
              onSelected: (val) {
                if (val == 'edit') {
                  _openSimpleCakeModal(cake: cake);
                } else if (val == 'delete') {
                  _deleteCake(cake);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Renomear'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo: Emoji + Nome + Status + Quantidade + Botões
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Topo: Emoji
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 30),
                ),

                // Nome do Bolo com ALTO CONTRASTE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    cake.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isZero
                          ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isZero
                        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                        : (isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isZero ? '⚠️ ESGOTADO' : '✓ DISPONÍVEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: isZero
                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
                          : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)),
                    ),
                  ),
                ),

                // Quantidade (Toque para editar o número direto)
                InkWell(
                  onTap: () => _promptExactQty(cake),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    child: Column(
                      children: [
                        Text(
                          '${cake.quantity}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isZero
                                ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                               : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          cake.quantity == 1 ? 'unidade' : 'unidades',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botões de Ajuste Rápido [-] e [+]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botão Menos (-)
                    Material(
                      color: isZero
                          ? (isDark ? Colors.white10 : Colors.grey.shade100)
                          : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _adjustQty(cake, -1),
                        child: SizedBox(
                          width: 44,
                          height: 38,
                          child: Icon(
                            Icons.remove,
                            color: isZero
                                ? (isDark ? Colors.white24 : Colors.grey.shade400)
                                : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botão Mais (+)
                    Material(
                      color: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _adjustQty(cake, 1),
                        child: SizedBox(
                          width: 44,
                          height: 38,
                          child: Icon(
                            Icons.add,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
