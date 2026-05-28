import 'condiment_option.dart';
import 'menu.dart';

class OrderItemDraft {
  OrderItemDraft({
    required this.menu,
    this.quantity = 1,
    List<CondimentOption>? selectedCondiments,
    this.notes,
  }) : selectedCondiments = selectedCondiments ?? [];

  final Menu menu;
  int quantity;
  final List<CondimentOption> selectedCondiments;
  String? notes;

  double get condimentTotal =>
      selectedCondiments.fold<double>(0, (s, c) => s + c.additionalPrice);

  double get unitPrice => menu.price + condimentTotal;

  double get subtotal => unitPrice * quantity;

  String get condimentSummary =>
      selectedCondiments.map((c) => c.name).join(', ');

  Map<String, dynamic> toApiPayload() => {
        'menu_id': menu.id,
        'quantity': quantity,
        'condiment_option_ids': selectedCondiments.map((c) => c.id).toList(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
