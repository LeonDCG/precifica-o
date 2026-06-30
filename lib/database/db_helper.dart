import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();

  SupabaseClient get _client => Supabase.instance.client;

  // --- INGREDIENTS CRUD ---
  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    var data = ingredient.toMap();
    data.remove('id'); // Deixa o Postgres gerar o ID
    final response = await _client.from('ingredients').insert(data).select().single();
    return Ingredient.fromMap(response);
  }

  Future<List<Ingredient>> readAllIngredients() async {
    final response = await _client.from('ingredients').select().order('name', ascending: true);
    return response.map<Ingredient>((json) => Ingredient.fromMap(json)).toList();
  }

  Future<int> deleteIngredient(int id) async {
    await _client.from('ingredients').delete().eq('id', id);
    return 1;
  }

  Future<int> updateIngredient(Ingredient ingredient) async {
    var data = ingredient.toMap();
    data.remove('id');
    await _client.from('ingredients').update(data).eq('id', ingredient.id!);
    return 1;
  }

  // --- PRODUCTS CRUD ---
  Future<Product> createProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    final response = await _client.from('products').insert(prodData).select().single();
    final newProdId = response['id'] as int;
    product.id = newProdId;
    
    for (var pi in product.ingredients) {
      pi.productId = newProdId;
      var piData = pi.toMap();
      piData.remove('id');
      await _client.from('product_ingredients').insert(piData);
    }
    return product;
  }

  Future<List<Product>> readAllProducts() async {
    final productsResponse = await _client.from('products').select().order('name', ascending: true);
    List<Product> products = productsResponse.map<Product>((json) => Product.fromMap(json)).toList();
    
    final allIngredients = await readAllIngredients();

    for (var product in products) {
      final piMaps = await _client.from('product_ingredients').select().eq('productid', product.id!);
      product.ingredients = piMaps.map<ProductIngredient>((json) {
        final pi = ProductIngredient.fromMap(json);
        try {
          final ing = allIngredients.firstWhere((i) => i.id == pi.ingredientId);
          pi.ingredientName = ing.name;
          pi.ingredientUnit = ing.unit;
        } catch (_) {}
        return pi;
      }).toList();
    }
    return products;
  }

  Future<int> deleteProduct(int id) async {
    await _client.from('product_ingredients').delete().eq('productid', id);
    await _client.from('products').delete().eq('id', id);
    return 1;
  }

  Future<int> updateProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    await _client.from('products').update(prodData).eq('id', product.id!);

    // Recreate ingredients
    await _client.from('product_ingredients').delete().eq('productid', product.id!);
    for (var pi in product.ingredients) {
      pi.productId = product.id!;
      var piData = pi.toMap();
      piData.remove('id');
      await _client.from('product_ingredients').insert(piData);
    }
    return 1;
  }

  // --- SETTINGS ---
  Future<void> saveSetting(String key, String value) async {
    await _client.from('settings').upsert({'key': key, 'value': value});
  }

  Future<String?> getSetting(String key) async {
    final response = await _client.from('settings').select('value').eq('key', key).maybeSingle();
    if (response != null) {
      return response['value'] as String;
    }
    return null;
  }

  Future close() async {
    // No-op for Supabase
  }

  // --- SEED DATA (Massa de Teste) ---
  Future<void> seedData() async {
    final ingredients = await readAllIngredients();
    if (ingredients.isNotEmpty) return; // Já tem dados na nuvem

    // 1. Insumos
    final i1 = await createIngredient(Ingredient(name: 'Farinha de Trigo', unit: 'g', price: 5.0, quantity: 1000, type: 'ingredient', category: 'SECOS'));
    final i2 = await createIngredient(Ingredient(name: 'Açúcar Refinado', unit: 'g', price: 4.5, quantity: 1000, type: 'ingredient', category: 'SECOS'));
    final i3 = await createIngredient(Ingredient(name: 'Leite Condensado', unit: 'g', price: 6.0, quantity: 395, type: 'ingredient', category: 'LATICÍNIOS'));
    final i4 = await createIngredient(Ingredient(name: 'Ovos', unit: 'unidade', price: 18.0, quantity: 30, type: 'ingredient', category: 'LATICÍNIOS')); 
    final i5 = await createIngredient(Ingredient(name: 'Chocolate em Pó 50%', unit: 'g', price: 35.0, quantity: 1000, type: 'ingredient', category: 'SECOS'));
    
    // 2. Produto Final
    await createProduct(Product(
      name: 'Bolo de Brigadeiro Simples',
      suggestedPrice: 80.0,
      sellPrice: 80.0,
      profitMarginPercent: 150,
      imagePath: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      isFeatured: true,
      category: 'Bolos Inteiros',
      unit: 'unidade',
      yieldAmount: 1.0,
      ingredients: [
        ProductIngredient(productId: 0, ingredientId: i1.id!, ingredientName: i1.name, ingredientUnit: i1.unit, quantityUsed: 300, cost: i1.unitPrice * 300),
        ProductIngredient(productId: 0, ingredientId: i2.id!, ingredientName: i2.name, ingredientUnit: i2.unit, quantityUsed: 200, cost: i2.unitPrice * 200),
        ProductIngredient(productId: 0, ingredientId: i4.id!, ingredientName: i4.name, ingredientUnit: i4.unit, quantityUsed: 4, cost: i4.unitPrice * 4),
        ProductIngredient(productId: 0, ingredientId: i5.id!, ingredientName: i5.name, ingredientUnit: i5.unit, quantityUsed: 100, cost: i5.unitPrice * 100),
        ProductIngredient(productId: 0, ingredientId: i3.id!, ingredientName: i3.name, ingredientUnit: i3.unit, quantityUsed: 395, cost: i3.unitPrice * 395),
      ],
    ));
  }
}
