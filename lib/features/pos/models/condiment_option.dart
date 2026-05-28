import '../../../core/utils/json_parse.dart';

class CondimentOption {
  const CondimentOption({
    required this.id,
    required this.condimentGroupId,
    required this.name,
    required this.additionalPrice,
  });

  final int id;
  final int condimentGroupId;
  final String name;
  final double additionalPrice;

  factory CondimentOption.fromJson(Map<String, dynamic> json) =>
      CondimentOption(
        id: parseInt(json['id']),
        condimentGroupId: parseInt(json['condiment_group_id']),
        name: json['name']?.toString() ?? '',
        additionalPrice: parseDouble(json['additional_price']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CondimentOption && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
