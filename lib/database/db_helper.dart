import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // ==========================================
  // CACHE EM MEMÓRIA & DESDUPLICAÇÃO DE REDE
  // ==========================================
  List<Ingredient>? _cachedIngredients;
  List<Recipe>? _cachedRecipes;
  List<Product>? _cachedProducts;
  List<Product>? _cachedProductsSummary;
  int? _cachedProductCount;
  List<String>? _cachedCategories;
  Map<int, String>? _cachedProductImages;
  Map<String, String>? _cachedSettings;
  List<Sale>? _cachedSales;
  final Map<String, List<Sale>> _cachedSellerSales = {};
  List<RefrigeratorItem>? _cachedStock;

  // Getters para renderização instantânea (Stale-While-Revalidate)
  List<Ingredient>? get cachedIngredients => _cachedIngredients;
  List<Recipe>? get cachedRecipes => _cachedRecipes;
  List<Product>? get cachedProducts => _cachedProducts;
  List<Product>? get cachedProductsSummary => _cachedProductsSummary ?? _cachedProducts;
  List<Sale>? get cachedSales => _cachedSales;
  List<Sale>? getCachedSellerSales(String sellerName) => _cachedSellerSales[sellerName.trim().toLowerCase()];
  List<RefrigeratorItem>? get cachedStock => _cachedStock;
  Map<String, String>? get cachedSettings => _cachedSettings;

  // Futures em voo para desduplicar requisições concorrentes
  Future<List<Ingredient>>? _inFlightIngredients;
  Future<List<Recipe>>? _inFlightRecipes;
  Future<List<Product>>? _inFlightProducts;
  Future<List<Product>>? _inFlightProductsSummary;
  Future<Map<int, String>>? _inFlightProductImages;
  Future<Map<String, String>>? _inFlightSettings;
  Future<List<Sale>>? _inFlightSales;
  Future<List<RefrigeratorItem>>? _inFlightStock;

  void clearAllCache() {
    _cachedIngredients = null;
    _cachedRecipes = null;
    _cachedProducts = null;
    _cachedProductsSummary = null;
    _cachedProductCount = null;
    _cachedCategories = null;
    _cachedProductImages = null;
    _cachedSettings = null;
    _cachedSales = null;
    _cachedSellerSales.clear();
    _cachedStock = null;
    _cachedProfile = null;
  }

  void clearProductsCache() {
    _cachedProducts = null;
    _cachedProductsSummary = null;
    _cachedProductCount = null;
    _cachedCategories = null;
    _cachedProductImages = null;
  }

  void clearRecipesCache() {
    _cachedRecipes = null;
  }

  void clearIngredientsCache() {
    _cachedIngredients = null;
  }

  void clearSalesCache() {
    _cachedSales = null;
    _cachedSellerSales.clear();
  }

  void clearSettingsCache() {
    _cachedSettings = null;
  }

  void clearStockCache() {
    _cachedStock = null;
  }

  // --- INGREDIENTS CRUD ---
  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    var data = ingredient.toMap();
    data.remove('id'); // Deixa o Postgres gerar o ID
    final response = await _client.from('ingredients').insert(data).select().single();
    clearIngredientsCache();
    clearRecipesCache(); // Receitas dependem de ingredientes
    return Ingredient.fromMap(response);
  }

  Future<List<Ingredient>> readAllIngredients({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIngredients != null) {
      return _cachedIngredients!;
    }
    if (_inFlightIngredients != null) {
      return _inFlightIngredients!;
    }

    _inFlightIngredients = _fetchIngredients();
    try {
      final res = await _inFlightIngredients!;
      _cachedIngredients = res;
      return res;
    } finally {
      _inFlightIngredients = null;
    }
  }

  Future<List<Ingredient>> _fetchIngredients() async {
    final response = await _client.from('ingredients').select().order('name', ascending: true);
    return response.map<Ingredient>((json) => Ingredient.fromMap(json)).toList();
  }

  Future<int> deleteIngredient(int id) async {
    await _client.from('ingredients').delete().eq('id', id);
    clearIngredientsCache();
    clearRecipesCache();
    return 1;
  }

  Future<int> updateIngredient(Ingredient ingredient) async {
    var data = ingredient.toMap();
    data.remove('id');
    await _client.from('ingredients').update(data).eq('id', ingredient.id!);
    clearIngredientsCache();
    clearRecipesCache();
    return 1;
  }

  // --- RECIPES CRUD ---
  Future<Recipe> createRecipe(Recipe recipe) async {
    var recData = recipe.toMap();
    recData.remove('id');
    final response = await _client.from('recipes').insert(recData).select().single();
    final newRecId = response['id'] as int;
    recipe.id = newRecId;

    if (recipe.ingredients.isNotEmpty) {
      final List<Map<String, dynamic>> riDataList = [];
      for (var ri in recipe.ingredients) {
        ri.recipeId = newRecId;
        var riData = ri.toMap();
        riData.remove('id');
        riDataList.add(riData);
      }
      await _client.from('recipe_ingredients').insert(riDataList);
    }
    clearRecipesCache();
    clearProductsCache(); // Produtos dependem de receitas
    return recipe;
  }

  Future<List<Recipe>> readAllRecipes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRecipes != null) {
      return _cachedRecipes!;
    }
    if (_inFlightRecipes != null) {
      return _inFlightRecipes!;
    }

    _inFlightRecipes = _fetchRecipes();
    try {
      final res = await _inFlightRecipes!;
      _cachedRecipes = res;
      return res;
    } finally {
      _inFlightRecipes = null;
    }
  }

  Future<List<Recipe>> _fetchRecipes() async {
    final results = await Future.wait([
      _client.from('recipes').select().order('name', ascending: true),
      _client.from('ingredients').select('id, name, unit'),
      _client.from('recipe_ingredients').select(),
    ]);

    final recipesList = results[0] as List;
    final allIngredientsRaw = results[1] as List;
    final allRecipeIngredientsRaw = results[2] as List;

    final ingredientNameMap = <int, String>{};
    final ingredientUnitMap = <int, String>{};
    for (var json in allIngredientsRaw) {
      if (json['id'] != null) {
        final id = json['id'] as int;
        ingredientNameMap[id] = json['name']?.toString() ?? '';
        ingredientUnitMap[id] = json['unit']?.toString() ?? '';
      }
    }

    final recipeIngredientsByRecipeId = <int, List<RecipeIngredient>>{};
    for (var json in allRecipeIngredientsRaw) {
      final ri = RecipeIngredient.fromMap(json);
      if (ri.recipeId != 0) {
        ri.ingredientName = ingredientNameMap[ri.ingredientId] ?? '';
        ri.ingredientUnit = ingredientUnitMap[ri.ingredientId] ?? '';
        recipeIngredientsByRecipeId.putIfAbsent(ri.recipeId, () => []).add(ri);
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
    clearRecipesCache();
    clearProductsCache();
    return 1;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    var recData = recipe.toMap();
    recData.remove('id');
    await _client.from('recipes').update(recData).eq('id', recipe.id!);

    // Recreate ingredients em batch
    await _client.from('recipe_ingredients').delete().eq('recipeid', recipe.id!);
    if (recipe.ingredients.isNotEmpty) {
      final List<Map<String, dynamic>> riDataList = [];
      for (var ri in recipe.ingredients) {
        ri.recipeId = recipe.id!;
        var riData = ri.toMap();
        riData.remove('id');
        riDataList.add(riData);
      }
      await _client.from('recipe_ingredients').insert(riDataList);
    }
    clearRecipesCache();
    clearProductsCache();
    return 1;
  }

  // --- PRODUCTS CRUD ---
  Future<Product> createProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    final response = await _client.from('products').insert(prodData).select().single();
    final newProdId = response['id'] as int;
    product.id = newProdId;
    
    if (product.recipes.isNotEmpty) {
      final List<Map<String, dynamic>> prDataList = [];
      for (var pr in product.recipes) {
        pr.productId = newProdId;
        var prData = pr.toMap();
        prData.remove('id');
        prDataList.add(prData);
      }
      await _client.from('product_recipes').insert(prDataList);
    }
    if (product.extraExpenses.isNotEmpty) {
      final List<Map<String, dynamic>> peDataList = [];
      for (var pe in product.extraExpenses) {
        pe.productId = newProdId;
        var peData = pe.toMap();
        peData.remove('id');
        peDataList.add(peData);
      }
      await _client.from('product_expenses').insert(peDataList);
    }
    clearProductsCache();
    return product;
  }

  Future<List<Product>> readAllProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProducts != null) {
      return _cachedProducts!;
    }
    if (_inFlightProducts != null) {
      return _inFlightProducts!;
    }

    _inFlightProducts = _fetchProducts();
    try {
      final res = await _inFlightProducts!;
      _cachedProducts = res;
      _cachedProductsSummary = res;
      _cachedProductCount = res.length;
      // Atualizar também o cache de imagens para evitar query duplicada
      final imgMap = <int, String>{};
      for (var p in res) {
        if (p.id != null && p.imagePath.isNotEmpty) {
          imgMap[p.id!] = p.imagePath;
        }
      }
      _cachedProductImages = imgMap;
      return res;
    } finally {
      _inFlightProducts = null;
    }
  }

  Future<List<Product>> _fetchProducts() async {
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

  Future<Map<int, String>> getProductImages({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductImages != null) {
      return _cachedProductImages!;
    }
    // Se produtos já estão em cache, derive direto sem fazer requisição de rede
    if (_cachedProducts != null) {
      final map = <int, String>{};
      for (var p in _cachedProducts!) {
        if (p.id != null && p.imagePath.isNotEmpty) {
          map[p.id!] = p.imagePath;
        }
      }
      _cachedProductImages = map;
      return map;
    }

    if (_inFlightProductImages != null) {
      return _inFlightProductImages!;
    }

    _inFlightProductImages = _fetchProductImages();
    try {
      final res = await _inFlightProductImages!;
      _cachedProductImages = res;
      return res;
    } finally {
      _inFlightProductImages = null;
    }
  }

  Future<Map<int, String>> _fetchProductImages() async {
    try {
      final response = await _client.from('products').select('id, imagePath');
      final map = <int, String>{};
      for (var r in response) {
        if (r['id'] != null && r['imagePath'] != null && r['imagePath'].toString().isNotEmpty) {
          map[r['id'] as int] = r['imagePath'].toString();
        }
      }
      return map;
    } catch (e) {
      debugPrint('Erro ao buscar imagens de produtos: $e');
      return {};
    }
  }

  /// Busca resumida de produtos para telas que não precisam de receitas/despesas nem imagens Base64.
  /// Reduz o tráfego de rede e tempo de resposta em mais de 90%.
  Future<List<Product>> readProductsSummary({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductsSummary != null) {
      return _cachedProductsSummary!;
    }
    if (!forceRefresh && _cachedProducts != null) {
      _cachedProductsSummary = _cachedProducts;
      return _cachedProducts!;
    }
    if (_inFlightProductsSummary != null) {
      return _inFlightProductsSummary!;
    }

    _inFlightProductsSummary = _fetchProductsSummary();
    try {
      final res = await _inFlightProductsSummary!;
      _cachedProductsSummary = res;
      _cachedProductCount = res.length;
      return res;
    } finally {
      _inFlightProductsSummary = null;
    }
  }

  Future<List<Product>> _fetchProductsSummary() async {
    final response = await _client
        .from('products')
        .select('id, name, suggestedPrice, sellPrice, ifoodPrice, profitMarginPercent, isFeatured, category, unit, yieldAmount')
        .order('name', ascending: true);
    return (response as List).map<Product>((json) => Product.fromMap(json)).toList();
  }

  /// Retorna apenas a contagem total de produtos sem transferir dados pesados
  Future<int> getProductCount({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProductCount != null) {
      return _cachedProductCount!;
    }
    if (_cachedProducts != null) {
      _cachedProductCount = _cachedProducts!.length;
      return _cachedProductCount!;
    }
    if (_cachedProductsSummary != null) {
      _cachedProductCount = _cachedProductsSummary!.length;
      return _cachedProductCount!;
    }
    try {
      final response = await _client.from('products').select('id');
      final count = (response as List).length;
      _cachedProductCount = count;
      return count;
    } catch (_) {
      return _cachedProducts?.length ?? 0;
    }
  }

  /// Retorna categorias existentes de forma leve para o cadastro de produto
  Future<List<String>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null) {
      return _cachedCategories!;
    }
    if (_cachedProducts != null) {
      final cats = _cachedProducts!
          .map((p) => p.category.trim().isEmpty ? 'Geral' : p.category.trim())
          .toSet()
          .toList();
      _cachedCategories = cats;
      return cats;
    }
    if (_cachedProductsSummary != null) {
      final cats = _cachedProductsSummary!
          .map((p) => p.category.trim().isEmpty ? 'Geral' : p.category.trim())
          .toSet()
          .toList();
      _cachedCategories = cats;
      return cats;
    }
    try {
      final response = await _client.from('products').select('category');
      final Set<String> set = {};
      for (var r in response) {
        final c = r['category']?.toString().trim();
        set.add(c == null || c.isEmpty ? 'Geral' : c);
      }
      final list = set.toList();
      if (list.isEmpty) list.add('Geral');
      _cachedCategories = list;
      return list;
    } catch (_) {
      return ['Geral'];
    }
  }

  Future<int> deleteProduct(int id) async {
    await _client.from('product_recipes').delete().eq('productid', id);
    await _client.from('product_expenses').delete().eq('productid', id);
    await _client.from('products').delete().eq('id', id);
    clearProductsCache();
    return 1;
  }

  Future<int> updateProduct(Product product) async {
    var prodData = product.toMap();
    prodData.remove('id');
    await _client.from('products').update(prodData).eq('id', product.id!);

    // Recreate recipes
    await _client.from('product_recipes').delete().eq('productid', product.id!);
    if (product.recipes.isNotEmpty) {
      final List<Map<String, dynamic>> prDataList = [];
      for (var pr in product.recipes) {
        pr.productId = product.id!;
        var prData = pr.toMap();
        prData.remove('id');
        prDataList.add(prData);
      }
      await _client.from('product_recipes').insert(prDataList);
    }

    // Recreate expenses
    await _client.from('product_expenses').delete().eq('productid', product.id!);
    if (product.extraExpenses.isNotEmpty) {
      final List<Map<String, dynamic>> peDataList = [];
      for (var pe in product.extraExpenses) {
        pe.productId = product.id!;
        var peData = pe.toMap();
        peData.remove('id');
        peDataList.add(peData);
      }
      await _client.from('product_expenses').insert(peDataList);
    }
    clearProductsCache();
    return 1;
  }

  Future<void> updateProductIfoodPrice(int id, double ifoodPrice) async {
    await _client.from('products').update({'ifoodPrice': ifoodPrice}).eq('id', id);
    clearProductsCache();
  }

  // --- SETTINGS ---
  Future<void> saveSetting(String key, String value) async {
    await _client.from('settings').upsert({'key': key, 'value': value});
    if (_cachedSettings != null) {
      _cachedSettings![key] = value;
    }
  }

  Future<String?> getSetting(String key) async {
    if (_cachedSettings != null && _cachedSettings!.containsKey(key)) {
      return _cachedSettings![key];
    }
    try {
      final response = await _client.from('settings').select('value').eq('key', key).maybeSingle();
      if (response != null) {
        final val = response['value'] as String?;
        if (val != null) {
          _cachedSettings ??= {};
          _cachedSettings![key] = val;
        }
        return val;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>> getAllSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSettings != null) {
      return _cachedSettings!;
    }
    if (_inFlightSettings != null) {
      return _inFlightSettings!;
    }

    _inFlightSettings = _fetchAllSettings();
    try {
      final res = await _inFlightSettings!;
      _cachedSettings = res;
      return res;
    } finally {
      _inFlightSettings = null;
    }
  }

  Future<Map<String, String>> _fetchAllSettings() async {
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
    clearSalesCache();
    return Sale.fromMap(response);
  }

  Future<Sale> insertSale(Sale sale) => createSale(sale);

  Future<int> updateSale(Sale sale) async {
    var data = sale.toMap();
    await _client.from('sales').update(data).eq('id', sale.id!);
    clearSalesCache();
    return 1;
  }

  Future<List<Sale>> readAllSales({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSales != null) {
      return _cachedSales!;
    }
    if (_inFlightSales != null) {
      return _inFlightSales!;
    }

    _inFlightSales = _fetchSales();
    try {
      final res = await _inFlightSales!;
      _cachedSales = res;
      return res;
    } finally {
      _inFlightSales = null;
    }
  }

  Future<List<Sale>> _fetchSales() async {
    final response = await _client.from('sales').select().order('saledate', ascending: false);
    return response.map<Sale>((json) => Sale.fromMap(json)).toList();
  }

  /// Busca de vendas otimizada para vendedor: filtra no banco ao invés de baixar a base inteira!
  Future<List<Sale>> readSalesForSeller(String sellerName, {bool forceRefresh = false}) async {
    final key = sellerName.trim().toLowerCase();
    if (!forceRefresh && _cachedSellerSales.containsKey(key)) {
      return _cachedSellerSales[key]!;
    }

    try {
      final response = await _client
          .from('sales')
          .select()
          .ilike('sellername', sellerName.trim())
          .order('saledate', ascending: false);
      final list = response.map<Sale>((json) => Sale.fromMap(json)).toList();
      _cachedSellerSales[key] = list;
      return list;
    } catch (e) {
      debugPrint('Erro ao buscar vendas do vendedor: $e');
      return [];
    }
  }

  Future<int> deleteSale(int id) async {
    await _client.from('sales').delete().eq('id', id);
    clearSalesCache();
    return 1;
  }

  Future close() async {
    // No-op for Supabase
  }

  // --- SEED DATA ---
  Future<void> seedData() async {
    // No-op - we don't seed manually since Supabase has real data
  }

  // --- REFRIGERATOR STOCK CRUD ---
  Future<List<RefrigeratorItem>> readRefrigeratorStock({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStock != null) {
      return _cachedStock!;
    }
    if (_inFlightStock != null) {
      return _inFlightStock!;
    }

    _inFlightStock = _fetchRefrigeratorStock();
    try {
      final res = await _inFlightStock!;
      _cachedStock = res;
      return res;
    } finally {
      _inFlightStock = null;
    }
  }

  Future<List<RefrigeratorItem>> _fetchRefrigeratorStock() async {
    final response = await _client.from('refrigerator_stock').select().order('name', ascending: true);
    return response.map<RefrigeratorItem>((json) => RefrigeratorItem.fromMap(json)).toList();
  }

  Future<RefrigeratorItem> createRefrigeratorItem(RefrigeratorItem item) async {
    var data = item.toMap();
    data.remove('id');
    data.remove('last_updated');
    final response = await _client.from('refrigerator_stock').insert(data).select().single();
    clearStockCache();
    return RefrigeratorItem.fromMap(response);
  }

  Future<int> updateRefrigeratorItem(RefrigeratorItem item) async {
    var data = item.toMap();
    data.remove('id');
    data.remove('last_updated');
    await _client.from('refrigerator_stock').update(data).eq('id', item.id!);
    clearStockCache();
    return 1;
  }

  Future<int> deleteRefrigeratorItem(int id) async {
    await _client.from('refrigerator_stock').delete().eq('id', id);
    clearStockCache();
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
      debugPrint('Erro ao deduzir estoque: $e');
    }
  }

  // --- PROFILES & ROLES ---
  Profile? _cachedProfile;

  Future<Profile?> getProfile(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null && _cachedProfile!.id == uid) {
      return _cachedProfile;
    }
    try {
      final response = await _client.from('profiles').select().eq('id', uid).maybeSingle();
      if (response != null) {
        final prof = Profile.fromMap(response);
        _cachedProfile = prof;
        return prof;
      }
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
    }
    return _cachedProfile;
  }

  Future<void> createProfile(Profile profile) async {
    try {
      await _client.from('profiles').insert(profile.toMap());
    } catch (e) {
      debugPrint('Erro ao criar perfil: $e');
    }
  }

  Future<List<Profile>> getSellers() async {
    try {
      final response = await _client.rpc('get_sellers_with_emails');
      return (response as List).map<Profile>((json) => Profile.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Erro ao obter vendedores por RPC, tentando fallback: $e');
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
      clearSalesCache();
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
      debugPrint('Erro ao adicionar estoque consignado do vendedor: $e');
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
      debugPrint('Erro ao deduzir estoque consignado do vendedor: $e');
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
      debugPrint('Erro ao entregar pedido: $e');
    }
  }
}
