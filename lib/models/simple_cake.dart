class SimpleCake {
  final int? id;
  final String name;
  final int quantity;
  final String category;
  final String? notes;
  final double ifoodPrice;
  final double food99Price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SimpleCake({
    this.id,
    required this.name,
    required this.quantity,
    this.category = 'Bolo Caseiro',
    this.notes,
    this.ifoodPrice = 0.0,
    this.food99Price = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      if (notes != null) 'notes': notes,
      'ifood_price': ifoodPrice,
      'food99_price': food99Price,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory SimpleCake.fromMap(Map<String, dynamic> map) {
    return SimpleCake(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      category: map['category'] ?? 'Bolo Caseiro',
      notes: map['notes'] as String?,
      ifoodPrice: (map['ifood_price'] as num?)?.toDouble() ?? 0.0,
      food99Price: (map['food99_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  SimpleCake copyWith({
    int? id,
    String? name,
    int? quantity,
    String? category,
    String? notes,
    double? ifoodPrice,
    double? food99Price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SimpleCake(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      ifoodPrice: ifoodPrice ?? this.ifoodPrice,
      food99Price: food99Price ?? this.food99Price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
