class RefrigeratorItem {
  int? id;
  int? productId;
  int? recipeId;
  String name;
  double quantity;
  String unit;
  String type; // 'product' (bolo pronto) ou 'recipe' (recheio/base)
  DateTime? lastUpdated;

  RefrigeratorItem({
    this.id,
    this.productId,
    this.recipeId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.type,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'type': type,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }

  factory RefrigeratorItem.fromMap(Map<String, dynamic> map) {
    return RefrigeratorItem(
      id: map['id'],
      productId: map['product_id'] ?? map['productId'],
      recipeId: map['recipe_id'] ?? map['recipeId'],
      name: map['name'] ?? '',
      quantity: ((map['quantity'] ?? 0.0) as num).toDouble(),
      unit: map['unit'] ?? 'unidade',
      type: map['type'] ?? 'product',
      lastUpdated: map['last_updated'] != null || map['lastUpdated'] != null
          ? DateTime.parse(map['last_updated'] ?? map['lastUpdated'])
          : null,
    );
  }
}
