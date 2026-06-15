class Ingredient {
  int? id;
  String name;
  String unit; // ex: 'kg', 'g', 'L', 'ml', 'unidade'
  double price; // valor pago
  double quantity; // quantidade comprada (embalagem)
  
  // Novos campos para o design premium
  String type; // 'ingredient', 'packaging', 'operational'
  String category; // ex: 'SECOS', 'ADOÇANTES'

  Ingredient({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    this.type = 'ingredient',
    this.category = '',
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
      'type': type,
      'category': category,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      type: map['type'] ?? 'ingredient',
      category: map['category'] ?? '',
    );
  }
}
