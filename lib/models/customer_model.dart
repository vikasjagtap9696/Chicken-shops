class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final int totalPurchases;
  final double totalSpent;
  final double advanceBalance;
  final DateTime createdAt;
  final DateTime? lastPurchaseDate;
  final bool isRegular;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0,
    this.totalSpent = 0.0,
    this.advanceBalance = 0.0,
    required this.createdAt,
    this.lastPurchaseDate,
    this.isRegular = false,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      // integer ID ला string मध्ये बदलले आहे
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      totalPurchases: json['totalPurchases'] != null ? int.tryParse(json['totalPurchases'].toString()) ?? 0 : 0,
      totalSpent: json['totalSpent'] != null ? double.tryParse(json['totalSpent'].toString()) ?? 0.0 : 0.0,
      advanceBalance: json['creditBalance'] != null ? double.tryParse(json['creditBalance'].toString()) ?? 0.0 : 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastPurchaseDate: json['lastPurchaseDate'] != null ? DateTime.parse(json['lastPurchaseDate']) : null,
      isRegular: json['isRegular'] ?? false,
    );
  }
}
