import '../../../core/utils/json_parse.dart';

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.slug,
  });

  final int id;
  final String name;
  final String? slug;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString(),
      );
}
