import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../database/db_helper.dart';
import 'add_product_screen.dart';
import '../widgets/app_cached_image.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Product> _products = [];
  Map<String, List<Product>> _groupedProducts = {};
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final cached = DatabaseHelper.instance.cachedProducts;
    if (cached != null && cached.isNotEmpty) {
      _products = cached;
      _groupAndSetProducts(cached);
      _isLoading = false;
    }
    _refreshProducts();
  }

  void _groupAndSetProducts(List<Product> prods) {
    final Map<String, List<Product>> grouped = {};
    for (var product in prods) {
      final cat = product.category.trim().isEmpty ? 'Geral' : product.category.trim();
      grouped.putIfAbsent(cat, () => []).add(product);
    }
    _groupedProducts = grouped;
    _categories = grouped.keys.toList();
  }

  Future<void> _refreshProducts({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_products.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final prods = await DatabaseHelper.instance.readAllProducts(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _products = prods;
          _groupAndSetProducts(prods);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPlaceholderImage(int index) {
    // Retorna imagens lindíssimas do Unsplash de bolos/doces
    final urls = [
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=800&q=80', // Bolo Trufado
      'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?auto=format&fit=crop&w=800&q=80', // Torta Morango
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', // Croissant
      'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?auto=format&fit=crop&w=800&q=80', // Macarons
      'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?auto=format&fit=crop&w=800&q=80', // Cupcakes
    ];
    return urls[index % urls.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 24),
            const SizedBox(width: 8),
            Text('Catálogo', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meus Produtos', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                          Text('${_products.length} itens cadastrados', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                          _refreshProducts();
                        },
                        child: const Icon(Icons.add),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: _products.isEmpty
                      ? Center(child: Text('Nenhum produto cadastrado.', style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final categoryProducts = _groupedProducts[category] ?? [];

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
                                ...categoryProducts.map((product) {
                                  product.calculateSuggestedPrice();
                                  final imageUrl = product.imagePath.isNotEmpty ? product.imagePath : _getPlaceholderImage(product.id ?? 0);

                                  return InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => AddProductScreen(product: product)),
                                      );
                                      _refreshProducts();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            // Imagem de fundo real com AppCachedImage
                                            Positioned.fill(
                                              child: AppCachedImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                cacheWidth: 600,
                                                cacheHeight: 400,
                                              ),
                                            ),
                                            // Gradiente escuro em baixo
                                            Positioned(
                                              bottom: 0, left: 0, right: 0,
                                              height: 80,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Selo de Destaque e Lucro
                                            Positioned(
                                              top: 16, left: 16,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (product.isFeatured || _products.indexOf(product) == 0)
                                                    Container(
                                                      margin: const EdgeInsets.only(bottom: 6),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFC29B62), // brandGold
                                                        borderRadius: BorderRadius.circular(20), // Cápsula
                                                      ),
                                                      child: const Text(
                                                        'DESTAQUE', 
                                                        style: TextStyle(
                                                          color: Colors.white, 
                                                          fontSize: 9, 
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ),
                                                  Builder(
                                                    builder: (context) {
                                                      final totalVal = product.sellPrice > 0 ? product.sellPrice : product.suggestedPrice;
                                                      final profit = totalVal - product.totalCost;
                                                      final profitPerUnit = product.yieldAmount > 0 ? profit / product.yieldAmount : 0.0;
                                                      final isPositive = profit >= 0;

                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), // Pastel
                                                          borderRadius: BorderRadius.circular(20), // Cápsula
                                                        ),
                                                        child: Text(
                                                          product.yieldAmount > 1 
                                                              ? 'LUCRO: R\$ ${profitPerUnit.toStringAsFixed(2)} / ${product.unit}'
                                                              : 'LUCRO: R\$ ${profit.toStringAsFixed(2)}',
                                                          style: TextStyle(
                                                            color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
                                                            fontSize: 9, 
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Selo / Botão Preço iFood
                                                  GestureDetector(
                                                    onTap: () => _showIfoodPriceDialog(product),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: product.ifoodPrice > 0 ? const Color(0xFFEA1D2C) : Colors.black.withValues(alpha: 0.65),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: product.ifoodPrice > 0
                                                            ? null
                                                            : Border.all(color: const Color(0xFFEA1D2C).withValues(alpha: 0.7), width: 1),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.2),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.delivery_dining, color: Colors.white, size: 13),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            product.ifoodPrice > 0
                                                                ? 'iFood: R\$ ${product.ifoodPrice.toStringAsFixed(2)}'
                                                                : '+ Preço iFood',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 0.4,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 3),
                                                          const Icon(Icons.edit, color: Colors.white70, size: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // Botão de deletar
                                          Positioned(
                                            top: 12, right: 12,
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.white,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                onPressed: () async {
                                                  await DatabaseHelper.instance.deleteProduct(product.id!);
                                                  _refreshProducts();
                                                },
                                              ),
                                            ),
                                          ),
                                          // Botão WhatsApp Share
                                          Positioned(
                                            top: 12, right: 52,
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.white,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.share, size: 16, color: Colors.green),
                                                onPressed: () async {
                                                  final total = product.sellPrice > 0 ? product.sellPrice : product.suggestedPrice;
                                                  final fraction = product.yieldAmount > 1 ? (total / product.yieldAmount).toStringAsFixed(2) : '';
                                                  
                                                  String msg = 'Olá! Segue o detalhe do nosso produto:\n\n';
                                                  msg += '🎂 *${product.name}*\n';
                                                  if (product.yieldAmount > 1) {
                                                    msg += '📦 Rende: ${product.yieldAmount.toInt()} ${product.unit}(s)\n';
                                                    msg += '💰 Valor Total (Loja): R\$ ${total.toStringAsFixed(2)}\n';
                                                    msg += '💵 Valor / ${product.unit}: R\$ $fraction\n';
                                                  } else {
                                                    msg += '💰 Valor (Loja): R\$ ${total.toStringAsFixed(2)} / ${product.unit}\n';
                                                  }
                                                  if (product.ifoodPrice > 0) {
                                                    msg += '🛵 Valor no iFood: R\$ ${product.ifoodPrice.toStringAsFixed(2)}\n';
                                                  }
                                                  msg += '\nGostaria de fazer uma encomenda?';
                                                  
                                                  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          // Botão iFood Preço Rápido
                                          Positioned(
                                            top: 12, right: 92,
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: product.ifoodPrice > 0 ? const Color(0xFFEA1D2C) : Colors.white,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                tooltip: 'Preço no iFood',
                                                icon: Icon(
                                                  Icons.delivery_dining,
                                                  size: 16,
                                                  color: product.ifoodPrice > 0 ? Colors.white : const Color(0xFFEA1D2C),
                                                ),
                                                onPressed: () => _showIfoodPriceDialog(product),
                                              ),
                                            ),
                                          ),

                                          // Título e Preço
                                          Positioned(
                                            bottom: 16, left: 16, right: 16,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        style: GoogleFonts.merriweather(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (product.yieldAmount > 1)
                                                        Text(
                                                          'Rende ${product.yieldAmount.toInt()} ${product.unit}(s)',
                                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'R\$ ${product.sellPrice > 0 ? product.sellPrice.toStringAsFixed(2) : product.suggestedPrice.toStringAsFixed(2)}',
                                                      style: GoogleFonts.merriweather(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    if (product.yieldAmount > 1)
                                                      Text(
                                                        'R\$ ${((product.sellPrice > 0 ? product.sellPrice : product.suggestedPrice) / product.yieldAmount).toStringAsFixed(2)} / ${product.unit}',
                                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                    if (product.yieldAmount <= 1)
                                                      Text(
                                                        '/ ${product.unit}',
                                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                      ),
                                                    if (product.ifoodPrice > 0)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(
                                                          'iFood: R\$ ${product.ifoodPrice.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            color: Color(0xFFFF8A80),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ), // Stack
                                    ), // ClipRRect
                                  ), // Container
                                ); // InkWell
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

  Future<void> _showIfoodPriceDialog(Product product) async {
    final basePrice = product.sellPrice > 0 ? product.sellPrice : product.suggestedPrice;
    final controller = TextEditingController(
      text: product.ifoodPrice > 0 ? product.ifoodPrice.toStringAsFixed(2) : '',
    );
    double currentInputPrice = product.ifoodPrice > 0 ? product.ifoodPrice : 0.0;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Sugestão com base na taxa padrão de 27% (Plano Entrega iFood)
            // Preço iFood = Preço Loja / 0.73 para cobrir os 27%
            final suggestedIfood = basePrice > 0 ? (basePrice / 0.73) : 0.0;
            
            final retention27 = currentInputPrice * 0.27;
            final netPayout = currentInputPrice * 0.73;
            final netProfit = netPayout - product.totalCost;
            final isProfitPositive = netProfit >= 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA1D2C), // iFood Red
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preço de Venda iFood',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            product.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info de balcão
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Preço Balcão (Loja):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                'R\$ ${basePrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Custo Produção:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                'R\$ ${product.totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão de sugestão automática
                    if (basePrice > 0) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEA1D2C),
                          side: const BorderSide(color: Color(0xFFEA1D2C)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: Text('Sugerir R\$ ${suggestedIfood.toStringAsFixed(2)} (+27% iFood)'),
                        onPressed: () {
                          setDialogState(() {
                            currentInputPrice = suggestedIfood;
                            controller.text = suggestedIfood.toStringAsFixed(2);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Campo de Preço iFood
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Preço Praticado no iFood (R\$)',
                        hintText: 'Ex: 68.50',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFEA1D2C), width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          currentInputPrice = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                        });
                      },
                    ),

                    if (currentInputPrice > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA1D2C).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEA1D2C).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SIMULAÇÃO DE REPASSE (PLANO ENTREGA 27%):',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA1D2C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Comissão iFood (27%):', style: TextStyle(fontSize: 12)),
                                Text('- R\$ ${retention27.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Repasse Líquido iFood (73%):', style: TextStyle(fontSize: 12)),
                                Text('R\$ ${netPayout.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Lucro Líquido Real:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  'R\$ ${netProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isProfitPositive ? Colors.green[700] : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (product.ifoodPrice > 0)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await DatabaseHelper.instance.updateProductIfoodPrice(product.id!, 0.0);
                      setState(() {
                        product.ifoodPrice = 0.0;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Preço iFood removido de ${product.name}')),
                        );
                      }
                      _refreshProducts(forceRefresh: true);
                    },
                    child: const Text('Remover', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA1D2C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final newPrice = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
                    Navigator.pop(ctx);
                    await DatabaseHelper.instance.updateProductIfoodPrice(product.id!, newPrice);
                    setState(() {
                      product.ifoodPrice = newPrice;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Preço iFood de ${product.name} atualizado para R\$ ${newPrice.toStringAsFixed(2)}!'),
                          backgroundColor: const Color(0xFFEA1D2C),
                        ),
                      );
                    }
                    _refreshProducts(forceRefresh: true);
                  },
                  child: const Text('Salvar Preço'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

