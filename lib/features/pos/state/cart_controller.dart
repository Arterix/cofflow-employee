import 'package:flutter/foundation.dart';

import '../models/condiment_option.dart';
import '../models/menu.dart';
import '../models/order_item_draft.dart';

/// Single shared cart for the POS flow.
/// Lifetime = while the kasir builds an order. Cleared after payment success.
class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  final List<OrderItemDraft> _items = [];

  List<OrderItemDraft> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  double get total => _items.fold(0, (s, i) => s + i.subtotal);

  /// Adds an item. If a line with the same menu, same condiments, and same
  /// notes already exists, bumps its quantity instead of appending a new row.
  /// Different condiment sets of the same menu still coexist as separate rows.
  void addItem(
    Menu menu, {
    int quantity = 1,
    List<CondimentOption>? selectedCondiments,
    String? notes,
  }) {
    final selectedIds = (selectedCondiments ?? const <CondimentOption>[])
        .map((c) => c.id)
        .toSet();
    final normalizedNotes = (notes != null && notes.isEmpty) ? null : notes;

    final existingIndex = _items.indexWhere((line) {
      if (line.menu.id != menu.id) return false;
      if (line.notes != normalizedNotes) return false;
      final lineIds = line.selectedCondiments.map((c) => c.id).toSet();
      if (lineIds.length != selectedIds.length) return false;
      return lineIds.containsAll(selectedIds);
    });

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(OrderItemDraft(
        menu: menu,
        quantity: quantity,
        selectedCondiments: selectedCondiments,
        notes: normalizedNotes,
      ));
    }
    notifyListeners();
  }

  void incrementAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity += 1;
    notifyListeners();
  }

  void decrementAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final next = _items[index].quantity - 1;
    if (next <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = next;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
