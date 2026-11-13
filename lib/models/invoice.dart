import 'perfume.dart';

/// Highest quantity allowed on one invoice line.
const maxQuantity = 999;

/// One line on an invoice. Name and price are copied from the perfume
/// at the time of sale, so old invoices never change.
class InvoiceItem {
  const InvoiceItem({
    this.perfumeId,
    required this.perfumeName,
    this.perfumeSubtitle = '',
    required this.sizeLabel,
    required this.unitPrice,
    this.quantity = 1,
  });

  final int? perfumeId;
  final String perfumeName;

  /// "BY Dior" or "Oriental/Arabic".
  final String perfumeSubtitle;
  /// e.g. "30ml" or "Tola (12ml oil)". Free text for manual items.
  final String sizeLabel;
  final int unitPrice;
  final int quantity;

  int get lineTotal => unitPrice * quantity;

  InvoiceItem copyWith({int? quantity}) => InvoiceItem(
        perfumeId: perfumeId,
        perfumeName: perfumeName,
        perfumeSubtitle: perfumeSubtitle,
        sizeLabel: sizeLabel,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );

  Map<String, Object?> toMap(int invoiceId) => {
        'invoice_id': invoiceId,
        'perfume_id': perfumeId,
        'perfume_name': perfumeName,
        'perfume_subtitle': perfumeSubtitle,
        'size': sizeLabel,
        'unit_price': unitPrice,
        'quantity': quantity,
        'line_total': lineTotal,
      };

  factory InvoiceItem.fromMap(Map<String, Object?> map) => InvoiceItem(
        perfumeId: map['perfume_id'] as int?,
        perfumeName: map['perfume_name'] as String,
        perfumeSubtitle: (map['perfume_subtitle'] as String?) ?? '',
        sizeLabel: _sizeLabel(map['size'] as String),
        unitPrice: map['unit_price'] as int,
        quantity: map['quantity'] as int,
      );

  /// Invoices saved by version 1.0.0 stored the size code (e.g. "ml30").
  static String _sizeLabel(String stored) {
    for (final size in PerfumeSize.values) {
      if (size.name == stored) return size.label;
    }
    return stored;
  }
}

/// One row in the History list.
class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.invoiceNo,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    required this.itemCount,
    required this.total,
  });

  final int id;
  final String invoiceNo;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final int itemCount;
  final int total;

  factory InvoiceSummary.fromMap(Map<String, Object?> map) => InvoiceSummary(
        id: map['id'] as int,
        invoiceNo: map['invoice_no'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        customerName: map['customer_name'] as String?,
        customerPhone: map['customer_phone'] as String?,
        itemCount: map['item_count'] as int,
        total: map['total'] as int,
      );
}

class Invoice {
  const Invoice({
    this.id,
    this.invoiceNo,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    required this.items,
  });

  final int? id;

  /// e.g. "INV-00001". Given when the invoice is saved.
  final String? invoiceNo;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final List<InvoiceItem> items;

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  /// No tax or discount for now, so total equals subtotal.
  int get total => subtotal;

  factory Invoice.fromMap(Map<String, Object?> map, List<InvoiceItem> items) =>
      Invoice(
        id: map['id'] as int,
        invoiceNo: map['invoice_no'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        customerName: map['customer_name'] as String?,
        customerPhone: map['customer_phone'] as String?,
        items: items,
      );
}
