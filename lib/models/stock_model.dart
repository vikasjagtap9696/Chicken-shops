class StockModel {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double purchasePrice; // खरेदी किंमत
  final double sellingPrice; // विक्री किंमत (Backend: pricePerUnit)
  final String? description;
  final bool isAvailable;
  final double quantity;
  final DateTime createdAt;

  StockModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.description,
    this.isAvailable = true,
    this.quantity = 0.0,
    required this.createdAt,
  });

  // नफा आणि मार्जिन कॅल्क्युलेशन
  double get profit => sellingPrice - purchasePrice;
  double get profitMargin => purchasePrice > 0 ? (profit / purchasePrice) * 100 : 0.0;

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'chicken',
      unit: json['unit'] ?? 'kg',
      // बॅकएंड कडून येणारी खरेदी किंमत (खरेदी किंमत बॅकएंडला नसेल तर ० सेट होईल)
      purchasePrice: double.tryParse(json['purchasePrice']?.toString() ?? '0') ?? 0.0,
      sellingPrice: double.tryParse(json['pricePerUnit']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      isAvailable: json['isAvailable'] ?? true,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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

  bool get isLowStock => quantity <= 5;
}
