import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/invoice.dart';

/// Saves and loads invoices.
class InvoiceRepository {
  InvoiceRepository(this._db);

  final Database _db;

  /// 1 -> "INV-00001"
  static String formatInvoiceNo(int id) =>
      'INV-${id.toString().padLeft(5, '0')}';

  /// Saves [invoice] with all its items and returns it with its
  /// new id and invoice number.
  Future<Invoice> save(Invoice invoice) async {
    if (invoice.items.isEmpty) {
      throw ArgumentError('Cannot save an invoice with no items.');
    }

    return _db.transaction((txn) async {
      // Insert first to get the id, then set the number from it.
      final id = await txn.insert('invoices', {
        'invoice_no': 'pending-${DateTime.now().microsecondsSinceEpoch}',
        'created_at': invoice.createdAt.toIso8601String(),
        'customer_name': invoice.customerName,
        'customer_phone': invoice.customerPhone,
        'subtotal': invoice.subtotal,
        'total': invoice.total,
      });
      final invoiceNo = formatInvoiceNo(id);
      await txn.update(
        'invoices',
        {'invoice_no': invoiceNo},
        where: 'id = ?',
        whereArgs: [id],
      );

      for (final item in invoice.items) {
        await txn.insert('invoice_items', item.toMap(id));
      }

      return Invoice(
        id: id,
        invoiceNo: invoiceNo,
        createdAt: invoice.createdAt,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        items: invoice.items,
      );
    });
  }

  /// Newest first. [search] matches invoice number, customer name or phone.
  Future<List<InvoiceSummary>> list({String search = ''}) async {
    final pattern = '%${search.trim()}%';
    final rows = await _db.rawQuery('''
      SELECT i.*,
        (SELECT COALESCE(SUM(quantity), 0) FROM invoice_items
          WHERE invoice_id = i.id) AS item_count
      FROM invoices i
      WHERE i.invoice_no LIKE ?
         OR IFNULL(i.customer_name, '') LIKE ?
         OR IFNULL(i.customer_phone, '') LIKE ?
      ORDER BY i.id DESC
    ''', [pattern, pattern, pattern]);
    return rows.map(InvoiceSummary.fromMap).toList();
  }

  Future<Invoice?> getById(int id) async {
    final rows =
        await _db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final itemRows = await _db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'id',
    );
    return Invoice.fromMap(
      rows.first,
      itemRows.map(InvoiceItem.fromMap).toList(),
    );
  }
}
