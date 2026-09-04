import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/product.dart';
import '../models/recipe.dart';
import '../models/sale.dart';
import '../models/refrigerator_item.dart';
import '../models/profile.dart';
import '../models/order_request.dart';

class DatabaseHelper {
  static const String supabaseUrl = 'https://jfpswioaikpflvjiylqa.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmcHN3aW9haWtwZmx2aml5bHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMzA3ODQsImV4cCI6MjA5NDkwNjc4NH0.lZmckQNXdD99KAWpdYoY9Eb5rRdcmVzQh9S67rXXPdM';

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

  // --- RECIPES CRUD ---
  Future<Recipe> createRecipe(Recipe recipe) async {
    var recData = recipe.toMap();
    recData.remove('id');
    final response = await _client.from('recipes').insert(recData).select().single();
    final newRecId = response['id'] as int;
    recipe.id = newRecId;

    for (var ri in recipe.ingredients) {
      ri.recipeId = newRecId;
      var riData = ri.toMap();
      riData.remove('id');
      await _client.from('recipe_ingredients').insert(riData);
    }
    return recipe;
  }

  Future<List<Recipe>> readAllRecipes() async {
    final results = await Future.wait([
      _client.from('recipes').select().order('name', ascending: true),
      _client.from('ingredients').select('id, name, unit'),
      _client.from('recipe_ingredients').select(),
    ]);

    final recipesList = results[0] as List;
    final allIngredientsRaw = results[1] as List;
    final allRecipeIngredientsRaw = results[2] as List;

    final ingredientsMap = <int, Ingredient>{};
    for (var json in allIngredientsRaw) {
      final ing = Ingredient.fromMap(json);
      if (ing.id != null) ingredientsMap[ing.id!] = ing;
    }

    final recipeIngredientsByRecipeId = <int, List<RecipeIngredient>>{};
    for (var json in allRecipeIngredientsRaw) {
      final ri = RecipeIngredient.fromMap(json);
      if (ri.recipeId != null) {
        final ing = ingredientsMap[ri.ingredientId];
        if (ing != null) {
          ri.ingredientName = ing.name;
          ri.ingredientUnit = ing.unit;
        }
        recipeIngredientsByRecipeId.putIfAbsent(ri.recipeId!, () => []).add(ri);
      }
    }

    final List<Recipe> recipes = [];
    for (var json in recipesList) {
      final recipe = Recipe.fromMap(json);
      recipe.ingredients = recipeIngredientsByRecipeId[recipe.id] ?? [];
      recipes.add(recipe);
    }
    return recipes;
  }

  Future<int> deleteRecipe(int id) async {
    await _client.from('recipe_ingredients').delete().eq('recipeid', id);
    await _client.from('recipes').delete().eq('id', id);
    return 1;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    var recData = recipe.toMap();
    recData.remove('id');
    await _client.from('recipes').update(recData).eq('id', recipe.id!);

    // Recreate ingredients
    await _client.from('recipe_ingredients').delete().eq('recipeid', recipe.id!);
    for (var ri in recipe.ingredients) {
      ri.recipeId = recipe.id!;
      var riData = ri.toMap();
      riData.remove('id');
      await _client.from('recipe_ingredients').insert(riData);
    }
    return 1;
  }

  // --- PRODUCTS CRUD ---
  Future<Product> createProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    final response = await _client.from('products').insert(prodData).select().single();
    final newProdId = response['id'] as int;
    product.id = newProdId;
    
