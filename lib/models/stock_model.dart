class StockModel {
  final String productId;
  final String productName;
  final String category;
  final String unit;
  final double pricePerUnit;
  final bool isAvailable;
  final double currentStock;

  StockModel({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unit,
    required this.pricePerUnit,
    required this.isAvailable,
    required this.currentStock,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      // Backend may return 'id' or 'productId' or 'id' as int
      productId: (json['productId'] ?? json['id'] ?? '').toString(),
      // Backend may return 'name' or 'productName'
      productName: json['productName'] ?? json['name'] ?? 'Unknown Product',
      category: json['category'] ?? 'other',
      unit: json['unit'] ?? 'kg',
      pricePerUnit: double.tryParse((json['pricePerUnit'] ?? json['price'] ?? '0').toString()) ?? 0.0,
      isAvailable: json['isAvailable'] ?? true,
      currentStock: double.tryParse((json['currentStock'] ?? json['stock'] ?? '0').toString()) ?? 0.0,
    );
  }

  String get emoji {
    switch (category.toLowerCase()) {
      case 'chicken': return '🍗';
      case 'mutton': return '🐐';
      case 'egg': return '🥚';
      case 'fish': return '🐟';
      default: return '📦';
    }
  }

  bool get isLowStock => currentStock > 0 && currentStock <= 5;
  bool get isOutOfStock => currentStock <= 0;
}
