import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
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

  // --- RECIPES CRUD ---
  Future<Recipe> createRecipe(Recipe recipe) async {
    var recipeData = recipe.toMap();
    recipeData.remove('id');
    final response = await _client.from('recipes').insert(recipeData).select().single();
    final newRecipeId = response['id'] as int;
    recipe.id = newRecipeId;
    
    for (var ri in recipe.ingredients) {
      ri.recipeId = newRecipeId;
      var riData = ri.toMap();
      riData.remove('id');
      await _client.from('recipe_ingredients').insert(riData);
    }
    return recipe;
  }

  Future<List<Recipe>> readAllRecipes() async {
    final recipesResponse = await _client.from('recipes').select().order('name', ascending: true);
    List<Recipe> recipes = recipesResponse.map<Recipe>((json) => Recipe.fromMap(json)).toList();
    
    // Buscar ingredientes para todas as receitas de uma vez ou loop
    // Para simplificar, loop:
    for (var recipe in recipes) {
      final riMaps = await _client.from('recipe_ingredients').select().eq('recipeId', recipe.id!);
      recipe.ingredients = riMaps.map<RecipeIngredient>((json) => RecipeIngredient.fromMap(json)).toList();
    }
    return recipes;
  }

  Future<int> deleteRecipe(int id) async {
    await _client.from('recipe_ingredients').delete().eq('recipeId', id);
    await _client.from('recipes').delete().eq('id', id);
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
    final productsResponse = await _client.from('products').select().order('name', ascending: true);
    List<Product> products = productsResponse.map<Product>((json) => Product.fromMap(json)).toList();
    
    for (var product in products) {
      final prMaps = await _client.from('product_recipes').select().eq('productId', product.id!);
      product.recipes = prMaps.map<ProductRecipe>((json) => ProductRecipe.fromMap(json)).toList();
      
      final peMaps = await _client.from('product_expenses').select().eq('productId', product.id!);
      product.extraExpenses = peMaps.map<ProductExpense>((json) => ProductExpense.fromMap(json)).toList();
    }
    return products;
  }

  Future<int> deleteProduct(int id) async {
    await _client.from('product_recipes').delete().eq('productId', id);
    await _client.from('product_expenses').delete().eq('productId', id);
    await _client.from('products').delete().eq('id', id);
    return 1;
  }

  // --- SALES (Estoque Inteligente) ---
  Future<void> registerProductSale(Product product, int quantitySold) async {
    final allRecipes = await readAllRecipes();
    final allIngredients = await readAllIngredients();

    for (var pr in product.recipes) {
      final recipe = allRecipes.firstWhere((r) => r.id == pr.recipeId);
      
      // Proporção consumida
      final recipeProportionUsed = (pr.quantityUsed / recipe.yieldAmount) * quantitySold;
      
      for (var ri in recipe.ingredients) {
        final amountConsumed = ri.quantityUsed * recipeProportionUsed;
        
        final ingredient = allIngredients.firstWhere((i) => i.id == ri.ingredientId);
        
        ingredient.stock -= amountConsumed;
        await updateIngredient(ingredient);
      }
    }
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
    final i1 = await createIngredient(Ingredient(name: 'Farinha de Trigo', unit: 'kg', price: 5.0, quantity: 1, type: 'ingredient', category: 'SECOS', stock: 5, minStock: 2));
    final i2 = await createIngredient(Ingredient(name: 'Açúcar Refinado', unit: 'kg', price: 4.5, quantity: 1, type: 'ingredient', category: 'SECOS', stock: 10, minStock: 3));
    final i3 = await createIngredient(Ingredient(name: 'Leite Condensado', unit: 'unidade', price: 6.0, quantity: 1, type: 'ingredient', category: 'LATICÍNIOS', stock: 20, minStock: 5));
    final i4 = await createIngredient(Ingredient(name: 'Ovos', unit: 'unidade', price: 18.0, quantity: 30, type: 'ingredient', category: 'LATICÍNIOS', stock: 60, minStock: 12)); 
    final i5 = await createIngredient(Ingredient(name: 'Chocolate em Pó 50%', unit: 'kg', price: 35.0, quantity: 1, type: 'ingredient', category: 'SECOS', stock: 2, minStock: 1));

    // Embalagens
    final e1 = await createIngredient(Ingredient(name: 'Caixa para Bolo 20cm', unit: 'unidade', price: 4.5, quantity: 1, type: 'packaging', category: 'EMBALAGENS', stock: 50, minStock: 10));
    final e2 = await createIngredient(Ingredient(name: 'Prato MDF 25cm', unit: 'unidade', price: 3.0, quantity: 1, type: 'packaging', category: 'EMBALAGENS', stock: 20, minStock: 5));

    // Operacional
    final o1 = await createIngredient(Ingredient(name: 'Energia Elétrica (Fornada)', unit: 'unidade', price: 2.0, quantity: 1, type: 'operational', category: 'CUSTOS FIXOS', stock: 9999, minStock: 0));

    // 2. Receita (Massa de Chocolate)
    final r1 = await createRecipe(Recipe(
      name: 'Massa de Chocolate',
      yieldAmount: 1,
      yieldUnit: 'unidade',
      instructions: 'Bata os ovos com açúcar. Adicione os líquidos. Misture os secos. Asse a 180C por 40 min.',
      prepTimeMinutes: 45,
      laborCost: (45 / 60.0) * 12.50,
      ingredients: [
        RecipeIngredient(recipeId: 0, ingredientId: i1.id!, ingredientName: i1.name, ingredientUnit: i1.unit, ingredientType: i1.type, quantityUsed: 0.3, cost: i1.unitPrice * 0.3),
        RecipeIngredient(recipeId: 0, ingredientId: i2.id!, ingredientName: i2.name, ingredientUnit: i2.unit, ingredientType: i2.type, quantityUsed: 0.2, cost: i2.unitPrice * 0.2),
        RecipeIngredient(recipeId: 0, ingredientId: i4.id!, ingredientName: i4.name, ingredientUnit: i4.unit, ingredientType: i4.type, quantityUsed: 4, cost: i4.unitPrice * 4),
        RecipeIngredient(recipeId: 0, ingredientId: i5.id!, ingredientName: i5.name, ingredientUnit: i5.unit, ingredientType: i5.type, quantityUsed: 0.1, cost: i5.unitPrice * 0.1),
        RecipeIngredient(recipeId: 0, ingredientId: e1.id!, ingredientName: e1.name, ingredientUnit: e1.unit, ingredientType: e1.type, quantityUsed: 1, cost: e1.unitPrice * 1),
        RecipeIngredient(recipeId: 0, ingredientId: o1.id!, ingredientName: o1.name, ingredientUnit: o1.unit, ingredientType: o1.type, quantityUsed: 1, cost: o1.unitPrice * 1),
      ],
    ));

    // 3. Receita (Recheio de Brigadeiro)
    final r2 = await createRecipe(Recipe(
      name: 'Recheio de Brigadeiro',
      yieldAmount: 1,
      yieldUnit: 'unidade',
      instructions: 'Misture tudo na panela de fundo grosso e cozinhe até ponto de recheio firme.',
      prepTimeMinutes: 30,
      laborCost: (30 / 60.0) * 12.50,
      ingredients: [
        RecipeIngredient(recipeId: 0, ingredientId: i3.id!, ingredientName: i3.name, ingredientUnit: i3.unit, ingredientType: i3.type, quantityUsed: 2, cost: i3.unitPrice * 2),
        RecipeIngredient(recipeId: 0, ingredientId: i5.id!, ingredientName: i5.name, ingredientUnit: i5.unit, ingredientType: i5.type, quantityUsed: 0.05, cost: i5.unitPrice * 0.05),
      ]
    ));

    // 4. Produto Final
    await createProduct(Product(
      name: 'Bolo de Brigadeiro Completo',
      suggestedPrice: 120.0,
      sellPrice: 120.0,
      profitMarginPercent: 0,
      imagePath: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      isFeatured: true,
      category: 'Bolos Inteiros',
      unit: 'unidade',
      yieldAmount: 1.0,
      recipes: [
        ProductRecipe(productId: 0, recipeId: r1.id!, quantityUsed: 1, cost: r1.totalCost),
        ProductRecipe(productId: 0, recipeId: r2.id!, quantityUsed: 1, cost: r2.totalCost),
      ],
      extraExpenses: [
        ProductExpense(productId: 0, name: 'Prato MDF', cost: e2.unitPrice),
      ],
    ));
  }
}
