import 'dart:io';

import 'package:aura/app.dart';
import 'package:aura/data/app_database.dart';
import 'package:aura/data/invoice_repository.dart';
import 'package:aura/data/perfume_repository.dart';
import 'package:aura/data/settings_repository.dart';
import 'package:aura/models/perfume.dart';
import 'package:aura/printing/receipt_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late List<Perfume> perfumes;
  late InvoiceRepository invoices;
  late ReceiptPrinter printer;

  setUpAll(() async {
    final csv = File(AppDatabase.priceListAsset).readAsStringSync();
    await AppDatabase.instance
        .open(path: inMemoryDatabasePath, loadPriceList: () async => csv);
    perfumes = await PerfumeRepository(AppDatabase.instance.db).getAll();
    invoices = InvoiceRepository(AppDatabase.instance.db);
    printer = ReceiptPrinter(
      await SettingsRepository.load(AppDatabase.instance.db),
    );
  });

  tearDownAll(() => AppDatabase.instance.close());

  testWidgets('search, add a perfume, and see the total update',
      (tester) async {
    // A typical desktop window size.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AuraApp(
      perfumes: perfumes,
      invoiceRepository: invoices,
      receiptPrinter: printer,
    ));
    expect(find.text('268 perfumes'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);

    // Search by S.No 129 = Hope.
    await tester.enterText(find.byType(TextField).first, '129');
    await tester.pump();
    expect(find.text('1 perfumes'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Hope'));
    await tester.pumpAndSettle();

    // Dialog: choose 30ml, quantity 2.
    await tester.tap(find.text('30ml'));
    await tester.pump();
    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();
    expect(find.text('PKR 7,000'), findsOneWidget); // line total in dialog

    await tester.tap(find.text('Add to invoice'));
    await tester.pumpAndSettle();

    // Invoice shows the line and both subtotal and total.
    expect(find.text('No items yet'), findsNothing);
    expect(find.text('3,500'), findsOneWidget); // unit price
    expect(find.text('7,000'), findsOneWidget); // line total
    expect(find.text('PKR 7,000'), findsNWidgets(2)); // subtotal + total
    expect(tester.takeException(), isNull); // no layout overflow
  });
}
