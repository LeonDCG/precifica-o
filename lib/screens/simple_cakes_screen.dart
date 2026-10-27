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
    final q = _searchQuery.toLowerCase();
    return _cakes.where((c) {
      final name = c.name.toLowerCase();
      final cat = c.category.toLowerCase();
      final notes = (c.notes ?? '').toLowerCase();
      return name.contains(q) || cat.contains(q) || notes.contains(q);
    }).toList();
  }

  Future<void> _adjustQty(SimpleCake cake, int delta) async {
    final currentQty = cake.quantity;
    final newQty = (currentQty + delta) < 0 ? 0 : (currentQty + delta);

    if (currentQty == 0 && delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O bolo "${cake.name}" já está zerado!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // 1. Atualização Otimista Imediata
    setState(() {
      final idx = _cakes.indexWhere((c) => c.id == cake.id);
      if (idx != -1) {
        _cakes[idx] = _cakes[idx].copyWith(quantity: newQty);
      }
    });

    // 2. Persistência no Banco Supabase
    try {
      if (cake.id != null) {
        await DatabaseHelper.instance.updateSimpleCakeQuantity(cake.id!, newQty);
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar quantidade no Supabase: $e');
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

  Future<void> _promptExactQty(SimpleCake cake) async {
    final controller = TextEditingController(text: cake.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Definir Quantidade de ${cake.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Quantidade em Balcão (unidades)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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

  Future<void> _openCakeModal({SimpleCake? cake}) async {
    final isEditing = cake != null;
    final nameCtrl = TextEditingController(text: cake?.name ?? '');
    final qtyCtrl = TextEditingController(text: cake?.quantity.toString() ?? '1');
    final catCtrl = TextEditingController(text: cake?.category ?? 'Bolo Caseiro');
    final ifoodCtrl = TextEditingController(text: (cake != null && cake.ifoodPrice > 0) ? cake.ifoodPrice.toStringAsFixed(2) : '');
    final food99Ctrl = TextEditingController(text: (cake != null && cake.food99Price > 0) ? cake.food99Price.toStringAsFixed(2) : '');
    final notesCtrl = TextEditingController(text: cake?.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🎂', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEditing ? 'Editar Bolo' : 'Novo Bolo (Sem Ficha)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Nome do Bolo *',
                  hintText: 'Ex: Cenoura com Chocolate, Red Velvet...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: catCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ifoodCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço iFood (R\$)',
                        hintText: '22.99',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.circle, color: Colors.red, size: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: food99Ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço 99Food (R\$)',
                        hintText: '24.99',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.circle, color: Colors.orange, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações / Sabores / Tamanho',
                  hintText: 'Ex: Bolo Matilda, cobertura durinha...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
              final cat = catCtrl.text.trim().isEmpty ? 'Bolo Caseiro' : catCtrl.text.trim();
              final ifood = double.tryParse(ifoodCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
              final food99 = double.tryParse(food99Ctrl.text.replaceAll(',', '.').trim()) ?? 0.0;
              final notes = notesCtrl.text.trim();

              Navigator.pop(ctx);

              if (isEditing) {
                final updated = cake.copyWith(
                  name: name,
                  quantity: qty,
                  category: cat,
                  ifoodPrice: ifood,
                  food99Price: food99,
                  notes: notes,
                );
                setState(() {
                  final idx = _cakes.indexWhere((c) => c.id == cake.id);
                  if (idx != -1) _cakes[idx] = updated;
                });
                await DatabaseHelper.instance.updateSimpleCake(updated);
              } else {
                final newCake = SimpleCake(
                  name: name,
                  quantity: qty,
                  category: cat,
                  ifoodPrice: ifood,
                  food99Price: food99,
                  notes: notes,
                );
                final saved = await DatabaseHelper.instance.createSimpleCake(newCake);
                setState(() {
                  _cakes.add(saved);
                  _cakes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                });
              }
              _loadCakes(forceRefresh: true);
            },
            child: Text(isEditing ? 'Salvar Alterações' : 'Cadastrar Bolo'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCake(SimpleCake cake) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Bolo'),
        content: Text('Deseja realmente excluir o bolo "${cake.name}" do controle direto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bolo "${cake.name}" excluído.')),
      );
    }
  }

  Map<String, dynamic> _getCakeTheme(String name) {
    final norm = name.toLowerCase();
    if (norm.contains('choc') || norm.contains('brigadeir') || norm.contains('cacau')) {
      return {'bg': const Color(0xFFFEF7EE), 'border': const Color(0xFF78350F), 'icon': '🍫'};
    }
    if (norm.contains('cenour') || norm.contains('laranja')) {
      return {'bg': const Color(0xFFFFF7ED), 'border': const Color(0xFFEA580C), 'icon': '🍰'};
    }
    if (norm.contains('fub') || norm.contains('milho')) {
      return {'bg': const Color(0xFFFEFCE8), 'border': const Color(0xFFCA8A04), 'icon': '🧁'};
    }
    if (norm.contains('morang') || norm.contains('red velvet')) {
      return {'bg': const Color(0xFFFDF2F8), 'border': const Color(0xFFEC4899), 'icon': '🍓'};
    }
    if (norm.contains('lim') || norm.contains('abacaxi')) {
      return {'bg': const Color(0xFFF0FDF4), 'border': const Color(0xFF16A34A), 'icon': '🍋'};
    }
    return {'bg': const Color(0xFFF8FAFC), 'border': const Color(0xFF64748B), 'icon': '🎂'};
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _cakes.fold<int>(0, (sum, c) => sum + c.quantity);
    final totalTypes = _cakes.length;
    final zeroCount = _cakes.where((c) => c.quantity == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controle Direto de Bolos',
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
              // Barra de Busca
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar bolo por sabor ou observação...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

              // Cards de Estatísticas no Topo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildStatPill('Total', '$totalUnits un', Colors.pink.shade100, Colors.pink.shade900),
                    const SizedBox(width: 8),
                    _buildStatPill('Tipos', '$totalTypes tipos', Colors.blue.shade100, Colors.blue.shade900),
                    const SizedBox(width: 8),
                    _buildStatPill('Zerados', '$zeroCount esgotados', Colors.red.shade100, Colors.red.shade900),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Lista de Bolos com botões rápidos (+ / -)
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
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Cadastre bolos rápidos pelo botão abaixo',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadCakes(forceRefresh: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: displayList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final cake = displayList[index];
                                return _buildCakeCard(cake);
                              },
                            ),
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
        onPressed: () => _openCakeModal(),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCakeCard(SimpleCake cake) {
    final theme = _getCakeTheme(cake.name);
    final isZero = cake.quantity == 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isZero ? Colors.red.shade300 : (theme['border'] as Color).withOpacity(0.4),
          width: isZero ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Informações do Bolo
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme['bg'] as Color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (theme['border'] as Color).withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(theme['icon'] as String, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cake.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isZero ? Colors.red.shade700 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isZero ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isZero ? '⚠️ ESGOTADO' : '✓ DISPONÍVEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isZero ? Colors.red.shade700 : Colors.green.shade800,
                              ),
                            ),
                          ),
                          if (cake.ifoodPrice > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '🔴 iFood: R\$ ${cake.ifoodPrice.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            ),
                          if (cake.food99Price > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '🟠 99: R\$ ${cake.food99Price.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                              ),
                            ),
                        ],
                      ),
                      if (cake.notes != null && cake.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📝 ${cake.notes!}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openCakeModal(cake: cake);
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
                          Text('Alterar'),
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
              ],
            ),
          ),

          // Barra inferior com botões rápidos (+ / -)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isZero ? Colors.red.shade50.withOpacity(0.4) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão Menos (-)
                Material(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _adjustQty(cake, -1),
                    child: const SizedBox(
                      width: 52,
                      height: 48,
                      child: Icon(Icons.remove, color: Colors.red, size: 28),
                    ),
                  ),
                ),

                // Quantidade (Toque para digitar)
                InkWell(
                  onTap: () => _promptExactQty(cake),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        Text(
                          '${cake.quantity}',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isZero ? Colors.red.shade700 : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'unidades',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Mais (+)
                Material(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _adjustQty(cake, 1),
                    child: const SizedBox(
                      width: 52,
                      height: 48,
                      child: Icon(Icons.add, color: Colors.green, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
