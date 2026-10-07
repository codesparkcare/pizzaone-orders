class ShopModel {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool isActive;

  ShopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.isActive,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'is_active': isActive ? 1 : 0,
    };
  }
}
