import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/invoice_repository.dart';
import 'data/perfume_repository.dart';
import 'data/settings_repository.dart';
import 'printing/receipt_printer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.open();
  final db = AppDatabase.instance.db;

  final perfumes = await PerfumeRepository(db).getAll();
  final settings = await SettingsRepository.load(db);

  runApp(AuraApp(
    perfumes: perfumes,
    invoiceRepository: InvoiceRepository(db),
    receiptPrinter: ReceiptPrinter(settings),
  ));
}
