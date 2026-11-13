import 'package:flutter/material.dart';

import 'data/invoice_repository.dart';
import 'models/perfume.dart';
import 'printing/receipt_printer.dart';
import 'screens/invoice_screen.dart';
import 'theme.dart';

class AuraApp extends StatelessWidget {
  const AuraApp({
    super.key,
    required this.perfumes,
    required this.invoiceRepository,
    required this.receiptPrinter,
  });

  final List<Perfume> perfumes;
  final InvoiceRepository invoiceRepository;
  final ReceiptPrinter receiptPrinter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura',
      debugShowCheckedModeBanner: false,
      theme: buildAuraTheme(),
      home: InvoiceScreen(
        perfumes: perfumes,
        invoiceRepository: invoiceRepository,
        receiptPrinter: receiptPrinter,
      ),
    );
  }
}
