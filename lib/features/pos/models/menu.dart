import '../../../core/utils/json_parse.dart';
import 'category.dart';
import 'condiment_group.dart';

class Menu {
  const Menu({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isActive,
    this.category,
    required this.condimentGroups,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final MenuCategory? category;
  final List<CondimentGroup> condimentGroups;

  bool get hasCondiments => condimentGroups.isNotEmpty;

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        id: parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        price: parseDouble(json['price']),
        imageUrl: json['image_url']?.toString(),
        isActive: parseBool(json['is_active'], fallback: true),
        category: json['category'] is Map<String, dynamic>
            ? MenuCategory.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        condimentGroups: (json['condiment_groups'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CondimentGroup.fromJson)
            .toList(),
      );
}
