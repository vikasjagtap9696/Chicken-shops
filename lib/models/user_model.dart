class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String shopName;
  final String role;
  final String? gstNumber;
  final String? fssaiNumber;
  final String? address;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.shopName,
    required this.role,
    this.gstNumber,
    this.fssaiNumber,
    this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'shopName': shopName,
      'role': role,
      'gstNumber': gstNumber,
      'fssaiNumber': fssaiNumber,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Backend kadun int yeu shakto, mhanun .toString() vaprave
      id: json['id']?.toString() ?? '', 
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      shopName: json['shopName'] ?? 'Chicken Shop',
      role: json['role'] ?? 'staff',
      gstNumber: json['gstNumber'],
      fssaiNumber: json['fssaiNumber'],
      address: json['address'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
