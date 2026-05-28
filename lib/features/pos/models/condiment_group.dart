import '../../../core/utils/json_parse.dart';
import 'condiment_option.dart';

enum CondimentGroupType { singleSelect, multiSelect }

CondimentGroupType _parseType(String? raw) {
  switch (raw) {
    case 'multi_select':
      return CondimentGroupType.multiSelect;
    case 'single_select':
    default:
      return CondimentGroupType.singleSelect;
  }
}

class CondimentGroup {
  const CondimentGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.options,
  });

  final int id;
  final String name;
  final CondimentGroupType type;
  final bool isRequired;
  final List<CondimentOption> options;

  bool get isMulti => type == CondimentGroupType.multiSelect;

  factory CondimentGroup.fromJson(Map<String, dynamic> json) => CondimentGroup(
        id: parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        type: _parseType(json['type']?.toString()),
        isRequired: parseBool(json['is_required']),
        options: (json['options'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CondimentOption.fromJson)
            .toList(),
      );
}
