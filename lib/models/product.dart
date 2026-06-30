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

  List<ProductIngredient> ingredients;

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
    this.ingredients = const [],
  });

  double get totalCost {
    double sum = 0;
    for (var i in ingredients) {
      sum += i.cost;
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

class ProductIngredient {
  int? id;
  int productId;
  int ingredientId;
  String ingredientName;
  String ingredientUnit;
  double quantityUsed;
  double cost;

  ProductIngredient({
    this.id,
    required this.productId,
    required this.ingredientId,
    this.ingredientName = '',
    this.ingredientUnit = '',
    required this.quantityUsed,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productid': productId,
      'ingredientid': ingredientId,
      'quantityused': quantityUsed,
      'cost': cost,
    };
  }

  factory ProductIngredient.fromMap(Map<String, dynamic> map) {
    return ProductIngredient(
      id: map['id'],
      productId: map['productid'] ?? map['productId'],
      ingredientId: map['ingredientid'] ?? map['ingredientId'],
      quantityUsed: (map['quantityused'] ?? map['quantityUsed'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
    );
  }
}
