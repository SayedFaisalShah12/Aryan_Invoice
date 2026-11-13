import 'package:aura/controllers/invoice_controller.dart';
import 'package:aura/models/perfume.dart';
import 'package:flutter_test/flutter_test.dart';

Perfume _perfume(String name, List<int> prices, {String? brand}) => Perfume(
      sno: 1,
      name: name,
      brand: brand,
      category: brand == null ? 'Oriental/Arabic' : null,
      prices: {
        for (var i = 0; i < PerfumeSize.values.length; i++)
          PerfumeSize.values[i]: prices[i],
      },
    );

void main() {
  final hope = _perfume('Hope', [1150, 3500, 5750, 3200, 1600],
      brand: 'Fraderic Malle');
  final motia = _perfume('Motia', [250, 750, 1100, 400, 200]);

  test('totals update automatically', () {
    final c = InvoiceController();
    c.addItem(hope, PerfumeSize.ml30, quantity: 2); // 7,000
    c.addItem(motia, PerfumeSize.halfTola); // 200
    expect(c.items.length, 2);
    expect(c.subtotal, 7200);
    expect(c.total, 7200);

    c.setQuantity(1, 3); // Motia 3 x 200
    expect(c.total, 7600);

    c.removeAt(0);
    expect(c.total, 600);

    c.clear();
    expect(c.isEmpty, isTrue);
    expect(c.total, 0);
  });

  test('same perfume and size adds to the existing line', () {
    final c = InvoiceController();
    c.addItem(hope, PerfumeSize.ml10);
    c.addItem(hope, PerfumeSize.ml10, quantity: 2);
    c.addItem(hope, PerfumeSize.ml50);
    expect(c.items.length, 2);
    expect(c.items.first.quantity, 3);
    expect(c.total, 3 * 1150 + 5750);
  });

  test('quantity stays between 1 and 999', () {
    final c = InvoiceController();
    c.addItem(motia, PerfumeSize.ml10);
    c.setQuantity(0, 0);
    expect(c.items.first.quantity, 1);
    c.setQuantity(0, 5000);
    expect(c.items.first.quantity, 999);
  });

  test('blank customer details are saved as empty', () {
    final c = InvoiceController()..addItem(motia, PerfumeSize.ml10);
    final invoice = c.buildInvoice(customerName: '  ', customerPhone: ' 0300 ');
    expect(invoice.customerName, isNull);
    expect(invoice.customerPhone, '0300');
  });
}
