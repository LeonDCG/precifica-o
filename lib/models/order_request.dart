class OrderRequest {
  final int? id;
  final String sellerId;
  final int productId;
  final double quantity;
  final DateTime requestedDate;
  final String status; // 'pending', 'approved', 'rejected', 'delivered'
  final DateTime? createdAt;
  
  // Extra fields populated by join
  final String? productName;
  final String? sellerName;

  OrderRequest({
    this.id,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.requestedDate,
    required this.status,
    this.createdAt,
    this.productName,
    this.sellerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'product_id': productId,
      'quantity': quantity,
      'requested_date': requestedDate.toIso8601String(),
      'status': status,
    };
  }

  factory OrderRequest.fromMap(Map<String, dynamic> map) {
    return OrderRequest(
      id: map['id'],
      sellerId: map['seller_id'] ?? map['sellerId'] ?? '',
      productId: map['product_id'] ?? map['productId'] ?? 0,
      quantity: ((map['quantity'] ?? 0.0) as num).toDouble(),
      requestedDate: DateTime.parse(map['requested_date'] ?? map['requestedDate']),
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      productName: map['product_name'] ?? map['products']?['name'],
      sellerName: map['seller_name'] ?? map['profiles']?['name'],
    );
  }
}
