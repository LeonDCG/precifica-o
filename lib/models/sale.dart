class Sale {
  int? id;
  int? productId;
  String productName;
  double quantity;
  double totalValue;
  double totalCost;
  double totalProfit;
  String sellerType; // 'me' ou 'other'
  String sellerName;
  double commissionPercent;
  double commissionValue;
  double netProfit;
  DateTime saleDate;
  String notes;

  Sale({
    this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.sellerType,
    this.sellerName = '',
    this.commissionPercent = 0.0,
    this.commissionValue = 0.0,
    required this.netProfit,
    required this.saleDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productid': productId,
      'productname': productName,
      'quantity': quantity,
      'totalvalue': totalValue,
      'totalcost': totalCost,
      'totalprofit': totalProfit,
      'sellertype': sellerType,
      'sellername': sellerName,
      'commissionpercent': commissionPercent,
      'commissionvalue': commissionValue,
      'netprofit': netProfit,
      'saledate': saleDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['productid'] ?? map['productId'],
      productName: map['productname'] ?? map['productName'] ?? '',
      quantity: (map['quantity'] ?? map['quantity'] as num).toDouble(),
      totalValue: (map['totalvalue'] ?? map['totalValue'] as num).toDouble(),
      totalCost: (map['totalcost'] ?? map['totalCost'] as num).toDouble(),
      totalProfit: (map['totalprofit'] ?? map['totalProfit'] as num).toDouble(),
      sellerType: map['sellertype'] ?? map['sellerType'] ?? 'me',
      sellerName: map['sellername'] ?? map['sellerName'] ?? '',
      commissionPercent: (map['commissionpercent'] ?? map['commissionPercent'] as num?)?.toDouble() ?? 0.0,
      commissionValue: (map['commissionvalue'] ?? map['commissionValue'] as num?)?.toDouble() ?? 0.0,
      netProfit: (map['netprofit'] ?? map['netProfit'] as num).toDouble(),
      saleDate: DateTime.parse(map['saledate'] ?? map['saleDate']),
      notes: map['notes'] ?? '',
    );
  }
}
