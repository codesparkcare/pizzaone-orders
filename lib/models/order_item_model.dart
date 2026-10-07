class OrderItemModel {
  final int productId;
  final String name;
  final String size;
  final int quantity;
  final double price;
  final double itemTotal;
  final List<String> addons;
  final String instructions;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.size,
    required this.quantity,
    required this.price,
    required this.itemTotal,
    required this.addons,
    this.instructions = '',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedAddons = [];
    if (json['addons'] != null) {
      if (json['addons'] is List) {
        parsedAddons = (json['addons'] as List)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (json['addons'] is String && json['addons'].toString().isNotEmpty) {
        parsedAddons = [json['addons'].toString()];
      }
    }

    return OrderItemModel(
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      name: json['name'] ?? json['product_name'] ?? 'Produit',
      size: json['size'] ?? json['size_name'] ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 1,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      itemTotal: json['item_total'] is num
          ? (json['item_total'] as num).toDouble()
          : double.tryParse(json['item_total'].toString()) ?? 0.0,
      addons: parsedAddons,
      instructions: json['instructions'] ?? json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'size': size,
      'quantity': quantity,
      'price': price,
      'item_total': itemTotal,
      'addons': addons,
      'instructions': instructions,
    };
  }
}
