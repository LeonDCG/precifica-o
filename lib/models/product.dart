class Product {
  int? id;
  String name;
  double suggestedPrice;
  double sellPrice;
  double profitMarginPercent;
  
  String imagePath; // Caminho da imagem local ou asset
  bool isFeatured; // Se é destaque
  String category; // Categoria do Produto
  String unit; // Unidade de venda (fatia, unidade, caixa, etc)
  double yieldAmount; // Rendimento do produto (ex: 10 fatias)

  List<ProductRecipe> recipes;
  List<ProductExpense> extraExpenses;

  Product({
    this.id,
    required this.name,
    this.suggestedPrice = 0,
    this.sellPrice = 0,
    this.profitMarginPercent = 30.0,
    this.imagePath = '',
    this.isFeatured = false,
    this.category = 'Geral',
    this.unit = 'unidade',
    this.yieldAmount = 1.0,
    this.recipes = const [],
    this.extraExpenses = const [],
  });

  double get totalCost {
    double sum = 0;
    for (var r in recipes) {
      sum += r.cost;
    }
    for (var e in extraExpenses) {
      sum += e.cost;
    }
    // Se receitas não estiverem carregadas (consulta leve), deduz do suggestedPrice salvo
    if (sum == 0 && suggestedPrice > 0 && profitMarginPercent > -100) {
      return suggestedPrice / (1 + (profitMarginPercent / 100));
    }
    return sum;
  }

  void calculateSuggestedPrice() {
    suggestedPrice = totalCost * (1 + (profitMarginPercent / 100));
  }

  double get actualProfit => sellPrice - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suggestedPrice': suggestedPrice,
      'sellPrice': sellPrice,
      'profitMarginPercent': profitMarginPercent,
      'imagePath': imagePath,
      'isFeatured': isFeatured ? 1 : 0,
      'category': category,
      'unit': unit,
      'yieldAmount': yieldAmount,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      suggestedPrice: (map['suggestedPrice'] as num).toDouble(),
      sellPrice: (map['sellPrice'] as num).toDouble(),
      profitMarginPercent: (map['profitMarginPercent'] as num).toDouble(),
      imagePath: map['imagePath'] ?? '',
      isFeatured: (map['isFeatured'] ?? 0) == 1,
      category: map['category'] ?? 'Geral',
      unit: map['unit'] ?? 'unidade',
      yieldAmount: (map['yieldAmount'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ProductRecipe {
  int? id;
  int productId;
  int recipeId;
  String recipeName;
  double quantityUsed; // ex: usa 2 "rendimentos" daquela receita
  double cost;

  ProductRecipe({
    this.id,
    required this.productId,
    required this.recipeId,
    this.recipeName = '',
    required this.quantityUsed,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productid': productId,
      'recipeid': recipeId,
      'quantityused': quantityUsed,
      'cost': cost,
    };
  }

  factory ProductRecipe.fromMap(Map<String, dynamic> map) {
    return ProductRecipe(
      id: map['id'],
      productId: map['productid'] ?? map['productId'],
      recipeId: map['recipeid'] ?? map['recipeId'],
      quantityUsed: (map['quantityused'] ?? map['quantityUsed'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
    );
  }
}

class ProductExpense {
  int? id;
  int productId;
  String name;
  double cost;

  ProductExpense({
    this.id,
    required this.productId,
    required this.name,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productid': productId,
      'name': name,
      'cost': cost,
    };
  }

  factory ProductExpense.fromMap(Map<String, dynamic> map) {
    return ProductExpense(
      id: map['id'],
      productId: map['productid'] ?? map['productId'],
      name: map['name'],
      cost: (map['cost'] as num).toDouble(),
    );
  }
}
