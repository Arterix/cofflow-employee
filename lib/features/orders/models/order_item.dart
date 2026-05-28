import '../../../core/utils/json_parse.dart';

class OrderItemCondiment {
  const OrderItemCondiment({
    required this.condimentOptionId,
    required this.optionName,
    required this.additionalPrice,
  });

  final int condimentOptionId;
  final String optionName;
  final double additionalPrice;

  factory OrderItemCondiment.fromJson(Map<String, dynamic> json) =>
      OrderItemCondiment(
        condimentOptionId: parseInt(json['condiment_option_id']),
        optionName: json['option_name']?.toString() ?? '',
        additionalPrice: parseDouble(json['additional_price']),
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.menuId,
    required this.menuName,
    this.menuImageUrl,
    required this.quantity,
    required this.unitPrice,
    this.appliedDiscount = 0,
    this.notes,
    required this.condiments,
  });

  final int id;
  final int menuId;
  final String menuName;
  final String? menuImageUrl;
  final int quantity;
  final double unitPrice;
  final double appliedDiscount;
  final String? notes;
  final List<OrderItemCondiment> condiments;

  double get lineTotal => unitPrice * quantity - appliedDiscount;
  String get condimentSummary => condiments.map((c) => c.optionName).join(', ');

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final menu = json['menu'] as Map<String, dynamic>?;
    return OrderItem(
      id: parseInt(json['id']),
      menuId: parseInt(json['menu_id']),
      menuName: menu?['name']?.toString() ?? 'Menu',
      menuImageUrl: menu?['image_url']?.toString(),
      quantity: parseInt(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      appliedDiscount: parseDouble(json['applied_discount']),
      notes: json['notes']?.toString(),
      condiments: (json['condiments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemCondiment.fromJson)
          .toList(),
    );
  }
}
