class Ingredient {
  int? id;
  String name;
  String unit; // ex: 'kg', 'g', 'L', 'ml', 'unidade'
  double price;
  double quantity; // quantidade na embalagem original
  double minStock;
  
  // Novos campos para o design premium
  String type; // 'ingredient', 'packaging', 'operational'
  String category; // ex: 'SECOS', 'ADOÇANTES'
  double stock;

  Ingredient({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    this.minStock = 0.0,
    this.type = 'ingredient',
    this.category = '',
    this.stock = 0.0,
  });

  // Calculate price per unit (e.g. price per 1 gram)
  double get unitPrice => price / quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'minStock': minStock,
      'type': type,
      'category': category,
      'stock': stock,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      minStock: (map['minStock'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'ingredient',
      category: map['category'] ?? '',
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
