import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/product.dart';
import '../models/recipe.dart';

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
    final response = await _client.from('recipes').select().order('name', ascending: true);
    List<Recipe> recipes = response.map<Recipe>((json) => Recipe.fromMap(json)).toList();

    final allIngredients = await readAllIngredients();

    for (var recipe in recipes) {
      final riMaps = await _client.from('recipe_ingredients').select().eq('recipeid', recipe.id!);
      recipe.ingredients = riMaps.map<RecipeIngredient>((json) {
        final ri = RecipeIngredient.fromMap(json);
        try {
          final ing = allIngredients.firstWhere((i) => i.id == ri.ingredientId);
          ri.ingredientName = ing.name;
          ri.ingredientUnit = ing.unit;
        } catch (_) {}
        return ri;
      }).toList();
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
    final productsResponse = await _client.from('products').select().order('name', ascending: true);
    List<Product> products = productsResponse.map<Product>((json) => Product.fromMap(json)).toList();
    
    final allRecipes = await readAllRecipes();

    for (var product in products) {
      final prMaps = await _client.from('product_recipes').select().eq('productid', product.id!);
      product.recipes = prMaps.map<ProductRecipe>((json) {
        final pr = ProductRecipe.fromMap(json);
        try {
          final rec = allRecipes.firstWhere((r) => r.id == pr.recipeId);
          pr.recipeName = rec.name;
        } catch (_) {}
        return pr;
      }).toList();
      
      final peMaps = await _client.from('product_expenses').select().eq('productid', product.id!);
      product.extraExpenses = peMaps.map<ProductExpense>((json) => ProductExpense.fromMap(json)).toList();
    }
    return products;
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

  Future close() async {
    // No-op for Supabase
  }

  // --- SEED DATA ---
  Future<void> seedData() async {
    // No-op - we don't seed manually since Supabase has real data
  }
}
