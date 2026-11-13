import 'package:flutter/foundation.dart';

import '../models/invoice.dart';
import '../models/perfume.dart';

/// Holds the invoice being built on screen and keeps totals up to date.
class InvoiceController extends ChangeNotifier {
  final List<InvoiceItem> _items = [];

  List<InvoiceItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  int get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  /// No tax or discount for now, so total equals subtotal.
  int get total => subtotal;

  /// Adds a perfume. If the same perfume and size is already on the
  /// invoice, its quantity is increased instead of adding a new line.
  void addItem(Perfume perfume, PerfumeSize size, {int quantity = 1}) {
    _add(InvoiceItem(
      perfumeId: perfume.id,
      perfumeName: perfume.name,
      perfumeSubtitle: perfume.subtitle,
      sizeLabel: size.label,
      unitPrice: perfume.priceFor(size),
      quantity: quantity,
    ));
  }

  /// An item typed in by hand (not from the price list).
  void addManualItem({
    required String name,
    String sizeLabel = '',
    required int unitPrice,
    int quantity = 1,
  }) {
    _add(InvoiceItem(
      perfumeName: name.trim(),
      sizeLabel: sizeLabel.trim(),
      unitPrice: unitPrice,
      quantity: quantity,
    ));
  }

  void _add(InvoiceItem newItem) {
    if (newItem.quantity < 1) {
      throw ArgumentError.value(newItem.quantity, 'quantity', 'Must be >= 1');
    }

    final index = _items.indexWhere((item) =>
        item.perfumeName == newItem.perfumeName &&
        item.perfumeSubtitle == newItem.perfumeSubtitle &&
        item.sizeLabel == newItem.sizeLabel &&
        item.unitPrice == newItem.unitPrice);

    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: _limit(existing.quantity + newItem.quantity),
      );
    } else {
      _items.add(newItem.copyWith(quantity: _limit(newItem.quantity)));
    }
    notifyListeners();
  }

  void setQuantity(int index, int quantity) {
    _items[index] = _items[index].copyWith(quantity: _limit(quantity));
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Creates the [Invoice] to save. Blank customer fields become null.
  Invoice buildInvoice({
    String? customerName,
    String? customerPhone,
    DateTime? createdAt,
  }) =>
      Invoice(
        createdAt: createdAt ?? DateTime.now(),
        customerName: _clean(customerName),
        customerPhone: _clean(customerPhone),
        items: List.of(_items),
      );

  static int _limit(int quantity) => quantity.clamp(1, maxQuantity);

  static String? _clean(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
