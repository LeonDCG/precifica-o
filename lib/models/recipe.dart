class Recipe {
  int? id;
  String name;
  double yieldAmount;
  String yieldUnit;
  double additionalCostPercent;
  String instructions; // Modo de preparo
  int prepTimeMinutes;
  double laborCost;
  
  List<RecipeIngredient> ingredients;

  Recipe({
    this.id,
    required this.name,
    this.yieldAmount = 1,
    this.yieldUnit = 'unidade',
    this.additionalCostPercent = 10.0,
    this.instructions = '',
    this.prepTimeMinutes = 0,
    this.laborCost = 0.0,
    this.ingredients = const [],
  });

  double get totalCost {
    double sum = laborCost;
    for (var i in ingredients) {
      sum += i.cost;
    }
    return sum * (1 + (additionalCostPercent / 100));
  }

  double get costPerYield => totalCost / yieldAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'yieldamount': yieldAmount,
      'yieldunit': yieldUnit,
      'additionalcostpercent': additionalCostPercent,
      'instructions': instructions,
      'preptimeminutes': prepTimeMinutes,
      'laborcost': laborCost,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      yieldAmount: (map['yieldamount'] ?? map['yieldAmount'] as num).toDouble(),
      yieldUnit: map['yieldunit'] ?? map['yieldUnit'] ?? 'unidade',
      additionalCostPercent: (map['additionalcostpercent'] ?? map['additionalCostPercent'] as num).toDouble(),
      instructions: map['instructions'] ?? '',
      prepTimeMinutes: map['preptimeminutes'] ?? map['prepTimeMinutes'] ?? 0,
      laborCost: (map['laborcost'] ?? map['laborCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecipeIngredient {
  int? id;
  int recipeId;
  int ingredientId;
  String ingredientName;
  String ingredientUnit;
  String ingredientType; // 'ingredient', 'packaging', 'operational'
  double quantityUsed;
  double cost;

  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.ingredientId,
    this.ingredientName = '',
    this.ingredientUnit = '',
    this.ingredientType = 'ingredient',
    required this.quantityUsed,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeid': recipeId,
      'ingredientid': ingredientId,
      'quantityused': quantityUsed,
      'cost': cost,
      'ingredienttype': ingredientType,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipeid'] ?? map['recipeId'],
      ingredientId: map['ingredientid'] ?? map['ingredientId'],
      quantityUsed: (map['quantityused'] ?? map['quantityUsed'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      ingredientType: map['ingredienttype'] ?? map['ingredientType'] ?? 'ingredient',
    );
  }
}
