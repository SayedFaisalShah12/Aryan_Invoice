import 'dart:io';

import 'package:aura/controllers/invoice_controller.dart';
import 'package:aura/data/app_database.dart';
import 'package:aura/data/invoice_repository.dart';
import 'package:aura/data/perfume_repository.dart';
import 'package:aura/models/invoice.dart';
import 'package:aura/models/perfume.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late InvoiceRepository invoices;
  late List<Perfume> perfumes;

  setUp(() async {
    final csv = File(AppDatabase.priceListAsset).readAsStringSync();
    await AppDatabase.instance
        .open(path: inMemoryDatabasePath, loadPriceList: () async => csv);
    final db = AppDatabase.instance.db;
    perfumes = await PerfumeRepository(db).getAll();
    invoices = InvoiceRepository(db);
  });

  tearDown(() => AppDatabase.instance.close());

  test('saves an invoice and loads it back exactly', () async {
    final hope = perfumes.firstWhere((p) => p.sno == 129);
    final whiteMuskJ = perfumes.firstWhere((p) => p.sno == 261);

    final c = InvoiceController()
      ..addItem(hope, PerfumeSize.ml30, quantity: 2)
      ..addItem(whiteMuskJ, PerfumeSize.tola);
    final saved = await invoices.save(c.buildInvoice(customerName: 'Ali'));

    expect(saved.invoiceNo, 'INV-00001');
    expect(saved.total, 2 * 3500 + 1200);

    final loaded = (await invoices.getById(saved.id!))!;
    expect(loaded.invoiceNo, 'INV-00001');
    expect(loaded.customerName, 'Ali');
    expect(loaded.customerPhone, isNull);
    expect(loaded.total, 8200);
    expect(loaded.items.length, 2);
    expect(loaded.items[1].perfumeName, 'White Musk');
    expect(loaded.items[1].perfumeSubtitle, 'BY J.');
    expect(loaded.items[1].sizeLabel, PerfumeSize.tola.label);
    expect(loaded.items[1].unitPrice, 1200);
  });

  test('invoice numbers go up by one', () async {
    final c = InvoiceController()
      ..addItem(perfumes.first, PerfumeSize.ml10);
    final first = await invoices.save(c.buildInvoice());
    final second = await invoices.save(c.buildInvoice());
    expect(first.invoiceNo, 'INV-00001');
    expect(second.invoiceNo, 'INV-00002');
  });

  test('an empty invoice cannot be saved', () async {
    final empty = Invoice(createdAt: DateTime.now(), items: const []);
    expect(() => invoices.save(empty), throwsArgumentError);
  });
}