    for (var pr in product.recipes) {
      pr.productId = newProdId;
      var prData = pr.toMap();
      prData.remove('id');
      await _client.from('product_recipes').insert(prData);
    }
    for (var pe in product.extraExpenses) {
      pe.productId = newProdId;
      var peData = pe.toMap();
      peData.remove('id');
      await _client.from('product_expenses').insert(peData);
    }
    return product;
  }

  Future<List<Product>> readAllProducts() async {
    final results = await Future.wait([
      _client.from('products').select().order('name', ascending: true),
      _client.from('product_recipes').select(),
      _client.from('product_expenses').select(),
      _client.from('recipes').select('id, name'),
    ]);

    final productsList = results[0] as List;
    final allProductRecipesRaw = results[1] as List;
    final allProductExpensesRaw = results[2] as List;
    final allRecipesRaw = results[3] as List;

    final recipeNameMap = <int, String>{};
    for (var r in allRecipesRaw) {
      if (r['id'] != null && r['name'] != null) {
        recipeNameMap[r['id'] as int] = r['name'].toString();
      }
    }

    final productRecipesByProductId = <int, List<ProductRecipe>>{};
    for (var json in allProductRecipesRaw) {
      final pr = ProductRecipe.fromMap(json);
      if (pr.productId != null) {
        pr.recipeName = recipeNameMap[pr.recipeId] ?? '';
        productRecipesByProductId.putIfAbsent(pr.productId!, () => []).add(pr);
      }
    }

    final productExpensesByProductId = <int, List<ProductExpense>>{};
    for (var json in allProductExpensesRaw) {
      final pe = ProductExpense.fromMap(json);
      if (pe.productId != null) {
        productExpensesByProductId.putIfAbsent(pe.productId!, () => []).add(pe);
      }
    }

    final List<Product> products = [];
    for (var json in productsList) {
      final product = Product.fromMap(json);
      product.recipes = productRecipesByProductId[product.id] ?? [];
      product.extraExpenses = productExpensesByProductId[product.id] ?? [];
      products.add(product);
    }
    return products;
  }

  Future<Map<int, String>> getProductImages() async {
    try {
      final response = await _client.from('products').select('id, imagepath');
      final map = <int, String>{};
      for (var r in response) {
        if (r['id'] != null && r['imagepath'] != null && r['imagepath'].toString().isNotEmpty) {
          map[r['id'] as int] = r['imagepath'].toString();
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<int> deleteProduct(int id) async {
    await _client.from('product_recipes').delete().eq('productid', id);
    await _client.from('product_expenses').delete().eq('productid', id);
    await _client.from('products').delete().eq('id', id);
    return 1;
  }

  Future<int> updateProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    await _client.from('products').update(prodData).eq('id', product.id!);

    // Recreate recipes
    await _client.from('product_recipes').delete().eq('productid', product.id!);
    for (var pr in product.recipes) {
      pr.productId = product.id!;
      var prData = pr.toMap();
      prData.remove('id');
      await _client.from('product_recipes').insert(prData);
    }

    // Recreate expenses
    await _client.from('product_expenses').delete().eq('productid', product.id!);
    for (var pe in product.extraExpenses) {
      pe.productId = product.id!;
      var peData = pe.toMap();
      peData.remove('id');
      await _client.from('product_expenses').insert(peData);
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

  Future<Map<String, String>> getAllSettings() async {
    try {
      final response = await _client.from('settings').select();
      final map = <String, String>{};
      for (var row in response) {
        if (row['key'] != null && row['value'] != null) {
          map[row['key'].toString()] = row['value'].toString();
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  // --- SALES CRUD ---
  Future<Sale> createSale(Sale sale) async {
    var data = sale.toMap();
    data.remove('id');
    final response = await _client.from('sales').insert(data).select().single();
    return Sale.fromMap(response);
  }

  Future<List<Sale>> readAllSales() async {
    final response = await _client.from('sales').select().order('saledate', ascending: false);
    return response.map<Sale>((json) => Sale.fromMap(json)).toList();
  }

  Future<int> deleteSale(int id) async {
    await _client.from('sales').delete().eq('id', id);
    return 1;
  }  Future close() async {
    // No-op for Supabase
  }

  // --- SEED DATA ---
  Future<void> seedData() async {
    // No-op - we don't seed manually since Supabase has real data
  }

  // --- REFRIGERATOR STOCK CRUD ---
  Future<List<RefrigeratorItem>> readRefrigeratorStock() async {
    final response = await _client.from('refrigerator_stock').select().order('name', ascending: true);
    return response.map<RefrigeratorItem>((json) => RefrigeratorItem.fromMap(json)).toList();
  }

  Future<RefrigeratorItem> createRefrigeratorItem(RefrigeratorItem item) async {
    var data = item.toMap();
    data.remove('id');
    data.remove('last_updated');
    final response = await _client.from('refrigerator_stock').insert(data).select().single();
    return RefrigeratorItem.fromMap(response);
  }

  Future<int> updateRefrigeratorItem(RefrigeratorItem item) async {
    var data = item.toMap();
    data.remove('id');
    data.remove('last_updated');
    await _client.from('refrigerator_stock').update(data).eq('id', item.id!);
    return 1;
  }

  Future<int> deleteRefrigeratorItem(int id) async {
    await _client.from('refrigerator_stock').delete().eq('id', id);
    return 1;
  }

  Future<void> deductStockForProduct(int productId, double quantityToDeduct, {double yieldAmount = 1.0, bool isSliceSale = false}) async {
    try {
      final response = await _client
          .from('refrigerator_stock')
          .select()
          .eq('product_id', productId)
          .maybeSingle();

      if (response != null) {
        final item = RefrigeratorItem.fromMap(response);
        double finalDeduct = quantityToDeduct;
        // Se for venda de fatia e estoque estiver em unidades inteiras
        if (isSliceSale && yieldAmount > 1 && item.unit.toLowerCase() == 'unidade') {
          finalDeduct = quantityToDeduct / yieldAmount;
        }
        final newQuantity = (item.quantity - finalDeduct).clamp(0.0, double.infinity);
        item.quantity = newQuantity;
        await updateRefrigeratorItem(item);
      }
    } catch (e) {
      // Falha silenciosa para não quebrar o fluxo de salvar venda
      print('Erro ao deduzir estoque: $e');
    }
  }

  // --- PROFILES & ROLES ---
  Future<Profile?> getProfile(String uid) async {
    try {
      final response = await _client.from('profiles').select().eq('id', uid).maybeSingle();
      if (response != null) {
        return Profile.fromMap(response);
      }
    } catch (e) {
      print('Erro ao buscar perfil: $e');
    }
    return null;
  }

  Future<void> createProfile(Profile profile) async {
    try {
      await _client.from('profiles').insert(profile.toMap());
    } catch (e) {
      print('Erro ao criar perfil: $e');
    }
  }

  Future<List<Profile>> getSellers() async {
    try {
      final response = await _client.rpc('get_sellers_with_emails');
      return (response as List).map<Profile>((json) => Profile.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao obter vendedores por RPC, tentando fallback: $e');
      final response = await _client.from('profiles').select().eq('role', 'seller').order('name');
      return response.map<Profile>((json) => Profile.fromMap(json)).toList();
    }
  }

  Future<void> updateProfileName(String uid, String newName, {String? oldName, double? commissionPercent}) async {
    final Map<String, dynamic> updateData = {'name': newName};
    if (commissionPercent != null) {
      updateData['commission_percent'] = commissionPercent;
    }
    await _client.from('profiles').update(updateData).eq('id', uid);

    if (oldName != null && oldName.trim().isNotEmpty && oldName.trim().toLowerCase() != newName.trim().toLowerCase()) {
      await _client
          .from('sales')
          .update({'sellername': newName.trim()})
          .ilike('sellername', oldName.trim());
    }
  }

  Future<void> adminUpdateUser(String userId, {String? email, String? password}) async {
    await _client.rpc('admin_update_user', params: {
      'user_id': userId,
      'new_email': email ?? '',
      'new_password': password ?? '',
    });
  }

  Future<void> deleteProfile(String uid) async {
    await _client.from('profiles').delete().eq('id', uid);
  }

  // --- SELLER CONSIGNED STOCK ---
  Future<List<Map<String, dynamic>>> getSellerStock(String sellerId) async {
    final response = await _client
        .from('seller_stock')
        .select('*, products(name, unit, yieldAmount)')
        .eq('seller_id', sellerId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addSellerStock(String sellerId, int productId, double qty) async {
    try {
      final response = await _client
          .from('seller_stock')
          .select()
          .eq('seller_id', sellerId)
          .eq('product_id', productId)
          .maybeSingle();

      if (response != null) {
        final currentQty = ((response['quantity'] ?? 0.0) as num).toDouble();
        await _client
            .from('seller_stock')
            .update({'quantity': currentQty + qty, 'last_updated': DateTime.now().toIso8601String()})
            .eq('seller_id', sellerId)
            .eq('product_id', productId);
      } else {
        await _client.from('seller_stock').insert({
          'seller_id': sellerId,
          'product_id': productId,
          'quantity': qty,
        });
      }
    } catch (e) {
      print('Erro ao adicionar estoque consignado do vendedor: $e');
    }
  }

  Future<void> deductSellerStock(String sellerId, int productId, double qty, {double yieldAmount = 1.0, bool isSliceSale = false}) async {
    try {
      final response = await _client
          .from('seller_stock')
          .select('*, products(unit)')
          .eq('seller_id', sellerId)
          .eq('product_id', productId)
          .maybeSingle();

      if (response != null) {
        final currentQty = ((response['quantity'] ?? 0.0) as num).toDouble();
        double finalDeduct = qty;
        final productUnit = response['products']?['unit']?.toString().toLowerCase() ?? 'unidade';
        if (isSliceSale && yieldAmount > 1 && productUnit == 'unidade') {
          finalDeduct = qty / yieldAmount;
        }
        final newQty = (currentQty - finalDeduct).clamp(0.0, double.infinity);
        await _client
            .from('seller_stock')
            .update({'quantity': newQty, 'last_updated': DateTime.now().toIso8601String()})
            .eq('seller_id', sellerId)
            .eq('product_id', productId);
      }
    } catch (e) {
      print('Erro ao deduzir estoque consignado do vendedor: $e');
    }
  }

  // --- ORDER REQUESTS ---
  Future<void> createOrderRequest(OrderRequest req) async {
    var data = req.toMap();
    data.remove('id');
    await _client.from('order_requests').insert(data);
  }

  Future<List<OrderRequest>> getSellerOrderRequests(String sellerId) async {
    final response = await _client
        .from('order_requests')
        .select('*, products(name)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return response.map<OrderRequest>((json) => OrderRequest.fromMap(json)).toList();
  }

  Future<List<OrderRequest>> getAllOrderRequests() async {
    final response = await _client
        .from('order_requests')
        .select('*, products(name), profiles(name)')
        .order('created_at', ascending: false);
    return response.map<OrderRequest>((json) => OrderRequest.fromMap(json)).toList();
  }

  Future<void> updateOrderRequestStatus(int id, String status) async {
    await _client.from('order_requests').update({'status': status}).eq('id', id);
  }

  Future<void> deliverOrderRequest(int requestId) async {
    try {
      final response = await _client
          .from('order_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (response != null) {
        final sellerId = response['seller_id'];
        final productId = response['product_id'];
        final qty = ((response['quantity'] ?? 0.0) as num).toDouble();

        // 1. Atualizar status para entregue
        await updateOrderRequestStatus(requestId, 'delivered');
        // 2. Incrementar estoque consignado do vendedor
        await addSellerStock(sellerId, productId, qty);
      }
    } catch (e) {
      print('Erro ao entregar pedido: $e');
    }
  }
}
