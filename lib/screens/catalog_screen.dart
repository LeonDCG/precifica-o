import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../database/db_helper.dart';
import 'add_product_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    final prods = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  Map<String, List<Product>> _getGroupedProducts() {
    final Map<String, List<Product>> grouped = {};
    for (var product in _products) {
      final cat = product.category;
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(product);
    }
    return grouped;
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
                          itemCount: _getGroupedProducts().length,
                          itemBuilder: (context, index) {
                            final category = _getGroupedProducts().keys.elementAt(index);
                            final categoryProducts = _getGroupedProducts()[category]!;

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
                                  final imageUrl = product.imagePath.isNotEmpty ? product.imagePath : _getPlaceholderImage(_products.indexOf(product));

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
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            // Imagem de fundo real (trata network ou base64)
                                            Positioned.fill(
                                              child: imageUrl.startsWith('data:')
                                                  ? Image.memory(
                                                      base64Decode(imageUrl.split(',').last),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
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
                                                        color: Theme.of(context).colorScheme.secondary,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text('DESTAQUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                                          color: isPositive ? Colors.green[800] : Colors.red[800],
                                                          borderRadius: BorderRadius.circular(8),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.2),
                                                              blurRadius: 4,
                                                              offset: const Offset(0, 2),
                                                            )
                                                          ],
                                                        ),
                                                        child: Text(
                                                          product.yieldAmount > 1 
                                                              ? 'LUCRO: R\$ ${profitPerUnit.toStringAsFixed(2)} / ${product.unit}'
                                                              : 'LUCRO: R\$ ${profit.toStringAsFixed(2)}',
                                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      );
                                                    }
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
                                            top: 12, right: 56,
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
                                                    msg += '💰 Valor Total: R\$ ${total.toStringAsFixed(2)}\n';
                                                    msg += '💵 Valor / ${product.unit}: R\$ $fraction\n';
                                                  } else {
                                                    msg += '💰 Valor: R\$ ${total.toStringAsFixed(2)} / ${product.unit}\n';
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

}
