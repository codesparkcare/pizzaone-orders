class UserModel {
  final int id;
  final String username;
  final String role; // super_admin, admin, staff
  final int? shopId;
  final String shopName;
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.shopId,
    required this.shopName,
    this.token,
  });

  bool get isSuperAdmin => role == 'super_admin' || role == 'admin';
  bool get isStaff => role == 'staff';

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? 'staff',
      shopId: json['shop_id'] != null ? int.tryParse(json['shop_id'].toString()) : null,
      shopName: json['shop_name'] ?? 'Pizza One',
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'shop_id': shopId,
      'shop_name': shopName,
      'token': token,
    };
  }
}
