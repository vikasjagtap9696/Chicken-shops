class SaleModel {
  final String id;
  final String billNumber; 
  final String? customerName;
  final String? customerPhone;
  final List<SaleItem> items;
  final double subtotal; 
  final double discount;
  final double grandTotal; 
  final double amountPaid; // Added to track balance
  final double profit;
  final String paymentMode; 
  final String status;
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.billNumber,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.amountPaid,
    required this.profit,
    required this.paymentMode,
    required this.status,
    required this.createdAt,
  });

  double get balanceAmount => grandTotal - amountPaid;
  bool get hasBalance => balanceAmount > 0.1; // Using 0.1 to avoid float precision issues

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? '',
      billNumber: json['orderNumber'] ?? '', 
      customerName: json['customer'] != null ? json['customer']['name'] : 'Walk-in',
      customerPhone: json['customer'] != null ? json['customer']['phone'] : '',
      items: (json['items'] as List? ?? [])
          .map((item) => SaleItem.fromJson(item))
          .toList(),
      subtotal: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['netAmount']?.toString() ?? '0') ?? 0.0,
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? json['netAmount']?.toString() ?? '0') ?? 0.0,
      profit: double.tryParse(json['profit']?.toString() ?? '0') ?? 0.0,
      paymentMode: json['paymentMethod'] ?? 'cash',
      status: json['status'] ?? 'completed',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final double quantity;
  final double price; 
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['product'] != null ? json['product']['name'] : 'Product',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['pricePerUnit']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['totalPrice']?.toString() ?? '0') ?? 0.0,
    );
  }
}
